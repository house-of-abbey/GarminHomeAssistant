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
    private var strNoPhone          = WatchUi.loadResource($.Rez.Strings.NoPhone);
    private var strNoInternet       = WatchUi.loadResource($.Rez.Strings.NoInternet);
    private var strNoResponse       = WatchUi.loadResource($.Rez.Strings.NoResponse);
    private var strNoJson           = WatchUi.loadResource($.Rez.Strings.NoJson);
    private var strApiFlood         = WatchUi.loadResource($.Rez.Strings.ApiFlood);
    private var strApiUrlNotFound   = WatchUi.loadResource($.Rez.Strings.ApiUrlNotFound);
    private var strUnhandledHttpErr = WatchUi.loadResource($.Rez.Strings.UnhandledHttpErr);
    private var strUnavailable      = WatchUi.loadResource($.Rez.Strings.Unavailable);
    private var strAvailable        = WatchUi.loadResource($.Rez.Strings.Available);

    private var mApiKey as Lang.String;

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
        mApiKey = Properties.getValue("api_key");
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
    //
    function onReturnGetState(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        if (Globals.scDebug) {
            System.println("HomeAssistantToggleMenuItem onReturnGetState() Response Code: " + responseCode);
            System.println("HomeAssistantToggleMenuItem onReturnGetState() Response Data: " + data);
        }

        // Provide the ability to terminate updating chain of calls for a permanent network error.
        var keepUpdating = true;
        var status       = strUnavailable;
        switch (responseCode) {
            case Communications.BLE_HOST_TIMEOUT:
            case Communications.BLE_CONNECTION_UNAVAILABLE:
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem onReturnGetState() Response Code: BLE_HOST_TIMEOUT or BLE_CONNECTION_UNAVAILABLE, Bluetooth connection severed.");
                }
                ErrorView.show(strNoPhone + ".");
                break;

            case Communications.BLE_QUEUE_FULL:
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem onReturnGetState() Response Code: BLE_QUEUE_FULL, API calls too rapid.");
                }
                ErrorView.show(strApiFlood);
                break;

            case Communications.NETWORK_REQUEST_TIMED_OUT:
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem onReturnGetState() Response Code: NETWORK_REQUEST_TIMED_OUT, check Internet connection.");
                }
                ErrorView.show(strNoResponse);
                break;

            case Communications.INVALID_HTTP_BODY_IN_NETWORK_RESPONSE:
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem onReturnGetState() Response Code: INVALID_HTTP_BODY_IN_NETWORK_RESPONSE, check JSON is returned.");
                }
                ErrorView.show(strNoJson);
                break;

            case Communications.NETWORK_RESPONSE_OUT_OF_MEMORY:
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem onReturnGetState() Response Code: NETWORK_RESPONSE_OUT_OF_MEMORY, are we going too fast?");
                }
                // Pause updates
                keepUpdating = false;
                var myTimer = new Timer.Timer();
                // Now this feels very "closely coupled" to the application, but it is the most reliable method instead of using a timer.
                myTimer.start(getApp().method(:updateNextMenuItem), Globals.scApiBackoff, false);
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
                    ErrorView.show(strApiUrlNotFound);
                }
                keepUpdating = false;
                break;

            case 405:
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem onReturnGetState() Response Code: 405. " + mIdentifier + " " + data.get("message"));
                }
                ErrorView.show("HTTP 405, " + mIdentifier + ". " + data.get("message"));
                keepUpdating = false;
                break;

            case 200:
                status = strAvailable;
                var state = data.get("state") as Lang.String;
                if (Globals.scDebug) {
                    System.println((data.get("attributes") as Lang.Dictionary).get("friendly_name") + " State=" + state);
                }
                if (getLabel().equals("...")) {
                    setLabel((data.get("attributes") as Lang.Dictionary).get("friendly_name") as Lang.String);
                }
                setUiToggle(state);
                ErrorView.unShow();
                break;

            default:
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem onReturnGetState(): Unhandled HTTP response code = " + responseCode);
                }
                ErrorView.show(strUnhandledHttpErr + responseCode);
        }
        if (keepUpdating) {
            // Now this feels very "closely coupled" to the application, but it is the most reliable method instead of using a timer.
            getApp().updateNextMenuItem();
        }
        getApp().setApiStatus(status);
    }

    function getState() as Void {
        var options = {
            :method  => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Authorization" => "Bearer " + mApiKey
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        var keepUpdating = true;
        if (! System.getDeviceSettings().phoneConnected) {
            if (Globals.scDebug) {
                System.println("HomeAssistantToggleMenuItem getState(): No Phone connection, skipping API call.");
            }
            ErrorView.show(strNoPhone + ".");
        } else if (! System.getDeviceSettings().connectionAvailable) {
            if (Globals.scDebug) {
                System.println("HomeAssistantToggleMenuItem getState(): No Internet connection, skipping API call.");
            }
            ErrorView.show(strNoInternet + ".");
        } else {
            var url = Properties.getValue("api_url") + "/states/" + mIdentifier;
            if (Globals.scDebug) {
                System.println("HomeAssistantToggleMenuItem getState() URL=" + url);
            }
            Communications.makeWebRequest(
                url,
                null,
                options,
                method(:onReturnGetState)
            );
            // The update is called by onReturnGetState() instead
            keepUpdating = false;
        }
        // On temporary failure, keep the updating going.
        if (keepUpdating) {
            // Need to avoid an infinite loop where the pushed ErrorView does not appear before getState() is called again
            // and the call stack overflows. So continue the call chain from somewhere asynchronous.
            var myTimer = new Timer.Timer();
            // Now this feels very "closely coupled" to the application, but it is the most reliable method instead of using a timer.
            myTimer.start(getApp().method(:updateNextMenuItem), 500, false);
            if (Globals.scDebug) {
                System.println("HomeAssistantToggleMenuItem getState(): Updated failed " + mIdentifier);
            }
        }
    }

    // Callback function after completing the POST request to set the status.
    //
    function onReturnSetState(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        if (Globals.scDebug) {
            System.println("HomeAssistantToggleMenuItem onReturnSetState() Response Code: " + responseCode);
            System.println("HomeAssistantToggleMenuItem onReturnSetState() Response Data: " + data);
        }

        var status = strUnavailable;
        switch (responseCode) {
            case Communications.BLE_HOST_TIMEOUT:
            case Communications.BLE_CONNECTION_UNAVAILABLE:
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem onReturnSetState() Response Code: BLE_HOST_TIMEOUT or BLE_CONNECTION_UNAVAILABLE, Bluetooth connection severed.");
                }
                ErrorView.show(strNoPhone + ".");
                break;

            case Communications.BLE_QUEUE_FULL:
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem onReturnSetState() Response Code: BLE_QUEUE_FULL, API calls too rapid.");
                }
                ErrorView.show(strApiFlood);
                break;

            case Communications.NETWORK_REQUEST_TIMED_OUT:
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem onReturnSetState() Response Code: NETWORK_REQUEST_TIMED_OUT, check Internet connection.");
                }
                ErrorView.show(strNoResponse);
                break;

            case Communications.INVALID_HTTP_BODY_IN_NETWORK_RESPONSE:
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem onReturnSetState() Response Code: INVALID_HTTP_BODY_IN_NETWORK_RESPONSE, check JSON is returned.");
                }
                ErrorView.show(strNoJson);
                break;

            case 404:
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem onReturnSetState() Response Code: 404, page not found. Check API URL setting.");
                }
                ErrorView.show(strApiUrlNotFound);
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
                status = strAvailable;
                break;

            default:
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem onReturnSetState(): Unhandled HTTP response code = " + responseCode);
                }
                ErrorView.show(strUnhandledHttpErr + responseCode);
        }
        getApp().setApiStatus(status);
    }

    function setState(s as Lang.Boolean) as Void {
        var options = {
            :method  => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON,
                "Authorization" => "Bearer " + mApiKey
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        if (! System.getDeviceSettings().phoneConnected) {
            if (Globals.scDebug) {
                System.println("HomeAssistantToggleMenuItem getState(): No Phone connection, skipping API call.");
            }
            // Toggle the UI back
            setEnabled(!isEnabled());
            ErrorView.show(strNoPhone + ".");
        } else if (! System.getDeviceSettings().connectionAvailable) {
            if (Globals.scDebug) {
                System.println("HomeAssistantToggleMenuItem getState(): No Internet connection, skipping API call.");
            }
            // Toggle the UI back
            setEnabled(!isEnabled());
            ErrorView.show(strNoInternet + ".");
        } else {
            // Updated SDK and got a new error
            // ERROR: venu: Cannot find symbol ':substring' on type 'PolyType<Null or $.Toybox.Lang.Object>'.
            var id = mIdentifier as Lang.String;
            var url;
            if (s) {
                url = Properties.getValue("api_url") + "/services/" + id.substring(0, id.find(".")) + "/turn_on";
            } else {
                url = Properties.getValue("api_url") + "/services/" + id.substring(0, id.find(".")) + "/turn_off";
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
                options,
                method(:onReturnSetState)
            );
        }
    }

}
