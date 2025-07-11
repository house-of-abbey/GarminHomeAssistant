using Toybox.WatchUi;
using Toybox.System;
using Toybox.Communications;
using Toybox.Lang;
using Toybox.Timer;

// Delegate to respond to a confirmation to execute command via bulk sync
//
class WifiLteExecutionConfirmDelegate extends WatchUi.ConfirmationDelegate {
    public static var mCommandData as {
        :type       as Lang.String,
        :service    as Lang.String or Null,
        :data       as Lang.Dictionary or Null,
        :url        as Lang.String or Null,
        :id         as Lang.Number or Null,
        :exit       as Lang.Boolean
    };

    private var mToggleMethod   as Method(b as Lang.Boolean) as Void or Null;
    private var mToggleState    as Lang.Boolean or Null;
    private var mHasToast       as Lang.Boolean = false;
    private var mTimer          as Timer.Timer or Null;


    //! Initializes a confirmation delegate to confirm a Wi-Fi or LTE command exection
    //!
    //! @param options A dictionary describing the command to be executed:
    //!   - type:     The command type, either `"service"` or `"entity"`.
    //!   - service:  (For type `"service"`) The Home Assistant service to call (e.g., "light.turn_on").
    //!   - url:      (For type `"entity"`) The full Home Assistant entity API URL.
    //!   - callback: (For type `"entity"`) A callback method (Method<data as Dictionary>) to handle the response.
    //!   - data:     (Optional) A dictionary of data to send with the request.
    //!   = exit:     Boolean: true to exit after running command.
    //!
    //! @param toggleItem Optional toggle state information:
    //!   - confirmMethod: A method to call after confirmation.
    //!   - state:         The state (boolean) that will be passed to the confirmMethod.
    function initialize(cOptions as {
        :type     as Lang.String,
        :service  as Lang.String or Null,
        :data     as Lang.Dictionary or Null,
        :url      as Lang.String or Null,
        :callback as Lang.Method or Null,
        :exit     as Lang.Boolean,
    }, toggleItem as {
        :confirmMethod as Lang.Method,
        :state as Lang.Boolean
    } or Null) {
        ConfirmationDelegate.initialize();

        if (WatchUi has :showToast) {
            mHasToast = true;
        }

        mCommandData = {
            :type => cOptions[:type],
            :service => cOptions[:service],
            :data => cOptions[:data],
            :url => cOptions[:url],
            :callback => cOptions[:callback],
            :exit => cOptions[:exit]
        };
        if (toggleItem != null) {
            mToggleMethod = toggleItem[:confirmMethod];
            mToggleState = toggleItem[:state];
        }

        var timeout = Settings.getConfirmTimeout(); // ms
        if (timeout > 0) {
            mTimer = new Timer.Timer();
            mTimer.start(method(:onTimeout), timeout, true);
        }
    }

    //! Handles the user's response to the confirmation dialog.
    //!
    //! @param response The user's confirmation response as `WatchUi.Confirm`
    //! @return Always returns `true` to indicate the response was handled.
    function onResponse(response) as Lang.Boolean {
        getApp().getQuitTimer().reset();
        if (mTimer != null) {
            mTimer.stop();
        }

        if (response == WatchUi.CONFIRM_YES) {
            if (mToggleMethod != null) {
                mToggleMethod.invoke(mToggleState);
            }
            trySync();
        }
        return true;
    }

    //! Initiates a bulk sync process to execute a command, if connections are available
    private function trySync() as Void {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        var connectionInfo = System.getDeviceSettings().connectionInfo;
        var keys = connectionInfo.keys();
        var possibleConnection = false;

        for(var i = 0; i < keys.size(); i++) {
            if (keys[i] != :bluetooth) {
                var connection = connectionInfo[keys[i]];
                if (connection.state != System.CONNECTION_STATE_NOT_INITIALIZED) {
                    possibleConnection = true;
                    break;
                }
            }
        }

        if (possibleConnection) {
            if (Communications has :startSync2) {
                var syncString = WatchUi.loadResource($.Rez.Strings.WifiLteExecutionTitle) as Lang.String;
                Communications.startSync2({:message => syncString});
            } else {
                Communications.startSync();
            }
        } else {
            var toast = WatchUi.loadResource($.Rez.Strings.WifiLteNotAvailable) as Lang.String;
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
        }
    }

    //! Function supplied to a timer in order to limit the time for which the confirmation can be provided.
    function onTimeout() as Void {
        mTimer.stop();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}