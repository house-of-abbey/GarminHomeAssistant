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

using Toybox.Communications;
using Toybox.Lang;

//! SyncDelegate to execute single command via POST request to the Home Assistant
//! server.
//
class HomeAssistantSyncDelegate extends Communications.SyncDelegate {
    //! Retain the last synchronisation error.
    private static var syncError as Lang.String?;

    //! Class Constructor
    //
    public function initialize() {
        SyncDelegate.initialize();
    }

    //! Called by the system to determine if a synchronisation is needed
    //
    public function isSyncNeeded() as Lang.Boolean {
        return true;
    }

    //! Called by the system when starting a bulk synchronisation.
    //
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

    //! Performs a POST request to the Home Assistant server with a given payload and URL, and calls
    //! haCallback.
    //!
    //! @param url  URL for the API call.
    //! @param data Data to be supplied to the API call.
    //
    private function performRequest(url as Lang.String, data as Lang.Dictionary?) {
        Communications.makeWebRequest(
            url,
            data, // May include {"entity_id": xxxx} for service calls
            {
                :method  => Communications.HTTP_REQUEST_METHOD_POST,
                :headers => Settings.augmentHttpHeaders({
                    "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON,
                    "Authorization" => "Bearer " + Settings.getApiKey()
                }),
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
            },
            method(:haCallback)
        );
    }

    //! Handle callback from request
    //!
    //! @param responseCode Response code.
    //! @param data         Response data.
    //
    public function haCallback(code as Lang.Number, data as Lang.Dictionary?) as Void {
        Communications.notifySyncProgress(100);
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
    //
    public function onStopSync() as Void {
        if (WifiLteExecutionConfirmDelegate.mCommandData[:exit]) {
            System.exit();
        }
        Communications.cancelAllRequests();
        Communications.notifySyncComplete(syncError);
    }
}
