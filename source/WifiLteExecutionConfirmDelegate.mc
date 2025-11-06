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
// P A Abbey & J D Abbey & vincentezw, 22 July 2025
//
//-----------------------------------------------------------------------------------

using Toybox.WatchUi;
using Toybox.System;
using Toybox.Communications;
using Toybox.Lang;
using Toybox.Timer;

//! Delegate to respond to a confirmation to execute an API request via bulk
//! synchronisation.
//
class WifiLteExecutionConfirmDelegate extends WatchUi.ConfirmationDelegate {
    public static var mCommandData as {
        :type   as Lang.String,
        :action as Lang.String?,
        :data   as Lang.Dictionary?,
        :url    as Lang.String?,
        :id     as Lang.Number?,
        :exit   as Lang.Boolean
    }?;

    private static var mTimer     as Timer.Timer?;
    private var mHasToast         as Lang.Boolean = false;
    private var mConfirmationView as WatchUi.Confirmation;

    //! Initializes a confirmation delegate to confirm a Wi-Fi or LTE command execution
    //!
    //! @param options A dictionary describing the command to be executed:<br>
    //!   `{`<br>
    //!   &emsp; `:type:     as Lang.String,`      // The command type, either `"action"` or `"entity"`.<br>
    //!   &emsp; `:action:   as Lang.String?,`     // (For type `"action"`) The Home Assistant action to call (e.g., "light.turn_on").<br>
    //!   &emsp; `:url:      as Lang.Dictionary?,` // (For type `"entity"`) The full Home Assistant entity API URL.<br>
    //!   &emsp; `:callback: as Lang.String?,`     // (For type `"entity"`) A callback method (Method<data as Dictionary>) to handle the response.<br>
    //!   &emsp; `:data:     as Lang.Method?,`     // (Optional) A dictionary of data to send with the request.<br>
    //!   &emsp; `:exit:     as Lang.Boolean,`     // Boolean: if set to true: exit after running command.<br>
    //!   &rbrace;<br>
    //! @param view   The Confirmation view the delegate is active for
    //
    function initialize(
        cOptions as {
            :type     as Lang.String,
            :action   as Lang.String?,
            :data     as Lang.Dictionary?,
            :url      as Lang.String?,
            :callback as Lang.Method?,
            :exit     as Lang.Boolean,
        },
        view as WatchUi.Confirmation
    ) {
        ConfirmationDelegate.initialize();

        if (mTimer != null) {
            mTimer.stop();
        }

        if (WatchUi has :showToast) {
            mHasToast = true;
        }

        mConfirmationView = view;
        mCommandData = {
            :type     => cOptions[:type],
            :action   => cOptions[:action],
            :data     => cOptions[:data],
            :url      => cOptions[:url],
            :callback => cOptions[:callback],
            :exit     => cOptions[:exit]
        };

        var timeout = Settings.getConfirmTimeout(); // ms
        if (timeout > 0) {
            if (mTimer == null) {
                mTimer = new Timer.Timer();
            }
            mTimer.start(method(:onTimeout), timeout, true);
        }
    }

    //! Handles the user's response to the confirmation dialog.
    //!
    //! @param response The user's confirmation response as `WatchUi.Confirm`
    //! @return Always returns `true` to indicate the response was handled.
    //
    function onResponse(response) as Lang.Boolean {
        getApp().getQuitTimer().reset();
        if (mTimer != null) {
            mTimer.stop();
        }

        if (response == WatchUi.CONFIRM_YES) {
            trySync();
        }
        return true;
    }

    //! Initiates a bulk sync process to execute a command, if connections are available
    //
    private function trySync() as Void {
        var connectionInfo     = System.getDeviceSettings().connectionInfo;
        var keys               = connectionInfo.keys();
        var possibleConnection = false;

        for(var i = 0; i < keys.size(); i++) {
            if (keys[i] != :bluetooth) {
                if (connectionInfo[keys[i]].state != System.CONNECTION_STATE_NOT_INITIALIZED) {
                    possibleConnection = true;
                    break;
                }
            }
        }

        if (possibleConnection) {
            if (Communications has :startSync2) {
                Communications.startSync2({
                    :message => WatchUi.loadResource($.Rez.Strings.WifiLteExecutionTitle) as Lang.String
                });
            } else {
                Communications.startSync();
            }
        } else {
            var toast = WatchUi.loadResource($.Rez.Strings.WifiLteNotAvailable) as Lang.String;
            if (mHasToast) {
                WatchUi.showToast(toast, null);
            } else {
                new Alert({
                    :timeout => Globals.scAlertTimeoutMs,
                    :font    => Graphics.FONT_MEDIUM,
                    :text    => toast,
                    :fgcolor => Graphics.COLOR_WHITE,
                    :bgcolor => Graphics.COLOR_BLACK
                }).pushView(WatchUi.SLIDE_IMMEDIATE);
            }
        }
    }

    //! Function supplied to a timer in order to limit the time for which the confirmation can be provided.
    //
    function onTimeout() as Void {
        mTimer.stop();
        var getCurrentView = WatchUi.getCurrentView();

        if (getCurrentView[0] == mConfirmationView) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }
}