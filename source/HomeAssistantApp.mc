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
// P A Abbey & J D Abbey, 31 October 2023
//
//
// Description:
//
// Application root for GarminHomeAssistant.
//
//-----------------------------------------------------------------------------------

using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Application.Properties;
using Toybox.Timer;

class HomeAssistantApp extends Application.AppBase {
    hidden var haMenu;
    hidden var timer as Timer.Timer;

    function initialize() {
        AppBase.initialize();
        timer = new Timer.Timer();
    }

    // onStart() is called on application start up
    function onStart(state as Lang.Dictionary?) as Void {
        fetchMenuConfig();
    }

    // onStop() is called when your application is exiting
    function onStop(state as Lang.Dictionary?) as Void {
        if (timer != null) {
            timer.stop();
        }
    }

    // Return the initial view of your application here
    function getInitialView() as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>? {
        return [new WatchUi.View(), new WatchUi.BehaviorDelegate()] as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>;
    }

    // Callback function after completing the GET request to fetch the configuration menu.
    //
    function onReturnFetchMenuConfig(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        if (Globals.debug) {
            System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Code: " + responseCode);
            System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Data: " + data);
        }
        if (responseCode == 200) {
            haMenu = new HomeAssistantView(data, null);
            timer.start(
                haMenu.method(:stateUpdate),
                Globals.updateInterval * 1000,
                true
            );
            WatchUi.switchToView(haMenu, new HomeAssistantViewDelegate(), WatchUi.SLIDE_IMMEDIATE);
        } else {
            if (Globals.debug) {
                System.println("HomeAssistantApp Note - onReturnFetchMenuConfig(): Configuration not found or potential validation issue.");
            }
            new Alert({
                :timeout => Globals.alertTimeout,
                :font    => Graphics.FONT_SYSTEM_MEDIUM,
                :text    => "Error " + responseCode,
                :fgcolor => Graphics.COLOR_RED,
                :bgcolor => Graphics.COLOR_BLACK
            }).pushView(WatchUi.SLIDE_IMMEDIATE);
        }
    }

    function fetchMenuConfig() as Void {
        var options = {
            :method  => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        if (System.getDeviceSettings().phoneConnected && System.getDeviceSettings().connectionAvailable) {
            Communications.makeWebRequest(
                Properties.getValue("config_url"),
                null,
                options,
                method(:onReturnFetchMenuConfig)
            );
        } else {
            if (Globals.debug) {
                System.println("HomeAssistantApp Note - fetchMenuConfig(): No Internet connection, skipping API call.");
            }
            new Alert({
                :timeout => Globals.alertTimeout,
                :font    => Graphics.FONT_SYSTEM_MEDIUM,
                :text    => "No Internet connection",
                :fgcolor => Graphics.COLOR_RED,
                :bgcolor => Graphics.COLOR_BLACK
            }).pushView(WatchUi.SLIDE_IMMEDIATE);
        }
    }

}

function getApp() as HomeAssistantApp {
    return Application.getApp() as HomeAssistantApp;
}
