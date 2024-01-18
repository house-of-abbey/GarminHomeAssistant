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
// P A Abbey & J D Abbey & Someone0nEarth, 31 October 2023
//
//
// Description:
//
// Light or switch toggle button that calls the API to maintain the up to date state.
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application.Properties;
using Toybox.Timer;

class HomeAssistantToggleMenuItem extends WatchUi.ToggleMenuItem {

    function initialize(
        label     as Lang.String or Lang.Symbol,
        subLabel  as Lang.String or Lang.Symbol or {
            :enabled  as Lang.String or Lang.Symbol or Null,
            :disabled as Lang.String or Lang.Symbol or Null
        } or Null,
        identifier,
        enabled   as Lang.Boolean,
        options   as {
            :alignment as WatchUi.MenuItem.Alignment,
            :icon      as Graphics.BitmapType or WatchUi.Drawable or Lang.Symbol
        } or Null
    ) {
        WatchUi.ToggleMenuItem.initialize(label, subLabel, identifier, enabled, options);
    }

    private function setUiToggle(state as Null or Lang.String) as Void {
        if (state != null) {
            if (state.equals("on") && !isEnabled()) {
                setEnabled(true);
                WatchUi.requestUpdate();
            } else if (state.equals("off") && isEnabled()) {
                setEnabled(false);
                WatchUi.requestUpdate();
            }
        }
    }

    // Callback function after completing the GET request to fetch the status.
    // Terminate updating the toggle menu items via the chain of calls for a permanent network
    // error. The ErrorView cancellation will resume the call chain.
    //
    function onReturnGetState(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        if (Globals.scDebug) {
            System.println("HomeAssistantToggleMenuItem onReturnGetState() Response Code: " + responseCode);
            System.println("HomeAssistantToggleMenuItem onReturnGetState() Response Data: " + data);
        }

        var status = RezStrings.getUnavailable();
        switch (responseCode) {
            case Communications.BLE_HOST_TIMEOUT:
            case Communications.BLE_CONNECTION_UNAVAILABLE:
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem onReturnGetState() Response Code: BLE_HOST_TIMEOUT or BLE_CONNECTION_UNAVAILABLE, Bluetooth connection severed.");
                }
                ErrorView.show(RezStrings.getNoPhone() + ".");
                break;

            case Communications.BLE_QUEUE_FULL:
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem onReturnGetState() Response Code: BLE_QUEUE_FULL, API calls too rapid.");
                }
                ErrorView.show(RezStrings.getApiFlood());
                break;

