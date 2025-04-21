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
//
// Description:
//
// Application root for GarminHomeAssistant
//
//-----------------------------------------------------------------------------------

using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.System;
using Toybox.Application.Properties;
using Toybox.Timer;

(:glance, :background)
class HomeAssistantApp extends Application.AppBase {
    private var mApiStatus     as Lang.String       or Null;
    private var mMenuStatus    as Lang.String       or Null;
    private var mHaMenu        as HomeAssistantView or Null;
    private var mQuitTimer     as QuitTimer         or Null;
    private var mGlanceTimer   as Timer.Timer       or Null;
    private var mUpdateTimer   as Timer.Timer       or Null;
    // Array initialised by onReturnFetchMenuConfig()
    private var mItemsToUpdate as Lang.Array<HomeAssistantToggleMenuItem or HomeAssistantTapMenuItem or HomeAssistantGroupMenuItem> or Null;
    private var mIsGlance      as Lang.Boolean    = false;
    private var mIsApp         as Lang.Boolean    = false; // Or Widget
    private var mUpdating      as Lang.Boolean    = false; // Don't start a second chain of updates
    private var mTemplates     as Lang.Dictionary = {};

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

    // onStart() is called on application start up
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

    // onStop() is called when your application is exiting
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

    // Return the initial view of your application here
    function getInitialView() as [ WatchUi.Views ] or [ WatchUi.Views, WatchUi.InputDelegates ] {
        mIsApp       = true;
        mQuitTimer   = new QuitTimer();
        mUpdateTimer = new Timer.Timer();
        mApiStatus   = WatchUi.loadResource($.Rez.Strings.Checking) as Lang.String;
        mMenuStatus  = WatchUi.loadResource($.Rez.Strings.Checking) as Lang.String;
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
        } else if (! System.getDeviceSettings().phoneConnected) {
            // System.println("HomeAssistantApp getInitialView(): No Phone connection, skipping API call.");
            return ErrorView.create(WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String);
        } else if (! System.getDeviceSettings().connectionAvailable) {
            // System.println("HomeAssistantApp getInitialView(): No Internet connection, skipping API call.");
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

    // Callback function after completing the GET request to fetch the configuration menu.
    //
    (:glance)
    function onReturnFetchMenuConfig(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
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
                if (!mIsGlance) {
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

    // Return true if the menu came from the cache, otherwise false. This is because fetching the menu when not in the cache is
    // asynchronous and affects how the views are managed.
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
                if (! System.getDeviceSettings().phoneConnected) {
                    // System.println("HomeAssistantApp fetchMenuConfig(): No Phone connection, skipping API call.");
                    if (mIsGlance) {
                        WatchUi.requestUpdate();
                    } else {
                        ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String);
                    }
                    mMenuStatus = WatchUi.loadResource($.Rez.Strings.Unavailable) as Lang.String;
                } else if (! System.getDeviceSettings().connectionAvailable) {
                    // System.println("HomeAssistantApp fetchMenuConfig(): No Internet connection, skipping API call.");
                    if (mIsGlance) {
                        WatchUi.requestUpdate();
                    } else {
                        ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoInternet) as Lang.String);
                    }
                    mMenuStatus = WatchUi.loadResource($.Rez.Strings.Unavailable) as Lang.String;
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
                if (!mIsGlance) {
                    buildMenu(menu);
                }
                return true;
            }
        }
        return false;
    }

    private function buildMenu(menu as Lang.Dictionary) {
        mHaMenu = new HomeAssistantView(menu, null);
        mQuitTimer.begin();
        if (!Settings.getWebhookId().equals("")) {
            startUpdates();
        } // If not, this will be done via a chain in Settings.webhook() and mWebhookManager.requestWebhookId() that registers the sensors.
    }

    function startUpdates() {
        if (mHaMenu != null and !mUpdating) {
            // Start the continuous update process that continues for as long as the application is running.
            updateMenuItems();
            mUpdating = true;
        }
    }

    function onReturnUpdateMenuItems(responseCode as Lang.Number, data as Null or Lang.Dictionary) as Void {
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

    function updateMenuItems() as Void {
        if (! System.getDeviceSettings().phoneConnected) {
            // System.println("HomeAssistantApp updateMenuItems(): No Phone connection, skipping API call.");
            ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String);
            setApiStatus(WatchUi.loadResource($.Rez.Strings.Unavailable) as Lang.String);
        } else if (! System.getDeviceSettings().connectionAvailable) {
            // System.println("HomeAssistantApp updateMenuItems(): No Internet connection, skipping API call.");
            ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoInternet) as Lang.String);
            setApiStatus(WatchUi.loadResource($.Rez.Strings.Unavailable) as Lang.String);
        } else {
            if (mItemsToUpdate == null or mTemplates == null) {
                mItemsToUpdate = mHaMenu.getItemsToUpdate();
                mTemplates = {};
                for (var i = 0; i < mItemsToUpdate.size(); i++) {
                    var item = mItemsToUpdate[i];
                    var template = item.buildTemplate();
                    if (template != null) {
                        mTemplates.put(i.toString(), {
                            "template" => template
                        });
                    }
                    if (item instanceof HomeAssistantToggleMenuItem) {
                        mTemplates.put(i.toString() + "t", {
                            "template" => (item as HomeAssistantToggleMenuItem).buildToggleTemplate()
                        });
                    }
                }
            }
            // https://developers.home-assistant.io/docs/api/native-app-integration/sending-data/#render-templates
            var url = Settings.getApiUrl() + "/webhook/" + Settings.getWebhookId();
            // System.println("HomeAssistantApp updateMenuItems() URL=" + url + ", Template='" + mTemplate + "'");
            Communications.makeWebRequest(
                url,
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

    // Callback function after completing the GET request to fetch the API status.
    //
    (:glance)
    function onReturnFetchApiStatus(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
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

    (:glance)
    function fetchApiStatus() as Void {
        // System.println("API URL = " + Settings.getApiUrl());
        if (Settings.getApiUrl().equals("")) {
            mApiStatus = WatchUi.loadResource($.Rez.Strings.Unconfigured) as Lang.String;
            WatchUi.requestUpdate();
        } else {
            if (! System.getDeviceSettings().phoneConnected) {
                // System.println("HomeAssistantApp fetchApiStatus(): No Phone connection, skipping API call.");
                mApiStatus = WatchUi.loadResource($.Rez.Strings.Unavailable) as Lang.String;
                if (mIsGlance) {
                    WatchUi.requestUpdate();
                } else {
                    ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String);
                }
            } else if (! System.getDeviceSettings().connectionAvailable) {
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

    function setApiStatus(s as Lang.String) {
        mApiStatus = s;
    }

    (:glance)
    function getApiStatus() as Lang.String {
        return mApiStatus;
    }

    (:glance)
    function getMenuStatus() as Lang.String {
        return mMenuStatus;
    }

    function isHomeAssistantMenuLoaded() as Lang.Boolean {
        return mHaMenu != null;
    }

    function pushHomeAssistantMenuView() as Void {
        WatchUi.pushView(mHaMenu, new HomeAssistantViewDelegate(true), WatchUi.SLIDE_IMMEDIATE);
    }

    // Only call this function if Settings.getPollDelay() > 0. This must be tested locally as it is then efficient to take
    // alternative action if the test fails.
    function forceStatusUpdates() as Void {
        // Don't mess with updates unless we are using a timer.
        if (Settings.getPollDelay() > 0) {
            mUpdateTimer.stop();
            // For immediate updates
            updateMenuItems();
        }
    }

    function getQuitTimer() as QuitTimer {
        return mQuitTimer;
    }

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

    // Required for the Glance update timer.
    function updateStatus() as Void {
        mGlanceTimer = null;
        fetchMenuConfig();
        fetchApiStatus();
    }

    function onSettingsChanged() as Void {
        // System.println("HomeAssistantApp onSettingsChanged()");
        Settings.update();
    }

    // Called each time the Registered Temporal Event is to be invoked. So the object is created each time on request and
    // then destroyed on completion (to save resources).
    function getServiceDelegate() as [ System.ServiceDelegate ] {
        return [new BackgroundServiceDelegate()];
    }

    function getIsApp() as Lang.Boolean {
        return mIsApp;
    }

}

(:glance, :background)
function getApp() as HomeAssistantApp {
    return Application.getApp() as HomeAssistantApp;
}
