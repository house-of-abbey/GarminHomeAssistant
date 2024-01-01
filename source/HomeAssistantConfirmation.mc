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
using Toybox.Application.Properties;

class HomeAssistantConfirmation extends WatchUi.Confirmation {

    function initialize() {
        WatchUi.Confirmation.initialize(RezStrings.strConfirm);
    }

}

class HomeAssistantConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    private var mConfirmMethod;
    private var mTimer;

    function initialize(callback as Method() as Void) {
        WatchUi.ConfirmationDelegate.initialize();
        mConfirmMethod = callback;
        var timeout = Settings.getConfirmTimeout(); // ms
        if (timeout > 0) {
            mTimer = new Timer.Timer();
            mTimer.start(method(:onTimeout), timeout, true);
        }
    }

    function onResponse(response) as Lang.Boolean {
        getApp().getQuitTimer().reset();
        if (mTimer) {
            mTimer.stop();
        }
        if (response == WatchUi.CONFIRM_YES) {
            mConfirmMethod.invoke();
        }
        return true;
    }

    function onTimeout() as Void {
        mTimer.stop();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
