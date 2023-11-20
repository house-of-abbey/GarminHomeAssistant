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
// P A Abbey & J D Abbey & SomeoneOnEarth, 19 November 2023
//
//
// Description:
//
// Calling a Home Assistant Service.
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application.Properties;

class HomeAssistantService {
    private var mApiKey             as Lang.String;
    private var strNoPhone          as Lang.String;
    private var strNoInternet       as Lang.String;
    private var strNoResponse       as Lang.String;
    private var strApiFlood         as Lang.String;
    private var strApiUrlNotFound   as Lang.String;
    private var strUnhandledHttpErr as Lang.String;

    function initialize() {
        strNoPhone          = WatchUi.loadResource($.Rez.Strings.NoPhone);
        strNoInternet       = WatchUi.loadResource($.Rez.Strings.NoInternet);
        strNoResponse       = WatchUi.loadResource($.Rez.Strings.NoResponse);
        strApiFlood         = WatchUi.loadResource($.Rez.Strings.ApiFlood);
        strApiUrlNotFound   = WatchUi.loadResource($.Rez.Strings.ApiUrlNotFound);
        strUnhandledHttpErr = WatchUi.loadResource($.Rez.Strings.UnhandledHttpErr);
        mApiKey             = Properties.getValue("api_key");
    }

    // Callback function after completing the POST request to call a service.
    //
    function onReturnCall(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String, context as Lang.Object) as Void {
        var identifier = context as Lang.String;
        if (Globals.scDebug) {
            System.println("HomeAssistantService onReturnCall() Response Code: " + responseCode);
            System.println("HomeAssistantService onReturnCall() Response Data: " + data);
        }
        if (responseCode == Communications.BLE_HOST_TIMEOUT || responseCode == Communications.BLE_CONNECTION_UNAVAILABLE) {
            if (Globals.scDebug) {
                System.println("HomeAssistantService onReturnCall() Response Code: BLE_HOST_TIMEOUT or BLE_CONNECTION_UNAVAILABLE, Bluetooth connection severed.");
            }
            WatchUi.pushView(new ErrorView(strNoPhone + "."), new ErrorDelegate(), WatchUi.SLIDE_UP);
        } else if (responseCode == Communications.BLE_QUEUE_FULL) {
            if (Globals.scDebug) {
                System.println("HomeAssistantService onReturnCall() Response Code: BLE_QUEUE_FULL, API calls too rapid.");
            }
            if (!(WatchUi.getCurrentView()[0] instanceof ErrorView)) {
                // Avoid pushing multiple ErrorViews
                WatchUi.pushView(new ErrorView(strApiFlood), new ErrorDelegate(), WatchUi.SLIDE_UP);
            }
        } else if (responseCode == Communications.NETWORK_REQUEST_TIMED_OUT) {
            if (Globals.scDebug) {
                System.println("HomeAssistantService onReturnCall() Response Code: NETWORK_REQUEST_TIMED_OUT, check Internet connection.");
            }
            WatchUi.pushView(new ErrorView(strNoResponse), new ErrorDelegate(), WatchUi.SLIDE_UP);
        } else if (responseCode == 404) {
            if (Globals.scDebug) {
                System.println("HomeAssistantService onReturnCall() Response Code: 404, page not found. Check API URL setting.");
            }
            WatchUi.pushView(new ErrorView(strApiUrlNotFound), new ErrorDelegate(), WatchUi.SLIDE_UP);
        } else if (responseCode == 200) {
            if (Globals.scDebug) {
                System.println("HomeAssistantService onReturnCall(): Service executed.");
            }
            var d     = data as Lang.Array;
            var toast = "Executed";
            for(var i = 0; i < d.size(); i++) {
                if ((d[i].get("entity_id") as Lang.String).equals(identifier)) {
                    toast = (d[i].get("attributes") as Lang.Dictionary).get("friendly_name") as Lang.String;
                }
            }
            if (WatchUi has :showToast) {
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
        } else {
            if (Globals.scDebug) {
                System.println("HomeAssistantService onReturnCall(): Unhandled HTTP response code = " + responseCode);
            }
            WatchUi.pushView(new ErrorView(strUnhandledHttpErr + responseCode ), new ErrorDelegate(), WatchUi.SLIDE_UP);
        }
    }

    function call(identifier as Lang.String, service as Lang.String) as Void {
        var options = {
            :method  => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON,
                "Authorization" => "Bearer " + mApiKey
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
            :context      => identifier
        };
        if (! System.getDeviceSettings().phoneConnected) {
            if (Globals.scDebug) {
                System.println("HomeAssistantService call(): No Phone connection, skipping API call.");
            }
            WatchUi.pushView(new ErrorView(strNoPhone + "."), new ErrorDelegate(), WatchUi.SLIDE_UP);
        } else if (! System.getDeviceSettings().connectionAvailable) {
            if (Globals.scDebug) {
                System.println("HomeAssistantService call(): No Internet connection, skipping API call.");
            }
            WatchUi.pushView(new ErrorView(strNoInternet + "."), new ErrorDelegate(), WatchUi.SLIDE_UP);
        } else {
            var url = (Properties.getValue("api_url") as Lang.String) + "/services/" + service.substring(0, service.find(".")) + "/" + service.substring(service.find(".")+1, null);
            if (Globals.scDebug) {
                System.println("HomeAssistantService call() URL=" + url);
                System.println("HomeAssistantService call() service=" + service);
            }
            Communications.makeWebRequest(
                url,
                {
                    "entity_id" => identifier
                },
                options,
                method(:onReturnCall)
            );
            if (Attention has :vibrate) {
                Attention.vibrate([
                    new Attention.VibeProfile(50, 100), // On  for 100ms
                    new Attention.VibeProfile( 0, 100), // Off for 100ms
                    new Attention.VibeProfile(50, 100)  // On  for 100ms
                ]);
            }
        }
    }

}
