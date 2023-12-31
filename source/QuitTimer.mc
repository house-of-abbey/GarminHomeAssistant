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
// J D Abbey & P A Abbey, 28 December 2022
//
//
// Description:
//
// Quit the application after a period of inactivity in order to save the battery.
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.Timer;
using Toybox.Application.Properties;
using Toybox.WatchUi;

class QuitTimer extends Timer.Timer {

    function initialize() {
        Timer.Timer.initialize();
    }

    function exitApp() as Void {
        if (Globals.scDebug) {
            System.println("QuitTimer exitApp(): Exiting");
        }
         // This will exit the system cleanly from any point within an app.
        System.exit();
    }

    function begin() {
        var api_timeout = Settings.get().getAppTimeout(); // ms
        if (api_timeout > 0) {
            start(method(:exitApp), api_timeout, false);
        }
    }

    function reset() {
        if (Globals.scDebug) {
            System.println("QuitTimer reset(): Restarted quit timer");
        }
        stop();
        begin();
    }
}
