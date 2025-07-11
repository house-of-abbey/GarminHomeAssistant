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
// P A Abbey & J D Abbey & Someone0nEarth, 19 November 2023
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application.Properties;

//! Calling a Home Assistant Service.
//
class HomeAssistantService {
    private var mHasToast   as Lang.Boolean = false;
    private var mHasVibrate as Lang.Boolean = false;

    //! Class Constructor
    //
    function initialize() {
        mHasToast = WatchUi has :showToast;
        
        if (Attention has :vibrate) {
            mHasVibrate = true;
        }
    }

    //! Callback function after completing the POST request to call a service.
    //!
    //! @param responseCode Response code.
    //! @param data         Response data.
    //! @param context      An `entity_id` supplied in the GET request `options` `Lang.Dictionary` `context` field.
    //
    function onReturnCall(
        responseCode as Lang.Number,
        data         as Null or Lang.Dictionary or Lang.String,
        context      as Lang.Object
    ) as Void {
        var c = context as Lang.Dictionary;
        var entity_id;
        var exit = false;
        if (c != null) {
            entity_id = c.get(:entity_id) as Lang.String;
            exit      = c.get(:exit)      as Lang.Boolean;
        }
        // System.println("HomeAssistantService onReturnCall() Response Code: " + responseCode);
        // System.println("HomeAssistantService onReturnCall() Response Data: " + data);

        switch (responseCode) {
            case Communications.BLE_HOST_TIMEOUT:
            case Communications.BLE_CONNECTION_UNAVAILABLE:
                // System.println("HomeAssistantService onReturnCall() Response Code: BLE_HOST_TIMEOUT or BLE_CONNECTION_UNAVAILABLE, Bluetooth connection severed.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String);
                break;

            case Communications.BLE_QUEUE_FULL:
                // System.println("HomeAssistantService onReturnCall() Response Code: BLE_QUEUE_FULL, API calls too rapid.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.ApiFlood) as Lang.String);
                break;

            case Communications.NETWORK_REQUEST_TIMED_OUT:
                // System.println("HomeAssistantService onReturnCall() Response Code: NETWORK_REQUEST_TIMED_OUT, check Internet connection.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoResponse) as Lang.String);
                break;

            case Communications.NETWORK_RESPONSE_OUT_OF_MEMORY:
                // System.println("HomeAssistantService onReturnCall() Response Code: NETWORK_RESPONSE_OUT_OF_MEMORY, are we going too fast?");
                // Ignore and see if we can carry on
                break;
            case Communications.INVALID_HTTP_BODY_IN_NETWORK_RESPONSE:
                // System.println("HomeAssistantService onReturnCall() Response Code: INVALID_HTTP_BODY_IN_NETWORK_RESPONSE, check JSON is returned.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoJson) as Lang.String);
                break;

            case 404:
                // System.println("HomeAssistantService onReturnCall() Response Code: 404, page not found. Check API URL setting.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.ApiUrlNotFound) as Lang.String);
                break;

            case 200:
                // System.println("HomeAssistantService onReturnCall(): Service executed.");
                getApp().forceStatusUpdates();
                var d     = data as Lang.Array;
                var toast = WatchUi.loadResource($.Rez.Strings.Executed) as Lang.String;
                for(var i = 0; i < d.size(); i++) {
                    if ((d[i].get("entity_id") as Lang.String).equals(entity_id)) {
                        toast = (d[i].get("attributes") as Lang.Dictionary).get("friendly_name") as Lang.String;
                    }
                }
                if (mHasToast) {
                    WatchUi.showToast(toast, null);
                } else {
                    new Alert({
                        :timeout => Globals.scAlertTimeout,
                        :font    => Graphics.FONT_MEDIUM,
                        :text    => toast,
                        :fgcolor => Graphics.COLOR_WHITE,
                        :bgcolor => Graphics.COLOR_BLACK
                    }).pushView(WatchUi.SLIDE_IMMEDIATE);
                }
                if (exit) {
                    System.exit();
                }
                break;

            default:
                // System.println("HomeAssistantService onReturnCall(): Unhandled HTTP response code = " + responseCode);
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.UnhandledHttpErr) as Lang.String + responseCode);
        }
    }

    //! Invoke a service call for a menu item.
    //!
    //! @param service The Home Assistant service to be run, e.g. from the JSON `service` field.
    //! @param data    Data to be supplied to the service call.
    //
    function call(
        service as Lang.String,
        data    as Lang.Dictionary or Null,
        exit    as Lang.Boolean
    ) as Void {
        var phoneConnected = System.getDeviceSettings().phoneConnected;
        var internetAvailable = System.getDeviceSettings().connectionAvailable;
        if (Settings.getWifiLteExecutionEnabled() && (! phoneConnected || ! internetAvailable)) {
            var dialogMsg = WatchUi.loadResource($.Rez.Strings.WifiLtePrompt) as Lang.String;
            var dialog = new WatchUi.Confirmation(dialogMsg);
            WatchUi.pushView(
                dialog,
                new WifiLteExecutionConfirmDelegate({
                    :type => "service",
                    :service => service,
                    :data => data,
                    :exit => exit,
                }),
                WatchUi.SLIDE_LEFT
            );
        } else if (! phoneConnected) {
            // System.println("HomeAssistantService call(): No Phone connection, skipping API call.");
            ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String);
        } else if (! internetAvailable) {
            // System.println("HomeAssistantService call(): No Internet connection, skipping API call.");
            ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoInternet) as Lang.String);
        } else {
            // Can't use null for substring() parameters due to API version level.
            var url = Settings.getApiUrl() + "/services/" + service.substring(0, service.find(".")) + "/" + service.substring(service.find(".")+1, service.length());
            // System.println("HomeAssistantService call() URL=" + url);
            // System.println("HomeAssistantService call() service=" + service);

            var entity_id = "";
            if (data != null) {
                entity_id = data.get("entity_id");
                if (entity_id == null) {
                    entity_id = "";
                }
            }

            Communications.makeWebRequest(
                url,
                data, // Includes {"entity_id": xxxx}
                {
                    :method       => Communications.HTTP_REQUEST_METHOD_POST,
                    :headers      => {
                        "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON,
                        "Authorization" => "Bearer " + Settings.getApiKey()
                    },
                    :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
                    :context      => {
                        :entity_id => entity_id,
                        :exit      => exit
                    }
                },
                method(:onReturnCall)
            );
            if (mHasVibrate and Settings.getVibrate()) {
                Attention.vibrate([
                    new Attention.VibeProfile(50, 100), // On  for 100ms
                    new Attention.VibeProfile( 0, 100), // Off for 100ms
                    new Attention.VibeProfile(50, 100)  // On  for 100ms
                ]);
            }
        }
    }

}
