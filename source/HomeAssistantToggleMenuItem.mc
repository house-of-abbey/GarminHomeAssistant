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
    private var mConfirm  as Lang.Boolean;
    private var mData     as Lang.Dictionary;
    private var mTemplate as Lang.String;

    function initialize(
        label    as Lang.String or Lang.Symbol,
        template as Lang.String,
        confirm  as Lang.Boolean,
        data     as Lang.Dictionary or Null,
        options  as {
            :alignment as WatchUi.MenuItem.Alignment,
            :icon      as Graphics.BitmapType or WatchUi.Drawable or Lang.Symbol
        } or Null
    ) {
        WatchUi.ToggleMenuItem.initialize(label, null, null, false, options);
        mConfirm  = confirm;
        mData     = data;
        mTemplate = template;
    }

    private function setUiToggle(state as Null or Lang.String) as Void {
        if (state != null) {
            if (state.equals("on") && !isEnabled()) {
                setEnabled(true);
            } else if (state.equals("off") && isEnabled()) {
                setEnabled(false);
            }
        }
    }

    function buildTemplate() as Lang.String or Null {
        return mTemplate;
    }
    function buildToggleTemplate() as Lang.String or Null {
        return "{{states('" + mData.get("entity_id") + "')}}";
    }

    function updateState(data as Lang.String or Lang.Dictionary or Null) as Void {
        if (data == null) {
            setSubLabel(null);
        } else if(data instanceof Lang.String) {
            setSubLabel(data);
        } else if(data instanceof Lang.Dictionary) {
            // System.println("HomeAsistantToggleMenuItem updateState() data = " + data);
            if (data.get("error") != null) {
                setSubLabel($.Rez.Strings.TemplateError);
            } else {
                setSubLabel($.Rez.Strings.PotentialError);
            }
        } else {
            // The template must return a Lang.String, a number can be either integer or float and hence cannot be formatted locally without error.
            setSubLabel(WatchUi.loadResource($.Rez.Strings.TemplateError) as Lang.String);
        }
        WatchUi.requestUpdate();
    }
    function updateToggleState(data as Lang.String or Lang.Dictionary or Null) as Void {
        if (data == null) {
            setUiToggle("off");
        } else if(data instanceof Lang.String) {
            setUiToggle(data);
            if (mTemplate == null and data.equals("unavailable")) {
                setSubLabel($.Rez.Strings.Unavailable);
            }
        } else if(data instanceof Lang.Dictionary) {
            // System.println("HomeAsistantToggleMenuItem updateState() data = " + data);
            if (mTemplate == null) {
                if (data.get("error") != null) {
                    setSubLabel($.Rez.Strings.TemplateError);
                } else {
                    setSubLabel($.Rez.Strings.PotentialError);
                }
            }
        } else {
            // The template must return a Lang.String, a number can be either integer or float and hence cannot be formatted locally without error.
            if (mTemplate == null) {
                setSubLabel(WatchUi.loadResource($.Rez.Strings.TemplateError) as Lang.String);
            }
        }
        WatchUi.requestUpdate();
    }

    // Callback function after completing the POST request to set the status.
    //
    function onReturnSetState(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        // System.println("HomeAssistantToggleMenuItem onReturnSetState() Response Code: " + responseCode);
        // System.println("HomeAssistantToggleMenuItem onReturnSetState() Response Data: " + data);

        var status = WatchUi.loadResource($.Rez.Strings.Unavailable) as Lang.String;
        switch (responseCode) {
            case Communications.BLE_HOST_TIMEOUT:
            case Communications.BLE_CONNECTION_UNAVAILABLE:
                // System.println("HomeAssistantToggleMenuItem onReturnSetState() Response Code: BLE_HOST_TIMEOUT or BLE_CONNECTION_UNAVAILABLE, Bluetooth connection severed.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String + ".");
                break;

            case Communications.BLE_QUEUE_FULL:
                // System.println("HomeAssistantToggleMenuItem onReturnSetState() Response Code: BLE_QUEUE_FULL, API calls too rapid.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.ApiFlood) as Lang.String);
                break;

            case Communications.NETWORK_REQUEST_TIMED_OUT:
                // System.println("HomeAssistantToggleMenuItem onReturnSetState() Response Code: NETWORK_REQUEST_TIMED_OUT, check Internet connection.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoResponse) as Lang.String);
                break;

            case Communications.INVALID_HTTP_BODY_IN_NETWORK_RESPONSE:
                // System.println("HomeAssistantToggleMenuItem onReturnSetState() Response Code: INVALID_HTTP_BODY_IN_NETWORK_RESPONSE, check JSON is returned.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoJson) as Lang.String);
                break;

            case 404:
                // System.println("HomeAssistantToggleMenuItem onReturnSetState() Response Code: 404, page not found. Check API URL setting.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.ApiUrlNotFound) as Lang.String);
                break;

            case 200:
                // System.println("HomeAssistantToggleMenuItem onReturnSetState(): Service executed.");
                getApp().forceStatusUpdates();
                var state;
                var d = data as Lang.Array;
                for(var i = 0; i < d.size(); i++) {
                    if ((d[i].get("entity_id") as Lang.String).equals(mData.get("entity_id"))) {
                        state = d[i].get("state") as Lang.String;
                        // System.println((d[i].get("attributes") as Lang.Dictionary).get("friendly_name") + " State=" + state);
                        setUiToggle(state);
                        WatchUi.requestUpdate();
                    }
                }
                status = WatchUi.loadResource($.Rez.Strings.Available) as Lang.String;
                break;

            default:
                // System.println("HomeAssistantToggleMenuItem onReturnSetState(): Unhandled HTTP response code = " + responseCode);
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.UnhandledHttpErr) as Lang.String + responseCode);
        }
        getApp().setApiStatus(status);
    }

    function setState(s as Lang.Boolean) as Void {
        if (! System.getDeviceSettings().phoneConnected) {
            // System.println("HomeAssistantToggleMenuItem getState(): No Phone connection, skipping API call.");
            // Toggle the UI back
            setEnabled(!isEnabled());
            ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String + ".");
        } else if (! System.getDeviceSettings().connectionAvailable) {
            // System.println("HomeAssistantToggleMenuItem getState(): No Internet connection, skipping API call.");
            // Toggle the UI back
            setEnabled(!isEnabled());
            ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoInternet) as Lang.String + ".");
        } else {
            // Updated SDK and got a new error
            // ERROR: venu: Cannot find symbol ':substring' on type 'PolyType<Null or $.Toybox.Lang.Object>'.
            var id  = mData.get("entity_id") as Lang.String;
            var url = Settings.getApiUrl() + "/services/";
            if (s) {
                url = url + id.substring(0, id.find(".")) + "/turn_on";
            } else {
                url = url + id.substring(0, id.find(".")) + "/turn_off";
            }
            // System.println("HomeAssistantToggleMenuItem setState() URL       = " + url);
            // System.println("HomeAssistantToggleMenuItem setState() entity_id = " + id);
            Communications.makeWebRequest(
                url,
                mData,
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

    function callService(b as Lang.Boolean) as Void {
        if (mConfirm) {
            WatchUi.pushView(
                new HomeAssistantConfirmation(),
                new HomeAssistantConfirmationDelegate(method(:onConfirm), b),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else {
            setState(b);
        }
    }

    function onConfirm(b as Lang.Boolean) as Void {
        setState(b);
    }

}
