//-----------------------------------------------------------------------------------
//
// Distributed under MIT Licence
//   See https://github.com/house-of-abbey/GarminHomeAssistant/blob/main/LICENSE.
//
//-----------------------------------------------------------------------------------
//
// GarminHomeAssistant is a Garmin IQ application written in Monkey C and routinely
// tested on a Venu 2 device. The source code is provided at:
//            https://github.com/house-of-abbey/GarminHomeAssistant.
//
// P A Abbey & J D Abbey, 12 January 2024
//
//
// Description:
//
// Rendering a Home Assistant Template.
// 
// Reference:
//  * https://developers.home-assistant.io/docs/api/rest/
//  * https://www.home-assistant.io/docs/configuration/templating
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics;

class HomeAssistantTemplateMenuItem extends WatchUi.MenuItem {
    private var mHomeAssistantService as HomeAssistantService;
    private var mTemplate             as Lang.String;
    private var mService              as Lang.String or Null;
    private var mConfirm              as Lang.Boolean;

    function initialize(
        label      as Lang.String or Lang.Symbol,
        identifier as Lang.Object or Null,
        template   as Lang.String,
        service    as Lang.String or Null,
        confirm    as Lang.Boolean,
        options    as {
            :alignment as WatchUi.MenuItem.Alignment,
            :icon      as Graphics.BitmapType or WatchUi.Drawable or Lang.Symbol
        } or Null,
        haService  as HomeAssistantService
    ) {
        WatchUi.MenuItem.initialize(
            label,
            null,
            identifier,
            options
        );

        mHomeAssistantService = haService;
        mTemplate             = template;
        mService              = service;
        mConfirm              = confirm;
    }

    function callService() as Void {
        if (mConfirm) {
            WatchUi.pushView(
                new HomeAssistantConfirmation(),
                new HomeAssistantConfirmationDelegate(method(:onConfirm)),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else {
            onConfirm();
        }
    }

    function onConfirm() as Void {
        if (mService != null) {
            mHomeAssistantService.call(mIdentifier as Lang.String, mService);
        }
    }

    // Callback function after completing the GET request to fetch the status.
    // Terminate updating the toggle menu items via the chain of calls for a permanent network
    // error. The ErrorView cancellation will resume the call chain.
    //
    function onReturnGetState(responseCode as Lang.Number, data as Lang.String) as Void {
        if (Globals.scDebug) {
            System.println("HomeAssistantTemplateMenuItem onReturnGetState() Response Code: " + responseCode);
            System.println("HomeAssistantTemplateMenuItem onReturnGetState() Response Data: " + data);
        }

        var status = RezStrings.getUnavailable();
        switch (responseCode) {
            case Communications.BLE_HOST_TIMEOUT:
            case Communications.BLE_CONNECTION_UNAVAILABLE:
                if (Globals.scDebug) {
                    System.println("HomeAssistantTemplateMenuItem onReturnGetState() Response Code: BLE_HOST_TIMEOUT or BLE_CONNECTION_UNAVAILABLE, Bluetooth connection severed.");
                }
                ErrorView.show(RezStrings.getNoPhone() + ".");
                break;

            case Communications.BLE_QUEUE_FULL:
                if (Globals.scDebug) {
                    System.println("HomeAssistantTemplateMenuItem onReturnGetState() Response Code: BLE_QUEUE_FULL, API calls too rapid.");
                }
                ErrorView.show(RezStrings.getApiFlood());
                break;

            case Communications.NETWORK_REQUEST_TIMED_OUT:
                if (Globals.scDebug) {
                    System.println("HomeAssistantTemplateMenuItem onReturnGetState() Response Code: NETWORK_REQUEST_TIMED_OUT, check Internet connection.");
                }
                ErrorView.show(RezStrings.getNoResponse());
                break;

            case Communications.INVALID_HTTP_BODY_IN_NETWORK_RESPONSE:
                if (Globals.scDebug) {
                    System.println("HomeAssistantTemplateMenuItem onReturnGetState() Response Code: INVALID_HTTP_BODY_IN_NETWORK_RESPONSE, check JSON is returned.");
                }
                ErrorView.show(RezStrings.getNoJson());
                break;

            case Communications.NETWORK_RESPONSE_OUT_OF_MEMORY:
                if (Globals.scDebug) {
                    System.println("HomeAssistantTemplateMenuItem onReturnGetState() Response Code: NETWORK_RESPONSE_OUT_OF_MEMORY, are we going too fast?");
                }
                var myTimer = new Timer.Timer();
                // Now this feels very "closely coupled" to the application, but it is the most reliable method instead of using a timer.
                myTimer.start(getApp().method(:updateNextMenuItem), Globals.scApiBackoff, false);
                // Revert status
                status = getApp().getApiStatus();
                break;

            case 404:
                if (Globals.scDebug) {
                    System.println("HomeAssistantTemplateMenuItem onReturnGetState() Response Code: 404, page not found. Check API URL setting.");
                }
                ErrorView.show(RezStrings.getApiUrlNotFound());
                break;

            case 400:
                if (Globals.scDebug) {
                    System.println("HomeAssistantTemplateMenuItem onReturnGetState() Response Code: 400, bad request. Template error.");
                }
                ErrorView.show(RezStrings.getTemplateError());
                break;

            case 200:
                status = RezStrings.getAvailable();
                setSubLabel(data);
                requestUpdate();
                ErrorView.unShow();
                // Now this feels very "closely coupled" to the application, but it is the most reliable method instead of using a timer.
                getApp().updateNextMenuItem();
                break;

            default:
                if (Globals.scDebug) {
                    System.println("HomeAssistantTemplateMenuItem onReturnGetState(): Unhandled HTTP response code = " + responseCode);
                }
                ErrorView.show(RezStrings.getUnhandledHttpErr() + responseCode);
        }
        getApp().setApiStatus(status);
    }

    function getState() as Void {
        if (! System.getDeviceSettings().phoneConnected) {
            if (Globals.scDebug) {
                System.println("HomeAssistantTemplateMenuItem getState(): No Phone connection, skipping API call.");
            }
            ErrorView.show(RezStrings.getNoPhone() + ".");
            getApp().setApiStatus(RezStrings.getUnavailable());
        } else if (! System.getDeviceSettings().connectionAvailable) {
            if (Globals.scDebug) {
                System.println("HomeAssistantTemplateMenuItem getState(): No Internet connection, skipping API call.");
            }
            ErrorView.show(RezStrings.getNoInternet() + ".");
            getApp().setApiStatus(RezStrings.getUnavailable());
        } else {
            var url = Settings.getApiUrl() + "/template";
            if (Globals.scDebug) {
                System.println("HomeAssistantTemplateMenuItem getState() URL=" + url + ", Template='" + mTemplate + "'");
            }
            Communications.makeWebRequest(
                url,
                {
                    "template" => mTemplate
                },
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
