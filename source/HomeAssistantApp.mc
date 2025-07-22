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
// P A Abbey & J D Abbey & Someone0nEarth & moesterheld, 31 October 2023
//
//-----------------------------------------------------------------------------------

using Toybox.Application;
using Toybox.Communications;
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.System;
using Toybox.Application.Properties;
using Toybox.Timer;

//! Application root for GarminHomeAssistant
//
(:glance, :background)
class HomeAssistantApp extends Application.AppBase {
    private var mApiStatus      as Lang.String       or Null;
    private var mHasToast       as Lang.Boolean = false;
    private var mMenuStatus     as Lang.String       or Null;
    private var mHaMenu         as HomeAssistantView or Null;
    private var mGlanceTemplate as Lang.String       or Null = null;
    private var mGlanceText     as Lang.String       or Null = null;
    private var mQuitTimer      as QuitTimer         or Null;
    private var mGlanceTimer    as Timer.Timer       or Null;
    private var mUpdateTimer    as Timer.Timer       or Null;
    // Array initialised by onReturnFetchMenuConfig()
    private var mItemsToUpdate  as Lang.Array<HomeAssistantToggleMenuItem or HomeAssistantTapMenuItem or HomeAssistantGroupMenuItem> or Null;
    private var mIsGlance       as Lang.Boolean    = false;
    private var mIsApp          as Lang.Boolean    = false; // Or Widget
    private var mUpdating       as Lang.Boolean    = false; // Don't start a second chain of updates
    private var mTemplates      as Lang.Dictionary = {};
    private var mNotifiedNoBle  as Lang.Boolean = false;

    private const wifiPollDelayMs = 2000;

    //! Class Constructor
    //
    function initialize() {
        AppBase.initialize();
        // ATTENTION when adding stuff into this block:
        // Because of the >>GlanceView<<, it should contain only
        // code, which is used as well for the glance:
        // - https://developer.garmin.com/connect-iq/core-topics/glances/
        //
        // Also dealing with resources "Rez" needs attention, too. See
        // "Resource Scopes":
        // - https://developer.garmin.com/connect-iq/core-topics/resources/
        //
        // Classes which are used for the glance view, needed to be tagged
        // with "(:glance)".
    }

    //! Called on application start up
    //!
    //! @param state see `AppBase.onStart()`
    //
    function onStart(state as Lang.Dictionary?) as Void {
        AppBase.onStart(state);
        // ATTENTION when adding stuff into this block:
        // Because of the >>GlanceView<<, it should contain only
        // code, which is used as well for the glance:
        // - https://developer.garmin.com/connect-iq/core-topics/glances/
        //
        // Also dealing with resources "Rez" needs attention, too. See
        // "Resource Scopes":
        // - https://developer.garmin.com/connect-iq/core-topics/resources/
        //
        // Classes which are used for the glance view, needed to be tagged
        // with "(:glance)".
    }

    //! Called when your application is exiting
    //
    //!
    //! @param state see `AppBase.onStop()`
    //
    function onStop(state as Lang.Dictionary?) as Void {
        AppBase.onStop(state);
        // ATTENTION when adding stuff into this block:
        // Because of the >>GlanceView<<, it should contain only
        // code, which is used as well for the glance:
        // - https://developer.garmin.com/connect-iq/core-topics/glances/
        //
        // Also dealing with resources "Rez" needs attention, too. See
        // "Resource Scopes":
        // - https://developer.garmin.com/connect-iq/core-topics/resources/
        //
        // Classes which are used for the glance view, needed to be tagged
        // with "(:glance)".
    }

