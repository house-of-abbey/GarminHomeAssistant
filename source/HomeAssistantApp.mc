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
    private var mApiStatus         as Lang.String       or Null;
    private var mMenuStatus        as Lang.String       or Null;
    private var mHaMenu            as HomeAssistantView or Null;
    private var mQuitTimer         as QuitTimer         or Null;
    private var mGlanceTimer       as Timer.Timer       or Null;
    private var mUpdateTimer       as Timer.Timer       or Null;
    // Array initialised by onReturnFetchMenuConfig()
    private var mItemsToUpdate     as Lang.Array<HomeAssistantToggleMenuItem or HomeAssistantTemplateMenuItem> or Null;
    private var mNextItemToUpdate  as Lang.Number  = 0;     // Index into the above array
    private var mIsGlance          as Lang.Boolean = false;
    private var mIsApp             as Lang.Boolean = false; // Or Widget
    private var mIsInitUpdateCompl as Lang.Boolean = false;

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
    function getInitialView() as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>? {
        mIsApp       = true;
        mQuitTimer   = new QuitTimer();
        mUpdateTimer = new Timer.Timer();
        mApiStatus   = WatchUi.loadResource($.Rez.Strings.Checking) as Lang.String;
        mMenuStatus  = WatchUi.loadResource($.Rez.Strings.Checking) as Lang.String;
        Settings.update();

        if (Settings.getApiKey().length() == 0) {
            // System.println("HomeAssistantApp getInitialView(): No API key in the application Settings.");
            return ErrorView.create(WatchUi.loadResource($.Rez.Strings.NoAPIKey) as Lang.String + ".");
        } else if (Settings.getApiUrl().length() == 0) {
            // System.println("HomeAssistantApp getInitialView(): No API URL in the application Settings.");
            return ErrorView.create(WatchUi.loadResource($.Rez.Strings.NoApiUrl) as Lang.String + ".");
        } else if (Settings.getApiUrl().substring(-1, Settings.getApiUrl().length()).equals("/")) {
            // System.println("HomeAssistantApp getInitialView(): API URL must not have a trailing slash '/'.");
            return ErrorView.create(WatchUi.loadResource($.Rez.Strings.TrailingSlashErr) as Lang.String + ".");
        } else if (Settings.getConfigUrl().length() == 0) {
            // System.println("HomeAssistantApp getInitialView(): No configuration URL in the application settings.");
            return ErrorView.create(WatchUi.loadResource($.Rez.Strings.NoConfigUrl) as Lang.String + ".");
        } else if (! System.getDeviceSettings().phoneConnected) {
            // System.println("HomeAssistantApp getInitialView(): No Phone connection, skipping API call.");
            return ErrorView.create(WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String + ".");
        } else if (! System.getDeviceSettings().connectionAvailable) {
            // System.println("HomeAssistantApp getInitialView(): No Internet connection, skipping API call.");
            return ErrorView.create(WatchUi.loadResource($.Rez.Strings.NoInternet) as Lang.String + ".");
        } else {
            var isCached = fetchMenuConfig();
            fetchApiStatus();
            if (isCached) {
                return [mHaMenu, new HomeAssistantViewDelegate(true)] as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>;
            } else {
                return [new WatchUi.View(), new WatchUi.BehaviorDelegate()] as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>;
            }
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
                    ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String + ".");
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
        // System.println("URL = " + Settings.getConfigUrl());
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
                        ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String + ".");
                    }
                    mMenuStatus = WatchUi.loadResource($.Rez.Strings.Unavailable) as Lang.String;
                } else if (! System.getDeviceSettings().connectionAvailable) {
                    // System.println("HomeAssistantApp fetchMenuConfig(): No Internet connection, skipping API call.");
                    if (mIsGlance) {
                        WatchUi.requestUpdate();
                    } else {
                        ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoInternet) as Lang.String + ".");
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
    }

    function startUpdates() {
        if (mHaMenu != null) {
            mItemsToUpdate = mHaMenu.getItemsToUpdate();
            // Start the continuous update process that continues for as long as the application is running.
            // The chain of functions from 'updateNextMenuItem()' calls 'updateNextMenuItem()' on completion.
            if (mItemsToUpdate.size() > 0) {
                updateNextMenuItemInternal();
            }
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
                    ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String + ".");
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
                var msg = null;
                if (data != null) {
                    msg = data.get("message");
                }
                if (msg.equals("API running.")) {
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
                    ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String + ".");
                }
            } else if (! System.getDeviceSettings().connectionAvailable) {
                // System.println("HomeAssistantApp fetchApiStatus(): No Internet connection, skipping API call.");
                mApiStatus = WatchUi.loadResource($.Rez.Strings.Unavailable) as Lang.String;
                if (mIsGlance) {
                    WatchUi.requestUpdate();
                } else {
                    ErrorView.show(WatchUi.loadResource($.Rez.Strings.NoInternet) as Lang.String + ".");
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

    function updateNextMenuItem() as Void {
        var delay = Settings.getPollDelay();
        if (mIsInitUpdateCompl and (delay > 0) and (mNextItemToUpdate == 0)) {
            mUpdateTimer.start(method(:updateNextMenuItemInternal), delay, false);
        } else {
            updateNextMenuItemInternal();
        }
    }

    // Only call this function if Settings.getPollDelay() > 0. This must be tested locally as it is then efficient to take
    // alternative action if the test fails.
    function forceStatusUpdates() as Void {
        // Don't mess with updates unless we are using a timer.
        if (Settings.getPollDelay() > 0) {
            mUpdateTimer.stop();
            mIsInitUpdateCompl = false;
            // Start from the beginning, or we will only get a partial round of updates before mIsInitUpdateCompl is flipped.
            mNextItemToUpdate = 0;
            // For immediate updates
            updateNextMenuItem();
        }
    }

    // We need to spread out the API calls so as not to overload the results queue and cause Communications.BLE_QUEUE_FULL
    // (-101) error. This function is called by a timer every Globals.menuItemUpdateInterval ms.
    function updateNextMenuItemInternal() as Void {
        var itu = mItemsToUpdate as Lang.Array<HomeAssistantToggleMenuItem>;
        if (itu != null) {
            // System.println("HomeAssistantApp updateNextMenuItemInternal(): Doing update for item " + mNextItemToUpdate + ", mIsInitUpdateCompl=" + mIsInitUpdateCompl);
            itu[mNextItemToUpdate].getState();
            // mNextItemToUpdate = (mNextItemToUpdate + 1) % itu.size() - But with roll-over detection
            if (mNextItemToUpdate == itu.size()-1) {
                // Last item completed return to the start of the list
                mNextItemToUpdate  = 0;
                mIsInitUpdateCompl = true;
            } else {
                mNextItemToUpdate++;
            }
        // } else {
        //     System.println("HomeAssistantApp updateNextMenuItemInternal(): No menu items to update");
        }
    }

    function getQuitTimer() as QuitTimer {
        return mQuitTimer;
    }

    function getGlanceView() as Lang.Array<WatchUi.GlanceView or WatchUi.GlanceViewDelegate> or Null {
        mIsGlance   = true;
        mApiStatus  = WatchUi.loadResource($.Rez.Strings.Checking) as Lang.String;
        mMenuStatus = WatchUi.loadResource($.Rez.Strings.Checking) as Lang.String;
        updateStatus();
        Settings.update();
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
    function getServiceDelegate() as Lang.Array<System.ServiceDelegate> {
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
