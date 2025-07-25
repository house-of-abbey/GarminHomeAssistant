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
// P A Abbey & J D Abbey & Someone0nEarth & moesterheld & vincentezw, 31 October 2023
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application.Properties;
using Toybox.Timer;

//! Light or switch toggle menu button that calls the API to maintain the up to date state.
//
class HomeAssistantToggleMenuItem extends WatchUi.ToggleMenuItem {
    private var mData       as Lang.Dictionary;
    private var mTemplate   as Lang.String;
    private var mExit       as Lang.Boolean;
    private var mConfirm    as Lang.Boolean;
    private var mPin        as Lang.Boolean;
    private var mHasVibrate as Lang.Boolean = false;

    //! Class Constructor
    //!
    //! @param label    Menu item label.
    //! @param template Menu item template.
    //! @param data     Data to supply to the service call.
    //! @param options  Menu item options to be passed on, including both SDK and menu options, e.g. exit, confirm & pin.
    //
    function initialize(
        label    as Lang.String or Lang.Symbol,
        template as Lang.String,
        data     as Lang.Dictionary?,
        options  as {
            :alignment as WatchUi.MenuItem.Alignment,
            :icon      as Graphics.BitmapType or WatchUi.Drawable or Lang.Symbol,
            :exit      as Lang.Boolean,
            :confirm   as Lang.Boolean,
            :pin       as Lang.Boolean
        }?
    ) {
        WatchUi.ToggleMenuItem.initialize(
            label,
            null,
            null,
            false,
            {
                :alignment => options[:alignment],
                :icon      => options[:icon]
            }
        );
        if (Attention has :vibrate) {
            mHasVibrate = true;
        }
        mData     = data;
        mTemplate = template;
        mExit     = options[:exit];
        mConfirm  = options[:confirm];
        mPin      = options[:pin];
    }

    //! Set the state of a toggle menu item.
    //
    private function setUiToggle(state as Null or Lang.String) as Void {
        if (state != null) {
            if (state.equals("on") && !isEnabled()) {
                setEnabled(true);
            } else if (state.equals("off") && isEnabled()) {
                setEnabled(false);
            }
        }
    }

    //! Return the menu item's template.
    //!
    //! @return A string with the menu item's template definition (or null).
    //
    function getTemplate() as Lang.String? {
        return mTemplate;
    }

    //! Return a toggle menu item's state template.
    //!
    //! @return A string with the menu item's template definition (or null).
    //
    function getToggleTemplate() as Lang.String? {
        return "{{states('" + mData.get("entity_id") + "')}}";
    }

    //! Update the menu item's label from a recent GET request.
    //!
    //! @param data This should be a string, but the way the GET response is parsed, it can also be a number.
    //
    function updateState(data as Lang.String or Lang.Dictionary or Lang.Number or Lang.Float or Null) as Void {
        if (data == null) {
            setSubLabel(null);
        } else if(data instanceof Lang.String) {
            setSubLabel(data);
        } else if(data instanceof Lang.Number) {
            var d = data as Lang.Number;
            setSubLabel(d.format("%d"));
        } else if(data instanceof Lang.Float) {
            var f = data as Lang.Float;
            setSubLabel(f.format("%f"));
        } else if(data instanceof Lang.Dictionary) {
            // System.println("HomeAssistantToggleMenuItem updateState() data = " + data);
            if (data.get("error") != null) {
                setSubLabel($.Rez.Strings.TemplateError);
            } else {
                setSubLabel($.Rez.Strings.PotentialError);
            }
        } else {
            // The template must return a Lang.String, Number or Float, or the item cannot be formatted locally without error.
            setSubLabel(WatchUi.loadResource($.Rez.Strings.TemplateError) as Lang.String);
        }
        WatchUi.requestUpdate();
    }

