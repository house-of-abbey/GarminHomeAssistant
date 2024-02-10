//-----------------------------------------------------------------------------------
//
// Distributed under MIT Licence
//   See https://github.com/house-of-abbey/GarminHomeAssistantWidget/blob/main/LICENSE.
//
//-----------------------------------------------------------------------------------
//
// GarminHomeAssistantWidget is a Garmin IQ widget written in Monkey C. The source code is provided at:
//            https://github.com/house-of-abbey/GarminHomeAssistantWidget.
//
// P A Abbey & J D Abbey, 12 January 2024
//
//
// Description:
//
// Menu button that renders a Home Assistant Template, and optionally triggers a service.
//
// Reference:
//  * https://developers.home-assistant.io/docs/api/rest/
//  * https://www.home-assistant.io/docs/configuration/templating
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics;

class HomeAssistantTemplateMenuItem extends WatchUi.IconMenuItem {
    private var mHomeAssistantService as HomeAssistantService;
    private var mTemplate             as Lang.String;
    private var mService              as Lang.String or Null;
    private var mConfirm              as Lang.Boolean;
    private var mData                 as Lang.Dictionary or Null;

    function initialize(
        label      as Lang.String or Lang.Symbol,
        template   as Lang.String,
        service    as Lang.String or Null,
        confirm    as Lang.Boolean,
        data       as Lang.Dictionary or Null,
        icon       as Graphics.BitmapType or WatchUi.Drawable,
        options    as {
            :alignment as WatchUi.MenuItem.Alignment
        } or Null,
        haService  as HomeAssistantService
    ) {
        WatchUi.IconMenuItem.initialize(
            label,
            null,
            null,
            icon,
            options
        );

        mHomeAssistantService = haService;
        mTemplate             = template;
        mService              = service;
        mConfirm              = confirm;
        mData                 = data;
    }

    function callService() as Void {
        if (mConfirm) {
            WatchUi.pushView(
                new HomeAssistantConfirmation(),
                new HomeAssistantConfirmationDelegate(method(:onConfirm), false),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else {
            onConfirm(false);
        }
    }

    // NB. Parameter 'b' is ignored
    function onConfirm(b as Lang.Boolean) as Void {
        if (mService != null) {
            mHomeAssistantService.call(mService, mData);
        }
    }

    // Callback function after completing the GET request to fetch the status.
    // Terminate updating the toggle menu items via the chain of calls for a permanent network
    // error. The ErrorView cancellation will resume the call chain.
    //
    function onReturnGetState(responseCode as Lang.Number, data as Lang.String) as Void {
        // System.println("HomeAssistantTemplateMenuItem onReturnGetState() Response Code: " + responseCode);
        // System.println("HomeAssistantTemplateMenuItem onReturnGetState() Response Data: " + data);

        var status = WatchUi.loadResource($.Rez.Strings.Unavailable) as Lang.String;
        switch (responseCode) {
            case Communications.BLE_HOST_TIMEOUT:
            case Communications.BLE_CONNECTION_UNAVAILABLE:
                // System.println("HomeAssistantTemplateMenuItem onReturnGetState() Response Code: BLE_HOST_TIMEOUT or BLE_CONNECTION_UNAVAILABLE, Bluetooth connection severed.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String + ".");
                break;

            case Communications.BLE_QUEUE_FULL:
                // System.println("HomeAssistantTemplateMenuItem onReturnGetState() Response Code: BLE_QUEUE_FULL, API calls too rapid.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.ApiFlood) as Lang.String);
                break;

            case Communications.NETWORK_REQUEST_TIMED_OUT:
                // System.println("HomeAssistantTemplateMenuItem onReturnGetState() Response Code: NETWORK_REQUEST_TIMED_OUT, check Internet connection.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoResponse) as Lang.String);
                break;

            case Communications.INVALID_HTTP_BODY_IN_NETWORK_RESPONSE:
                // System.println("HomeAssistantTemplateMenuItem onReturnGetState() Response Code: INVALID_HTTP_BODY_IN_NETWORK_RESPONSE, check JSON is returned.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoJson) as Lang.String);
                break;

            case Communications.NETWORK_RESPONSE_OUT_OF_MEMORY:
                // System.println("HomeAssistantTemplateMenuItem onReturnGetState() Response Code: NETWORK_RESPONSE_OUT_OF_MEMORY, are we going too fast?");
                var myTimer = new Timer.Timer();
                // Now this feels very "closely coupled" to the application, but it is the most reliable method instead of using a timer.
                myTimer.start(getApp().method(:updateNextMenuItem), Globals.scApiBackoff, false);
                // Revert status
                status = getApp().getApiStatus();
                break;

            case 404:
                // System.println("HomeAssistantTemplateMenuItem onReturnGetState() Response Code: 404, page not found. Check API URL setting.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.ApiUrlNotFound) as Lang.String);
                break;

            case 400:
                // System.println("HomeAssistantTemplateMenuItem onReturnGetState() Response Code: 400, bad request. Template error.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.TemplateError) as Lang.String);
                break;

            case 200:
                status = WatchUi.loadResource($.Rez.Strings.Available) as Lang.String;
                setSubLabel(data);
                requestUpdate();
                // Now this feels very "closely coupled" to the application, but it is the most reliable method instead of using a timer.
                getApp().updateNextMenuItem();
                break;

            default:
                // System.println("HomeAssistantTemplateMenuItem onReturnGetState(): Unhandled HTTP response code = " + responseCode);
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.UnhandledHttpErr) as Lang.String + responseCode);
        }
        getApp().setApiStatus(status);
    }

    function getState() as Void {
        if (! System.getDeviceSettings().phoneConnected) {
            // System.println("HomeAssistantTemplateMenuItem getState(): No Phone connection, skipping API call.");
            ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String + ".");
            getApp().setApiStatus(WatchUi.loadResource($.Rez.Strings.Unavailable) as Lang.String);
        } else if (! System.getDeviceSettings().connectionAvailable) {
            // System.println("HomeAssistantTemplateMenuItem getState(): No Internet connection, skipping API call.");
            ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoInternet) as Lang.String + ".");
            getApp().setApiStatus(WatchUi.loadResource($.Rez.Strings.Unavailable) as Lang.String);
        } else {
            var url = Settings.getApiUrl() + "/template";
            // System.println("HomeAssistantTemplateMenuItem getState() URL=" + url + ", Template='" + mTemplate + "'");
            Communications.makeWebRequest(
                url,
                { "template" => mTemplate },
                {
                    :method  => Communications.HTTP_REQUEST_METHOD_POST,
                    :headers => {
                        "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON,
                        "Authorization" => "Bearer " + Settings.getApiKey()
                    },
                    :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_TEXT_PLAIN
                },
                method(:onReturnGetState)
            );
        }
    }

}
