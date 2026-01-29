//-----------------------------------------------------------------------------------
//
// Distributed under MIT Licence
//   See https://github.com/house-of-abbey/GarminHomeAssistant/blob/main/LICENSE
//
//-----------------------------------------------------------------------------------
//
// GarminHomeAssistant is a Garmin IQ application written in Monkey C and routinely
// tested on a Venu 2 device. The source code is provided at:
//            https://github.com/house-of-abbey/GarminHomeAssistant
//
// P A Abbey & J D Abbey & Someone0nEarth & vincentezw, 19 November 2023
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Timer;
using Toybox.Application.Properties;

//! Calling a Home Assistant confirmation dialogue view.
//
class HomeAssistantConfirmation extends WatchUi.Confirmation {

    //! Class Constructor
    //
    function initialize(message as Lang.String?) {
        if (message == null) {
            WatchUi.Confirmation.initialize(WatchUi.loadResource($.Rez.Strings.Confirm) as Lang.String);
        } else {
            WatchUi.Confirmation.initialize(message);
        }
    }
}

//! Delegate to respond to the confirmation request.
//
class HomeAssistantConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    private static var mTimer     as Timer.Timer?;
    private var mConfirmMethod    as Method(state as Lang.Boolean) as Void;
    private var mState            as Lang.Boolean;
    private var mToggleMethod     as Method(state as Lang.Boolean) as Void or Null;
    private var mConfirmationView as WatchUi.Confirmation;

    //! Class Constructor
    //!
    //! @param options A dictionary describing the following options:<br>
    //!   `{`<br>
    //!   &emsp; `:callback         as Method(state as Lang.Boolean) as Void,` // Method to call on confirmation.<br>
    //!   &emsp; `:confirmationView as WatchUi.Confirmation,`                  // Confirmation the delegate is active for<br>
    //!   &emsp; `:state            as Lang.Boolean,`                          // Wanted state of a toggle button.<br>
    //!   &emsp; `:toggle           as Method(state as Lang.Boolean)?`         // Optional setEnabled method to untoggle ToggleItem.<br>
    //!   `}`
    //
    function initialize(
        options as {
            :callback         as Method(state as Lang.Boolean) as Void,
            :confirmationView as WatchUi.Confirmation,
            :state            as Lang.Boolean,
            :toggleMethod     as Method(state as Lang.Boolean)?
        }
    ) {
        if (mTimer != null) {
            mTimer.stop();
        }

        WatchUi.ConfirmationDelegate.initialize();
        mConfirmMethod = options[:callback];
        mConfirmationView = options[:confirmationView];
        mState         = options[:state];
        mToggleMethod  = options[:toggleMethod];

        var timeout = Settings.getConfirmTimeout(); // ms
        if (timeout > 0) {
            if (mTimer == null) {
                mTimer = new Timer.Timer();
            }
            
            mTimer.start(method(:onTimeout), timeout, true);
        }
    }

    //! Respond to the confirmation event.
    //!
    //! @param response response code
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
    //
    function onTimeout() as Void {
        mTimer.stop();
        // Undo the toggle, if we have one
        if (mToggleMethod != null) {
            mToggleMethod.invoke(!mState);
        }

        var getCurrentView = WatchUi.getCurrentView();
        if (getCurrentView[0] == mConfirmationView) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }
}