    //! Returns the initial view of the application.
    //!
    //! @return The initial view.
    //
    function getInitialView() as [ WatchUi.Views ] or [ WatchUi.Views, WatchUi.InputDelegates ] {
        mIsApp       = true;
        mQuitTimer   = new QuitTimer();
        mUpdateTimer = new Timer.Timer();
        mApiStatus   = WatchUi.loadResource($.Rez.Strings.Checking) as Lang.String;
        mMenuStatus  = WatchUi.loadResource($.Rez.Strings.Checking) as Lang.String;
        mHasToast    = WatchUi has :showToast;
        Settings.update();

        if (Settings.getApiKey().length() == 0) {
            // System.println("HomeAssistantApp getInitialView(): No API key in the application Settings.");
            return ErrorView.create(WatchUi.loadResource($.Rez.Strings.NoAPIKey) as Lang.String);
        } else if (Settings.getApiUrl().length() == 0) {
            // System.println("HomeAssistantApp getInitialView(): No API URL in the application Settings.");
            return ErrorView.create(WatchUi.loadResource($.Rez.Strings.NoApiUrl) as Lang.String);
        } else if (Settings.getApiUrl().substring(-1, Settings.getApiUrl().length()).equals("/")) {
            // System.println("HomeAssistantApp getInitialView(): API URL must not have a trailing slash '/'.");
            return ErrorView.create(WatchUi.loadResource($.Rez.Strings.TrailingSlashErr) as Lang.String);
        } else if (Settings.getConfigUrl().length() == 0) {
            // System.println("HomeAssistantApp getInitialView(): No configuration URL in the application settings.");
            return ErrorView.create(WatchUi.loadResource($.Rez.Strings.NoConfigUrl) as Lang.String);
        } else if (Settings.getPin() == null) {
            // System.println("HomeAssistantApp getInitialView(): Invalid PIN in application settings.");
            return ErrorView.create(WatchUi.loadResource($.Rez.Strings.SettingsPinError) as Lang.String);
        } else if (! System.getDeviceSettings().phoneConnected and Settings.getWifiLteExecutionEnabled() and ! hasCachedMenu()) {
            // System.println("HomeAssistantApp getInitialView(): No Phone connection, no cached menu, skipping API call.");
            return ErrorView.create(WatchUi.loadResource($.Rez.Strings.NoPhoneNoCache) as Lang.String);
        } else if (! System.getDeviceSettings().phoneConnected and ! Settings.getWifiLteExecutionEnabled()) {
            // System.println("HomeAssistantApp getInitialView(): No Phone connection and Wi-Fi disabled, skipping API call.");
            return ErrorView.create(WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String);
        } else if (! System.getDeviceSettings().connectionAvailable and ! Settings.getWifiLteExecutionEnabled()) {
            // System.println("HomeAssistantApp getInitialView(): No Internet connection and Wi-Fi disabled, skipping API call.");
            return ErrorView.create(WatchUi.loadResource($.Rez.Strings.NoInternet) as Lang.String);
        } else {
            var isCached = fetchMenuConfig();
            var ret      = null;
            fetchApiStatus();
            if (isCached) {
                ret = [mHaMenu, new HomeAssistantViewDelegate(true)];
            } else {
                ret = [new WatchUi.View(), new WatchUi.BehaviorDelegate()];
            }
            // Separated from Settings.update() in order to call after fetchMenuConfig() and not call it on changes settings.
            Settings.webhook();
            return ret;
        }
    }

