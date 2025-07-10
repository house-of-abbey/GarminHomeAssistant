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

        ConfirmationDelegate.initialize();
    }

    //! Handles the user's response to the confirmation dialog.
    //!
    //! @param response The user's confirmation response as `WatchUi.Confirm`
    //! @return Always returns `true` to indicate the response was handled.
    function onResponse(response) as Lang.Boolean {
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
            var syncString = WatchUi.loadResource($.Rez.Strings.WifiLteExecutionTitle) as Lang.String;
            Communications.startSync2({:message => syncString});
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

class HomeAssistantSyncDelegate extends Communications.SyncDelegate {
    private static var syncError as Lang.String or Null;

    // Initialize an instance of this delegate
    public function initialize() {
        SyncDelegate.initialize();
    }

    //! Called by the system to determine if a sync is needed
    public function isSyncNeeded() as Lang.Boolean {
        return true;
    }

    //! Called by the system when starting a bulk sync.
    public function onStartSync() as Void {
        syncError = null;
        
        if (WifiLteExecutionConfirmDelegate.mCommandData == null) {
            syncError = WatchUi.loadResource($.Rez.Strings.WifiLteExecutionDataError) as Lang.String;
            onStopSync();
            return;
        }
        
        var type = WifiLteExecutionConfirmDelegate.mCommandData[:type];
        var data = WifiLteExecutionConfirmDelegate.mCommandData[:data];
        var url;

        switch (type) {
            case "service":
                var service = WifiLteExecutionConfirmDelegate.mCommandData[:service];
                url = Settings.getApiUrl() + "/services/" + service.substring(0, service.find(".")) + "/" + service.substring(service.find(".")+1, service.length());
                var entity_id = "";
                if (data != null) {
                    entity_id = data.get("entity_id");
                    if (entity_id == null) {
                        entity_id = "";
                    }
                }
                performRequest(url, data);
                break;
            case "entity":
                url = WifiLteExecutionConfirmDelegate.mCommandData[:url];
                performRequest(url, data);
                break;
        }
    }

    // Performs a POST request to Hass with a given payload and URL, and calls haCallback
    private function performRequest(url as Lang.String, data as Lang.Dictionary or Null) {
        Communications.makeWebRequest(
            url,
            data, // May include {"entity_id": xxxx} for service calls
            {
                :method  => Communications.HTTP_REQUEST_METHOD_POST,
                :headers => {
                    "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON,
                    "Authorization" => "Bearer " + Settings.getApiKey()
                },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:haCallback)
        );
    }

    //! Handle callback from request
    public function haCallback(code as Lang.Number, data as Null or Lang.Dictionary) as Void {
        if (code == 200) {
            syncError = null;
            if (WifiLteExecutionConfirmDelegate.mCommandData[:type].equals("entity")) {
                var callbackMethod = WifiLteExecutionConfirmDelegate.mCommandData[:callback];
                if (callbackMethod != null) {
                    var d = data as Lang.Array;
                    callbackMethod.invoke(d);
                }
            }
            onStopSync();
            return;
        }

        switch(code) {
            case Communications.NETWORK_REQUEST_TIMED_OUT:
                syncError = WatchUi.loadResource($.Rez.Strings.TimedOut) as Lang.String;
                break;
            case Communications.INVALID_HTTP_BODY_IN_NETWORK_RESPONSE:
                syncError = WatchUi.loadResource($.Rez.Strings.NoJson) as Lang.String;
                syncError = "";
            default:
                var codeMsg = WatchUi.loadResource($.Rez.Strings.UnhandledHttpErr) as Lang.String;
                syncError = codeMsg + code;
                break;
        }

        onStopSync();
    }

    //! Clean up
    public function onStopSync() as Void {
        if (WifiLteExecutionConfirmDelegate.mCommandData[:exit]) {
            System.exit();
        }
        
        Communications.cancelAllRequests();
        Communications.notifySyncComplete(syncError);
    }
}
