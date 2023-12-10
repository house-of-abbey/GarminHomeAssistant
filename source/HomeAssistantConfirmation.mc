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
// Calling a Home Assistant confirmation dialogue view.
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
// Required for callback method definition
typedef Method as Toybox.Lang.Method;
using Toybox.WatchUi;
using Toybox.Timer;

class HomeAssistantConfirmation extends WatchUi.Confirmation {
    function initialize() {
        WatchUi.Confirmation.initialize(WatchUi.loadResource($.Rez.Strings.Confirm));
    }

}

class HomeAssistantConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    private var confirmMethod;
    private var timeout;

    function initialize(callback as Method() as Void) {
        WatchUi.ConfirmationDelegate.initialize();
        confirmMethod = callback;
        timeout = new Timer.Timer();
        timeout.start(method(:onTimeout), 3000, true);
    }

    function onResponse(response) as Lang.Boolean {
        getApp().getQuitTimer().reset();
        timeout.stop();
        if (response == WatchUi.CONFIRM_YES) {
            confirmMethod.invoke();
        }
        return true;
    }

    function onTimeout() as Void {
        timeout.stop();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