    //! Update the menu item's toggle state from a recent GET request.
    //!
    //! @param data This should be a string of either "on" or "off".
    //
    function updateToggleState(data as Lang.String or Lang.Dictionary or Null) as Void {
        if (data == null) {
            setUiToggle("off");
        } else if(data instanceof Lang.String) {
            setUiToggle(data);
            if (mTemplate == null and data.equals("unavailable")) {
                setSubLabel($.Rez.Strings.Unavailable);
            }
        } else if(data instanceof Lang.Dictionary) {
            // System.println("HomeAssistantToggleMenuItem updateState() data = " + data);
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

    //! Callback function after completing the POST request to set the status.
    //!
    //! @param responseCode Response code.
    //! @param data         Response data.
    //
    function onReturnSetState(
        responseCode as Lang.Number,
        data         as Null or Lang.Dictionary or Lang.String
    ) as Void {
        // System.println("HomeAssistantToggleMenuItem onReturnSetState() Response Code: " + responseCode);
        // System.println("HomeAssistantToggleMenuItem onReturnSetState() Response Data: " + data);

        var status = WatchUi.loadResource($.Rez.Strings.Unavailable) as Lang.String;
        switch (responseCode) {
            case Communications.BLE_HOST_TIMEOUT:
            case Communications.BLE_CONNECTION_UNAVAILABLE:
                // System.println("HomeAssistantToggleMenuItem onReturnSetState() Response Code: BLE_HOST_TIMEOUT or BLE_CONNECTION_UNAVAILABLE, Bluetooth connection severed.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String);
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
                var d = data as Lang.Array;
                setToggleStateWithData(d);
                status = WatchUi.loadResource($.Rez.Strings.Available) as Lang.String;
                break;

            default:
                // System.println("HomeAssistantToggleMenuItem onReturnSetState(): Unhandled HTTP response code = " + responseCode);
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.UnhandledHttpErr) as Lang.String + responseCode);
        }
        getApp().setApiStatus(status);
        if (mExit) {
            System.exit();
        }
    }

    //! Handles the response from a Home Assistant service or state call and updates the toggle UI.
    //!
    //! @param data An array of dictionaries, each representing a Home Assistant entity state.
    //
    function setToggleStateWithData(data as Lang.Array) {
        // If there's no response body, let's assume that what we did actually happened and flip the toggle.
        if (data.size() == 0) {
            setEnabled(!isEnabled());
        }

        else {
            for(var i = 0; i < data.size(); i++) {
                if ((data[i].get("entity_id") as Lang.String).equals(mData.get("entity_id"))) {
                    var state = data[i].get("state") as Lang.String;
                    // System.println((d[i].get("attributes") as Lang.Dictionary).get("friendly_name") + " State=" + state);
                    setUiToggle(state);
                    WatchUi.requestUpdate();
                }
            }
        }
    }

