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
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.Timer;
using Toybox.Application.Properties;
using Toybox.WatchUi;

//! Quit the application after a period of inactivity in order to save the battery.
//!
class QuitTimer extends Timer.Timer {

    //! Class Constructor
    //
    function initialize() {
        Timer.Timer.initialize();
    }

    //! Can't see how to make a method object from `System.exit()` without this layer of
    //! indirection. I assume this is because `System` is a static class.
    //
    function exitApp() as Void {
        // System.println("QuitTimer exitApp(): Exiting");
         // This will exit the system cleanly from any point within an app.
        System.exit();
    }

    //! Kick off the quit timer.
    //
    function begin() {
        var api_timeout = Settings.getAppTimeout(); // ms
        if (api_timeout > 0) {
            start(method(:exitApp), api_timeout, false);
        }
    }

    //! Reset the quit timer.
    //
    function reset() {
        // System.println("QuitTimer reset(): Restarted quit timer");
        stop();
        begin();
    }
}