    //! Callback function after completing the GET request to fetch the configuration menu.
    //!
    //! @param responseCode Response code.
    //! @param data         Response data.
    //
    (:glance)
    function onReturnFetchMenuConfig(
        responseCode as Lang.Number,
        data         as Null or Lang.Dictionary or Lang.String
    ) as Void {
        // System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Code: " + responseCode);
        // System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Data: " + data);

        mMenuStatus = WatchUi.loadResource($.Rez.Strings.Unavailable) as Lang.String;
        switch (responseCode) {
            case Communications.BLE_HOST_TIMEOUT:
            case Communications.BLE_CONNECTION_UNAVAILABLE:
                // System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Code: BLE_HOST_TIMEOUT or BLE_CONNECTION_UNAVAILABLE, Bluetooth connection severed.");
                if (!mIsGlance) {
                    ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String);
                }
                break;

            case Communications.BLE_QUEUE_FULL:
                // System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Code: BLE_QUEUE_FULL, API calls too rapid.");
                if (!mIsGlance) {
                    ErrorView.show(WatchUi.loadResource($.Rez.Strings.ApiFlood) as Lang.String);
                }
                break;

            case Communications.NETWORK_REQUEST_TIMED_OUT:
                // System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Code: NETWORK_REQUEST_TIMED_OUT, check Internet connection.");
                if (!mIsGlance) {
                    ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoResponse) as Lang.String);
                }
                break;

            case Communications.INVALID_HTTP_BODY_IN_NETWORK_RESPONSE:
                // System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Code: INVALID_HTTP_BODY_IN_NETWORK_RESPONSE, check JSON is returned.");
                if (!mIsGlance) {
                    ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoJson) as Lang.String);
                }
                break;

            case 404:
                // System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Code: 404, page not found. Check Configuration URL setting.");
                if (!mIsGlance) {
                    ErrorView.show(WatchUi.loadResource($.Rez.Strings.ConfigUrlNotFound) as Lang.String);
                }
                break;

            case 200:
                if (data == null) {
                    mMenuStatus = WatchUi.loadResource($.Rez.Strings.Unavailable) as Lang.String;
                } else {
                    if (Settings.getCacheConfig()) {
                        Storage.setValue("menu", data as Lang.Dictionary);
                        mMenuStatus = WatchUi.loadResource($.Rez.Strings.Cached) as Lang.String;
                    } else {
                        mMenuStatus = WatchUi.loadResource($.Rez.Strings.Available) as Lang.String;
                    }
                }
                if (mIsGlance) {
                    glanceTemplate(data);
                } else {
                    if (data == null) {
                        ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoJson) as Lang.String);
                    } else {
                        buildMenu(data);
                        WatchUi.switchToView(mHaMenu, new HomeAssistantViewDelegate(false), WatchUi.SLIDE_IMMEDIATE);
                    }
                }
                break;

            default:
                // System.println("HomeAssistantApp onReturnFetchMenuConfig(): Unhandled HTTP response code = " + responseCode);
                if (!mIsGlance) {
                    ErrorView.show(WatchUi.loadResource($.Rez.Strings.UnhandledHttpErr) as Lang.String + responseCode);
                }
                break;
        }
        WatchUi.requestUpdate();
    }

    //! Can we use the cached menu?
    //!
    //! @return Return true if there's a menu in cache, and if the user has enabled the cache and 
    //! has not requested to have the cache busted.
    //
    function hasCachedMenu() as Lang.Boolean {
        if (Settings.getClearCache() || !Settings.getCacheConfig()) {
            return false;
        }

        var menu = Storage.getValue("menu") as Lang.Dictionary;
        return menu != null;
    }

    //! Fetch the menu configuration over HTTPS, which might be locally cached.
    //!
    //! @return Return true if the menu came from the cache, otherwise false. This is because fetching
    //!         the menu when not in the cache is asynchronous and affects how the views are managed.
    //
    (:glance)
    function fetchMenuConfig() as Lang.Boolean {
        // System.println("Menu URL = " + Settings.getConfigUrl());
        if (Settings.getConfigUrl().equals("")) {
            mMenuStatus = WatchUi.loadResource($.Rez.Strings.Unconfigured) as Lang.String;
            WatchUi.requestUpdate();
        } else {
            var menu = Storage.getValue("menu") as Lang.Dictionary;
            if (menu != null and (Settings.getClearCache() || !Settings.getCacheConfig())) {
                Storage.deleteValue("menu");
                menu = null;
                Settings.unsetClearCache();
            }
            if (menu == null) {
                var phoneConnected = System.getDeviceSettings().phoneConnected;
                var internetAvailable = System.getDeviceSettings().connectionAvailable;
                if (! phoneConnected or ! internetAvailable) {
                    var errorRez = $.Rez.Strings.NoPhone;
                    if (Settings.getWifiLteExecutionEnabled()) {
                        errorRez = $.Rez.Strings.NoPhoneNoCache;
                    } else if (! internetAvailable) {
                        errorRez = $.Rez.Strings.Unavailable;
                    }
                    // System.println("HomeAssistantApp fetchMenuConfig(): No Phone connection, skipping API call.");
                    if (mIsGlance) {
                        WatchUi.requestUpdate();
                    } else {
                        ErrorView.show(WatchUi.loadResource(errorRez) as Lang.String);
                    }
                    mMenuStatus = WatchUi.loadResource(errorRez) as Lang.String;
                } else {
                    Communications.makeWebRequest(
                        Settings.getConfigUrl(),
                        null,
                        {
                            :method       => Communications.HTTP_REQUEST_METHOD_GET,
                            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
                        },
                        method(:onReturnFetchMenuConfig)
                    );
                }
            } else {
                mMenuStatus = WatchUi.loadResource($.Rez.Strings.Cached) as Lang.String;
                WatchUi.requestUpdate();
                if (mIsGlance) {
                    glanceTemplate(menu);
                } else {
                    buildMenu(menu);
                }
                return true;
            }
        }
        return false;
    }

    //! Build the menu and store in `mHaMenu`. Then start updates if necessary.
    //!
    //! @param menu The dictionary derived from the JSON menu fetched by `fetchMenuConfig()`.
    //
    private function buildMenu(menu as Lang.Dictionary) {
        mHaMenu = new HomeAssistantView(menu, null);
        mQuitTimer.begin();
        if (!Settings.getWebhookId().equals("")) {
            startUpdates();
        } // If not, this will be done via a chain in Settings.webhook() and mWebhookManager.requestWebhookId() that registers the sensors.
    }

    //! Start the periodic menu updates for as long as the application is running.
    //
    function startUpdates() as Void {
        if (mHaMenu != null and !mUpdating) {
            // Start the continuous update process that continues for as long as the application is running.
            mUpdating = true;
            updateMenuItems();
        }
    }

    //! Extract the optional template to override the default glance view.
    //
    function glanceTemplate(menu as Lang.Dictionary) {
        if (menu != null) {
            if (menu.get("glance") != null) {
                var glance = menu.get("glance") as Lang.Dictionary;
                if (glance.get("type").equals("info")) {
                    mGlanceTemplate = glance.get("content") as Lang.String;
                    // System.println("HomeAssistantApp glanceTemplate() " + mGlanceTemplate);
                } else { // if glance.get("type").equals("status")
                    mGlanceTemplate = null;
                }
            }
        }
    }

    //! Callback function for each menu update GET request.
    //!
    //! @param responseCode Response code.
    //! @param data         Response data.
    //
    function onReturnUpdateMenuItems(
        responseCode as Lang.Number,
        data         as Null or Lang.Dictionary
    ) as Void {
        // System.println("HomeAssistantApp onReturnUpdateMenuItems() Response Code: " + responseCode);
        // System.println("HomeAssistantApp onReturnUpdateMenuItems() Response Data: " + data);

        var status = WatchUi.loadResource($.Rez.Strings.Unavailable) as Lang.String;
        switch (responseCode) {
            case Communications.BLE_HOST_TIMEOUT:
            case Communications.BLE_CONNECTION_UNAVAILABLE:
                // System.println("HomeAssistantApp onReturnUpdateMenuItems() Response Code: BLE_HOST_TIMEOUT or BLE_CONNECTION_UNAVAILABLE, Bluetooth connection severed.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String);
                break;

            case Communications.BLE_QUEUE_FULL:
                // System.println("HomeAssistantApp onReturnUpdateMenuItems() Response Code: BLE_QUEUE_FULL, API calls too rapid.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.ApiFlood) as Lang.String);
                break;

            case Communications.NETWORK_REQUEST_TIMED_OUT:
                // System.println("HomeAssistantApp onReturnUpdateMenuItems() Response Code: NETWORK_REQUEST_TIMED_OUT, check Internet connection.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoResponse) as Lang.String);
                break;

            case Communications.INVALID_HTTP_BODY_IN_NETWORK_RESPONSE:
                // System.println("HomeAssistantApp onReturnUpdateMenuItems() Response Code: INVALID_HTTP_BODY_IN_NETWORK_RESPONSE, check JSON is returned.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoJson) as Lang.String);
                break;

            case Communications.NETWORK_RESPONSE_OUT_OF_MEMORY:
                // System.println("HomeAssistantApp onReturnUpdateMenuItems() Response Code: NETWORK_RESPONSE_OUT_OF_MEMORY, are we going too fast?");
                var myTimer = new Timer.Timer();
                // Now this feels very "closely coupled" to the application, but it is the most reliable method instead of using a timer.
                myTimer.start(method(:updateMenuItems), Globals.scApiBackoff, false);
                // Revert status
                status = getApiStatus();
                break;

            case 404:
                // System.println("HomeAssistantApp onReturnUpdateMenuItems() Response Code: 404, page not found. Check API URL setting.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.ApiUrlNotFound) as Lang.String);
                break;

            case 400:
                // System.println("HomeAssistantApp onReturnUpdateMenuItems() Response Code: 400, bad request. Template error.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.TemplateError) as Lang.String);
                break;

            case 200:
                status = WatchUi.loadResource($.Rez.Strings.Available) as Lang.String;
                // System.println("mItemsToUpdate: " + mItemsToUpdate);
                if (mItemsToUpdate != null) {
                    for (var i = 0; i < mItemsToUpdate.size(); i++) {
                        var item = mItemsToUpdate[i];
                        var state = data.get(i.toString());
                        item.updateState(state);
                        if (item instanceof HomeAssistantToggleMenuItem) {
                            (item as HomeAssistantToggleMenuItem).updateToggleState(data.get(i.toString() + "t"));
                        }
                    }
                    var delay = Settings.getPollDelay();
                    if (delay > 0) {
                        mUpdateTimer.start(method(:updateMenuItems), delay, false);
                    } else {
                        updateMenuItems();
                    }
                }
                break;

            default:
                // System.println("HomeAssistantApp onReturnUpdateMenuItems(): Unhandled HTTP response code = " + responseCode);
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.UnhandledHttpErr) as Lang.String + responseCode);
        }
        setApiStatus(status);
    }

    //! Construct the GET request to update all menu items.
    //
    function updateMenuItems() as Void {
        var phoneConnected = System.getDeviceSettings().phoneConnected;
        var connectionAvailable = System.getDeviceSettings().connectionAvailable;

        // In Wi-Fi/LTE execution mode, we should not show an error page but use a toast instead.
        if (Settings.getWifiLteExecutionEnabled() && (! phoneConnected || ! connectionAvailable)) {
            // Notify only once per disconnection cycle
            if (!mNotifiedNoBle) {
                var toast = WatchUi.loadResource($.Rez.Strings.NoPhone);
                if (!connectionAvailable) {
                    toast = WatchUi.loadResource($.Rez.Strings.NoInternet);
                }

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

            mNotifiedNoBle = true;
            setApiStatus(WatchUi.loadResource($.Rez.Strings.Unavailable) as Lang.String);
            mUpdateTimer.start(method(:startUpdates), wifiPollDelayMs, false);

            mUpdating = false;
            return;
        }

        if (! phoneConnected) {
            // System.println("HomeAssistantApp updateMenuItems(): No Phone connection, skipping API call.");
            ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String);
            setApiStatus(WatchUi.loadResource($.Rez.Strings.Unavailable) as Lang.String);
        } else if (! connectionAvailable) {
            // System.println("HomeAssistantApp updateMenuItems(): No Internet connection, skipping API call.");
            ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoInternet) as Lang.String);
            setApiStatus(WatchUi.loadResource($.Rez.Strings.Unavailable) as Lang.String);
        } else {
            mNotifiedNoBle = false;

            if (mItemsToUpdate == null or mTemplates == null) {
                mItemsToUpdate = mHaMenu.getItemsToUpdate();
                mTemplates = {};
                for (var i = 0; i < mItemsToUpdate.size(); i++) {
                    var item = mItemsToUpdate[i];
                    var template = item.getTemplate();
                    if (template != null) {
                        mTemplates.put(i.toString(), {
                            "template" => template
                        });
                    }
                   if (item instanceof HomeAssistantToggleMenuItem) {
                       mTemplates.put(i.toString() + "t", {
                           "template" => (item as HomeAssistantToggleMenuItem).getToggleTemplate()
                       });
                   }
                }
            }
            // https://developers.home-assistant.io/docs/api/native-app-integration/sending-data/#render-templates
            // System.println("HomeAssistantApp updateMenuItems() URL=" + url + ", Template='" + mTemplate + "'");
            Communications.makeWebRequest(
                Settings.getApiUrl() + "/webhook/" + Settings.getWebhookId(),
                {
                    "type" => "render_template",
                    "data" => mTemplates
                },
                {
                    :method       => Communications.HTTP_REQUEST_METHOD_POST,
                    :headers      => {
                        "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
                    },
                    :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
                },
                method(:onReturnUpdateMenuItems)
            );
        }
    }

    //! Callback function after completing the GET request to fetch the API status.
    //!
    //! @param responseCode Response code.
    //! @param data         Response data.
    //
    (:glance)
    function onReturnFetchApiStatus(
        responseCode as Lang.Number,
        data         as Null or Lang.Dictionary or Lang.String
    ) as Void {
        // System.println("HomeAssistantApp onReturnFetchApiStatus() Response Code: " + responseCode);
        // System.println("HomeAssistantApp onReturnFetchApiStatus() Response Data: " + data);

        mApiStatus = WatchUi.loadResource($.Rez.Strings.Unavailable) as Lang.String;
        switch (responseCode) {
            case Communications.BLE_HOST_TIMEOUT:
            case Communications.BLE_CONNECTION_UNAVAILABLE:
                // System.println("HomeAssistantApp onReturnFetchApiStatus() Response Code: BLE_HOST_TIMEOUT or BLE_CONNECTION_UNAVAILABLE, Bluetooth connection severed.");
                if (!mIsGlance) {
                    ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String);
                }
                break;

            case Communications.BLE_QUEUE_FULL:
                // System.println("HomeAssistantApp onReturnFetchApiStatus() Response Code: BLE_QUEUE_FULL, API calls too rapid.");
                if (!mIsGlance) {
                    ErrorView.show(WatchUi.loadResource($.Rez.Strings.ApiFlood) as Lang.String);
                }
                break;

            case Communications.NETWORK_REQUEST_TIMED_OUT:
                // System.println("HomeAssistantApp onReturnFetchApiStatus() Response Code: NETWORK_REQUEST_TIMED_OUT, check Internet connection.");
                if (!mIsGlance) {
                    ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoResponse) as Lang.String);
                }
                break;

            case Communications.INVALID_HTTP_BODY_IN_NETWORK_RESPONSE:
                // System.println("HomeAssistantApp onReturnFetchApiStatus() Response Code: INVALID_HTTP_BODY_IN_NETWORK_RESPONSE, check JSON is returned.");
                if (!mIsGlance) {
                    ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoJson) as Lang.String);
                }
                break;

            case 404:
                // System.println("HomeAssistantApp onReturnFetchApiStatus() Response Code: 404, page not found. Check Configuration URL setting.");
                if (!mIsGlance) {
                    ErrorView.show(WatchUi.loadResource($.Rez.Strings.ConfigUrlNotFound) as Lang.String);
                }
                break;

            case 200:
                if ((data != null) && data.get("message").equals("API running.")) {
                    mApiStatus = WatchUi.loadResource($.Rez.Strings.Available) as Lang.String;
                } else {
                    if (!mIsGlance) {
                        ErrorView.show("API " + mApiStatus + ".");
                    }
                }
                break;

            default:
                // System.println("HomeAssistantApp onReturnFetchApiStatus(): Unhandled HTTP response code = " + responseCode);
                if (!mIsGlance) {
                    ErrorView.show(WatchUi.loadResource($.Rez.Strings.UnhandledHttpErr) as Lang.String + responseCode);
                }
        }
        WatchUi.requestUpdate();
    }

    //! Construct the GET request to test the API status, is it accessible?
    //
    (:glance)
    function fetchApiStatus() as Void {
        var phoneConnected = System.getDeviceSettings().phoneConnected;
        var connectionAvailable = System.getDeviceSettings().connectionAvailable;

        // System.println("API URL = " + Settings.getApiUrl());
        if (Settings.getApiUrl().equals("")) {
            mApiStatus = WatchUi.loadResource($.Rez.Strings.Unconfigured) as Lang.String;
            WatchUi.requestUpdate();
        } else {
            if (! mIsGlance && Settings.getWifiLteExecutionEnabled() && (! phoneConnected || ! connectionAvailable)) {
                // System.println("HomeAssistantApp fetchApiStatus(): In-app Wifi mode (No Phone and Internet connection), early return.");
                return;
            } else if (! phoneConnected) {
                // System.println("HomeAssistantApp fetchApiStatus(): No Phone connection, skipping API call.");
                mApiStatus = WatchUi.loadResource($.Rez.Strings.Unavailable) as Lang.String;
                if (mIsGlance) {
                    WatchUi.requestUpdate();
                } else {
                    System.println("we here");
                    ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String);
                }
            } else if (! connectionAvailable) {
                // System.println("HomeAssistantApp fetchApiStatus(): No Internet connection, skipping API call.");
                mApiStatus = WatchUi.loadResource($.Rez.Strings.Unavailable) as Lang.String;
                if (mIsGlance) {
                    WatchUi.requestUpdate();
                } else {
                    ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoInternet) as Lang.String);
                }
            } else {
                Communications.makeWebRequest(
                    Settings.getApiUrl() + "/",
                    null,
                    {
                        :method       => Communications.HTTP_REQUEST_METHOD_GET,
                        :headers      => {
                            "Authorization" => "Bearer " + Settings.getApiKey()
                        },
                        :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
                    },
                    method(:onReturnFetchApiStatus)
                );
            }
        }
    }


    //! Callback function after completing the GET request to render the glance template.
    //!
    //! @param responseCode Response code.
    //! @param data         Response data.
    //
    (:glance)
    function onReturnFetchGlanceContent(
        responseCode as Lang.Number,
        data         as Null or Lang.Dictionary or Lang.String
    ) as Void {
        // System.println("HomeAssistantApp onReturnFetchGlanceContent() Response Code: " + responseCode);
        // System.println("HomeAssistantApp onReturnFetchGlanceContent() Response Data: " + data);

        switch (responseCode) {
            case Communications.BLE_HOST_TIMEOUT:
            case Communications.BLE_CONNECTION_UNAVAILABLE:
                // System.println("HomeAssistantApp onReturnFetchGlanceContent() Response Code: BLE_HOST_TIMEOUT or BLE_CONNECTION_UNAVAILABLE, Bluetooth connection severed.");
                if (!mIsGlance) {
                    ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String);
                }
                break;

            case Communications.BLE_QUEUE_FULL:
                // System.println("HomeAssistantApp onReturnFetchGlanceContent() Response Code: BLE_QUEUE_FULL, API calls too rapid.");
                if (!mIsGlance) {
                    ErrorView.show(WatchUi.loadResource($.Rez.Strings.ApiFlood) as Lang.String);
                }
                break;

            case Communications.NETWORK_REQUEST_TIMED_OUT:
                // System.println("HomeAssistantApp onReturnFetchGlanceContent() Response Code: NETWORK_REQUEST_TIMED_OUT, check Internet connection.");
                if (!mIsGlance) {
                    ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoResponse) as Lang.String);
                }
                break;

            case Communications.INVALID_HTTP_BODY_IN_NETWORK_RESPONSE:
                // System.println("HomeAssistantApp onReturnFetchGlanceContent() Response Code: INVALID_HTTP_BODY_IN_NETWORK_RESPONSE, check JSON is returned.");
                if (!mIsGlance) {
                    ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoJson) as Lang.String);
                }
                break;

            case 404:
                // System.println("HomeAssistantApp onReturnFetchGlanceContent() Response Code: 404, page not found. Check Configuration URL setting.");
                if (!mIsGlance) {
                    ErrorView.show(WatchUi.loadResource($.Rez.Strings.ConfigUrlNotFound) as Lang.String);
                }
                break;

            case 200:
                if (data != null) {
                    mGlanceText = data.get("glanceTemplate");
                }
                break;

            default:
                // System.println("HomeAssistantApp onReturnFetchGlanceContent(): Unhandled HTTP response code = " + responseCode);
                if (!mIsGlance) {
                    ErrorView.show(WatchUi.loadResource($.Rez.Strings.UnhandledHttpErr) as Lang.String + responseCode);
                }
        }
        WatchUi.requestUpdate();
    }

    //! Construct the GET request to convert the optional glance template to text for display.
    //
    (:glance)
    function fetchGlanceContent() as Void {
        if (mGlanceTemplate != null) {
            // https://developers.home-assistant.io/docs/api/native-app-integration/sending-data/#render-templates
            Communications.makeWebRequest(
                Settings.getApiUrl() + "/webhook/" + Settings.getWebhookId(),
                {
                    "type" => "render_template",
                    "data" => {
                        "glanceTemplate" => {
                            "template" => mGlanceTemplate
                        }
                    }
                },
                {
                    :method       => Communications.HTTP_REQUEST_METHOD_POST,
                    :headers      => {
                        "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
                    },
                    :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
                },
                method(:onReturnFetchGlanceContent)
            );
        }
    }

    //! Record the API status result.
    //!
    //! @param s A string describing the API status
    //
    function setApiStatus(s as Lang.String) {
        mApiStatus = s;
    }

    //! Return the API status result.
    //!
    //! @return A string describing the API status
    //
    (:glance)
    function getApiStatus() as Lang.String {
        return mApiStatus;
    }

    //! Return the Menu status result.
    //!
    //! @return A string describing the Menu status
    //
    (:glance)
    function getMenuStatus() as Lang.String {
        return mMenuStatus;
    }

    //! Return the optional glance text that overrides the default glance content. This
    //! is derived from the glance template.
    //!
    //! @return A string derived from the glance template
    //
    (:glance)
    function getGlanceText() as Lang.String or Null {
        return mGlanceText;
    }

    //! Return the Menu construction status.
    //!
    //! @return A Boolean indicating if the menu is loaded into the application.
    //
    function isHomeAssistantMenuLoaded() as Lang.Boolean {
        return mHaMenu != null;
    }

    //! Make the menu visible on the watch face.
    //
    function pushHomeAssistantMenuView() as Void {
        WatchUi.pushView(mHaMenu, new HomeAssistantViewDelegate(true), WatchUi.SLIDE_IMMEDIATE);
    }

    //! Force status updates. Only take action if `Settings.getPollDelay() > 0`. This must be tested
    //! locally as it is then efficient to take alternative action if the test fails.
    //
    function forceStatusUpdates() as Void {
        // Don't mess with updates unless we are using a timer.
        if (Settings.getPollDelay() > 0) {
            mUpdateTimer.stop();
            // For immediate updates
            updateMenuItems();
        }
    }

    //! Return the timer used to quit the application.
    //!
    //! @return Timer object
    //
    function getQuitTimer() as QuitTimer {
        return mQuitTimer;
    }

    //! Return the glance view.
    //!
    //! @return The glance view
    //
    function getGlanceView() as [ WatchUi.GlanceView ] or [ WatchUi.GlanceView, WatchUi.GlanceViewDelegate ] or Null {
        mIsGlance   = true;
        mApiStatus  = WatchUi.loadResource($.Rez.Strings.Checking) as Lang.String;
        mMenuStatus = WatchUi.loadResource($.Rez.Strings.Checking) as Lang.String;
        Settings.update();
        updateStatus();
        mGlanceTimer = new Timer.Timer();
        mGlanceTimer.start(method(:updateStatus), Globals.scApiBackoff, true);
        return [new HomeAssistantGlanceView(self)];
    }

    //! Return the glance theme.
    //!
    //! @return The glance colour
    //
    function getGlanceTheme() as Application.AppBase.GlanceTheme {
        return Application.AppBase.GLANCE_THEME_LIGHT_BLUE;
    }

    //! Update the menu and API statuses. Required for the Glance update timer.
    //
    function updateStatus() as Void {
        mGlanceTimer = null;
        fetchMenuConfig();
        fetchApiStatus();
        fetchGlanceContent();
    }

    //! Code for when the application settings are updated.
    //
    function onSettingsChanged() as Void {
        // System.println("HomeAssistantApp onSettingsChanged()");
        Settings.update();
    }

    //! Called each time the Registered Temporal Event is to be invoked. So the object is created each time
    //! on request and then destroyed on completion (to save resources).
    //
    function getServiceDelegate() as [ System.ServiceDelegate ] {
        return [new BackgroundServiceDelegate()];
    }

    //! Determine is we are a glance or the full application. Glances should be considered to be separate applications.
    //
    function getIsApp() as Lang.Boolean {
        return mIsApp;
    }

    //! Returns a SyncDelegate for this App
    //!
    //! @return a SyncDelegate or null
    //
    public function getSyncDelegate() as Communications.SyncDelegate? {
        return new HomeAssistantSyncDelegate();
    }
}

//! Global function to return the application object.
//
(:glance, :background)
function getApp() as HomeAssistantApp {
    return Application.getApp() as HomeAssistantApp;
}