            case Communications.NETWORK_REQUEST_TIMED_OUT:
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem onReturnGetState() Response Code: NETWORK_REQUEST_TIMED_OUT, check Internet connection.");
                }
                ErrorView.show(RezStrings.getNoResponse());
                break;

            case Communications.INVALID_HTTP_BODY_IN_NETWORK_RESPONSE:
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem onReturnGetState() Response Code: INVALID_HTTP_BODY_IN_NETWORK_RESPONSE, check JSON is returned.");
                }
                ErrorView.show(RezStrings.getNoJson());
                break;

            case Communications.NETWORK_RESPONSE_OUT_OF_MEMORY:
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem onReturnGetState() Response Code: NETWORK_RESPONSE_OUT_OF_MEMORY, are we going too fast?");
                }
                var myTimer = new Timer.Timer();
                // Now this feels very "closely coupled" to the application, but it is the most reliable method instead of using a timer.
                myTimer.start(getApp().method(:updateNextMenuItem), Globals.scApiBackoff, false);
                // Revert status
                status = getApp().getApiStatus();
                break;

            case 404:
                var msg = null;
                if (data != null) {
                    msg = data.get("message");
                }
                if (msg != null) {
                    // Should be an HTTP 404 according to curl queries
                    if (Globals.scDebug) {
                        System.println("HomeAssistantToggleMenuItem onReturnGetState() Response Code: 404. " + mIdentifier + " " + msg);
                    }
                    ErrorView.show("HTTP 404, " + mIdentifier + ". " + data.get("message"));
                } else {
                    if (Globals.scDebug) {
                        System.println("HomeAssistantToggleMenuItem onReturnGetState() Response Code: 404, page not found. Check API URL setting.");
                    }
                    ErrorView.show(RezStrings.getApiUrlNotFound());
                }
                break;

            case 405:
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem onReturnGetState() Response Code: 405. " + mIdentifier + " " + data.get("message"));
                }
                ErrorView.show("HTTP 405, " + mIdentifier + ". " + data.get("message"));

                break;

            case 200:
                status = RezStrings.getAvailable();
                var state = data.get("state") as Lang.String;
                if (Globals.scDebug) {
                    System.println((data.get("attributes") as Lang.Dictionary).get("friendly_name") + " State=" + state);
                }
                if (getLabel().equals("...")) {
                    setLabel((data.get("attributes") as Lang.Dictionary).get("friendly_name") as Lang.String);
                }
                setUiToggle(state);
                // Now this feels very "closely coupled" to the application, but it is the most reliable method instead of using a timer.
                getApp().updateNextMenuItem();
                break;

            default:
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem onReturnGetState(): Unhandled HTTP response code = " + responseCode);
                }
                ErrorView.show(RezStrings.getUnhandledHttpErr() + responseCode);
        }
        getApp().setApiStatus(status);
    }

    function getState() as Void {
        if (! System.getDeviceSettings().phoneConnected) {
            if (Globals.scDebug) {
                System.println("HomeAssistantToggleMenuItem getState(): No Phone connection, skipping API call.");
            }
            ErrorView.show(RezStrings.getNoPhone() + ".");
            getApp().setApiStatus(RezStrings.getUnavailable());
        } else if (! System.getDeviceSettings().connectionAvailable) {
            if (Globals.scDebug) {
                System.println("HomeAssistantToggleMenuItem getState(): No Internet connection, skipping API call.");
            }
            ErrorView.show(RezStrings.getNoInternet() + ".");
            getApp().setApiStatus(RezStrings.getUnavailable());
        } else {
            var url = Settings.getApiUrl() + "/states/" + mIdentifier;
            if (Globals.scDebug) {
                System.println("HomeAssistantToggleMenuItem getState() URL=" + url);
            }
            Communications.makeWebRequest(
                url,
                null,
                {
                    :method  => Communications.HTTP_REQUEST_METHOD_GET,
                    :headers => {
                        "Authorization" => "Bearer " + Settings.getApiKey()
                    },
                    :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
                },
                method(:onReturnGetState)
            );
        }
    }

    // Callback function after completing the POST request to set the status.
    //
    function onReturnSetState(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        if (Globals.scDebug) {
            System.println("HomeAssistantToggleMenuItem onReturnSetState() Response Code: " + responseCode);
            System.println("HomeAssistantToggleMenuItem onReturnSetState() Response Data: " + data);
        }

        var status = RezStrings.getUnavailable();
        switch (responseCode) {
            case Communications.BLE_HOST_TIMEOUT:
            case Communications.BLE_CONNECTION_UNAVAILABLE:
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem onReturnSetState() Response Code: BLE_HOST_TIMEOUT or BLE_CONNECTION_UNAVAILABLE, Bluetooth connection severed.");
                }
                ErrorView.show(RezStrings.getNoPhone() + ".");
                break;

            case Communications.BLE_QUEUE_FULL:
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem onReturnSetState() Response Code: BLE_QUEUE_FULL, API calls too rapid.");
                }
                ErrorView.show(RezStrings.getApiFlood());
                break;

            case Communications.NETWORK_REQUEST_TIMED_OUT:
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem onReturnSetState() Response Code: NETWORK_REQUEST_TIMED_OUT, check Internet connection.");
                }
                ErrorView.show(RezStrings.getNoResponse());
                break;

            case Communications.INVALID_HTTP_BODY_IN_NETWORK_RESPONSE:
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem onReturnSetState() Response Code: INVALID_HTTP_BODY_IN_NETWORK_RESPONSE, check JSON is returned.");
                }
                ErrorView.show(RezStrings.getNoJson());
                break;

            case 404:
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem onReturnSetState() Response Code: 404, page not found. Check API URL setting.");
                }
                ErrorView.show(RezStrings.getApiUrlNotFound());
                break;

            case 200:
                var state;
                var d = data as Lang.Array;
                for(var i = 0; i < d.size(); i++) {
                    if ((d[i].get("entity_id") as Lang.String).equals(mIdentifier)) {
                        state = d[i].get("state") as Lang.String;
                        if (Globals.scDebug) {
                            System.println((d[i].get("attributes") as Lang.Dictionary).get("friendly_name") + " State=" + state);
                        }
                        setUiToggle(state);
                    }
                }
                status = RezStrings.getAvailable();
                break;

            default:
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem onReturnSetState(): Unhandled HTTP response code = " + responseCode);
                }
                ErrorView.show(RezStrings.getUnhandledHttpErr() + responseCode);
        }
        getApp().setApiStatus(status);
    }

    function setState(s as Lang.Boolean) as Void {
        if (! System.getDeviceSettings().phoneConnected) {
            if (Globals.scDebug) {
                System.println("HomeAssistantToggleMenuItem getState(): No Phone connection, skipping API call.");
            }
            // Toggle the UI back
            setEnabled(!isEnabled());
            ErrorView.show(RezStrings.getNoPhone() + ".");
        } else if (! System.getDeviceSettings().connectionAvailable) {
            if (Globals.scDebug) {
                System.println("HomeAssistantToggleMenuItem getState(): No Internet connection, skipping API call.");
            }
            // Toggle the UI back
            setEnabled(!isEnabled());
            ErrorView.show(RezStrings.getNoInternet() + ".");
        } else {
            // Updated SDK and got a new error
            // ERROR: venu: Cannot find symbol ':substring' on type 'PolyType<Null or $.Toybox.Lang.Object>'.
            var id  = mIdentifier as Lang.String;
            var url = Settings.getApiUrl() + "/services/";
            if (s) {
                url = url + id.substring(0, id.find(".")) + "/turn_on";
            } else {
                url = url + id.substring(0, id.find(".")) + "/turn_off";
            }
            if (Globals.scDebug) {
                System.println("HomeAssistantToggleMenuItem setState() URL=" + url);
                System.println("HomeAssistantToggleMenuItem setState() mIdentifier=" + mIdentifier);
            }
            Communications.makeWebRequest(
                url,
                {
                    "entity_id" => mIdentifier
                },
                {
                    :method  => Communications.HTTP_REQUEST_METHOD_POST,
                    :headers => {
                        "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON,
                        "Authorization" => "Bearer " + Settings.getApiKey()
                    },
                    :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
                },
                method(:onReturnSetState)
            );
        }
    }

}