    //! Set the state of the toggle menu item.
    //!
    //! @param s Boolean indicating the desired state of the toggle switch.
    //
    function setState(s as Lang.Boolean) as Void {
        var phoneConnected = System.getDeviceSettings().phoneConnected;
        var internetAvailable = System.getDeviceSettings().connectionAvailable;
        
        if (! phoneConnected && ! Settings.getWifiLteExecutionEnabled()) {
            // System.println("HomeAssistantToggleMenuItem getState(): No Phone connection, skipping API call.");
            ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String);
        } else if (! internetAvailable && ! Settings.getWifiLteExecutionEnabled()) {
            // System.println("HomeAssistantToggleMenuItem getState(): No Internet connection, skipping API call.");
            // Toggle the UI back
            ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoInternet) as Lang.String);
        } else {
            var id  = mData.get("entity_id") as Lang.String;
            var url = getUrl(id, s);

            if ((! phoneConnected || ! internetAvailable) && Settings.getWifiLteExecutionEnabled()) {
                // Undo the toggle
                setEnabled(!isEnabled());
                wifiPrompt(s);
                return;
            }

            // System.println("HomeAssistantToggleMenuItem setState() URL       = " + url);
            // System.println("HomeAssistantToggleMenuItem setState() entity_id = " + id);
            Communications.makeWebRequest(
                url,
                mData,
                {
                    :method       => Communications.HTTP_REQUEST_METHOD_POST,
                    :headers      => {
                        "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON,
                        "Authorization" => "Bearer " + Settings.getApiKey()
                    },
                    :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
                },
                method(:onReturnSetState)
            );
            if (mHasVibrate and Settings.getVibrate()) {
                Attention.vibrate([
                    new Attention.VibeProfile(50, 100), // On  for 100ms
                    new Attention.VibeProfile( 0, 100), // Off for 100ms
                    new Attention.VibeProfile(50, 100)  // On  for 100ms
                ]);
            }
        }
    }

    //! Call a Home Assistant service only after checks have been done for confirmation or PIN entry.
    //
    function callService(b as Lang.Boolean) as Void {
        var hasTouchScreen = System.getDeviceSettings().isTouchScreen;
        if (mPin && hasTouchScreen) {
            // Undo the toggle
            setEnabled(!isEnabled());

            var pin = Settings.getPin();
            if (pin != null) {
                var pinConfirmationView = new HomeAssistantPinConfirmationView();
                WatchUi.pushView(
                    pinConfirmationView,
                    new HomeAssistantPinConfirmationDelegate({
                        :callback       => method(:onConfirm),
                        :pin            => pin,
                        :state          => b,
                        :toggleMethod   => method(:setEnabled),
                        :view           => pinConfirmationView,
                    }),
                    WatchUi.SLIDE_IMMEDIATE
                );
            }
        } else if (mConfirm) {
            // Undo the toggle
            setEnabled(!isEnabled());

            var phoneConnected = System.getDeviceSettings().phoneConnected;
            var internetAvailable = System.getDeviceSettings().connectionAvailable;
            if ((! phoneConnected || ! internetAvailable) && Settings.getWifiLteExecutionEnabled()) {
                wifiPrompt(b);
            } else {
                var confirmationView = new HomeAssistantConfirmation();
                WatchUi.pushView(
                    confirmationView,
                    new HomeAssistantConfirmationDelegate({
                        :callback           => method(:onConfirm),
                        :confirmationView   => confirmationView,
                        :state              => b,
                        :toggleMethod       => method(:setEnabled),
                    }),
                    WatchUi.SLIDE_IMMEDIATE
                );
            }
        } else {
            onConfirm(b);
        }
    }

    //! Callback function to toggle state of this item after (optional) confirmation.
    //!
    //! @param b Desired toggle button state.
    //
    function onConfirm(b as Lang.Boolean) as Void {
        setState(b);
    }

    //! Displays a confirmation dialog before executing a service call via Wi-Fi/LTE.
    //!
    //! @param s Desired state: `true` to turn on, `false` to turn off.
    //
    private function wifiPrompt(s as Lang.Boolean) as Void {
        var id        = mData.get("entity_id") as Lang.String;
        var url       = getUrl(id, s);
        var dialogMsg = WatchUi.loadResource($.Rez.Strings.WifiLtePrompt) as Lang.String;
        var dialog    = new WatchUi.Confirmation(dialogMsg);
        WatchUi.pushView(
            dialog,
            new WifiLteExecutionConfirmDelegate({
                :type => "entity",
                :url => url,
                :id => id,
                :data => mData,
                :callback => method(:setToggleStateWithData),
                :exit => mExit,
            }, dialog),
            WatchUi.SLIDE_LEFT
        );
    }

    //! Constructs a Home Assistant API URL for the given entity and desired state.
    //!
    //! @param id The entity ID, e.g., `"switch.kitchen"`.
    //! @param s Desired state: `true` for "turn_on", `false` for "turn_off".
    //!
    //! @return Full service URL string.
    //
    private static function getUrl(id as Lang.String, s as Lang.Boolean) as Lang.String {
        var url = Settings.getApiUrl() + "/services/";
        if (s) {
            url = url + id.substring(0, id.find(".")) + "/turn_on";
        } else {
            url = url + id.substring(0, id.find(".")) + "/turn_off";
        }

        return url;
    }
}
