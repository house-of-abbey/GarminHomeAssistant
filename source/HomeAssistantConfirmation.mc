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
// Required for callback method definition
typedef Method as Toybox.Lang.Method;
using Toybox.WatchUi;
using Toybox.Timer;
using Toybox.Application.Properties;

//! Calling a Home Assistant confirmation dialogue view.
//
class HomeAssistantConfirmation extends WatchUi.Confirmation {

    //! Class Constructor
    //
    function initialize() {
        WatchUi.Confirmation.initialize(WatchUi.loadResource($.Rez.Strings.Confirm) as Lang.String);
    }

}

//! Delegate to respond to the confirmation request.
//
class HomeAssistantConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    private var mConfirmMethod as Method(state as Lang.Boolean) as Void;
    private var mTimer         as Timer.Timer or Null;
    private var mState         as Lang.Boolean;
    private var mToggleMethod  as Method(state as Lang.Boolean) as Void or Null;

    //! Class Constructor
    //!
    //! @param options A dictionary describing the following options:
    //!  - callback Method to call on confirmation.
    //!  - state    Wanted state of a toggle button.
    //!  - toggle   Optional setEnabled method to untoggle ToggleItem.
    //
    function initialize(options as {
        :callback as Method(state as Lang.Boolean) as Void,
        :state as Lang.Boolean,
        :toggleMethod as Method(state as Lang.Boolean) or Null,
    }) {
        WatchUi.ConfirmationDelegate.initialize();
        mConfirmMethod = options[:callback];
        mState         = options[:state];
        mToggleMethod  = options[:toggleMethod];

        var timeout = Settings.getConfirmTimeout(); // ms
        if (timeout > 0) {
            mTimer = new Timer.Timer();
            mTimer.start(method(:onTimeout), timeout, true);
        }
    }

    //! Respond to the confirmation event.
    //!
    //! @param response code
    //! @return Required to meet the function prototype, but the base class does not indicate a definition.
    //
    function onResponse(response as WatchUi.Confirm) as Lang.Boolean {
        getApp().getQuitTimer().reset();
        if (mTimer != null) {
            mTimer.stop();
        }
        if (response == WatchUi.CONFIRM_YES) {
            mConfirmMethod.invoke(mState);
        } else {
            // Undo the toggle, if we have one
            if (mToggleMethod != null) {
                mToggleMethod.invoke(!mState);
            }
        }
        return true;
    }

    //! Function supplied to a timer in order to limit the time for which the confirmation can be provided.
    function onTimeout() as Void {
        mTimer.stop();
        // Undo the toggle, if we have one
        if (mToggleMethod != null) {
            mToggleMethod.invoke(!mState);
        }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
