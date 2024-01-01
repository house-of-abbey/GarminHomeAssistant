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
    private var mApiStatus           as Lang.String       or Null;
    private var mMenuStatus          as Lang.String       or Null;
    private var mHaMenu              as HomeAssistantView or Null;
    private var mQuitTimer           as QuitTimer         or Null;
    private var mTimer               as Timer.Timer       or Null;
    private var mItemsToUpdate       as Lang.Array<HomeAssistantToggleMenuItem> or Null; // Array initialised by onReturnFetchMenuConfig()
    private var mNextItemToUpdate    as Lang.Number  = 0;                                // Index into the above array
    private var mIsGlance            as Lang.Boolean = false;
    private var mIsApp               as Lang.Boolean = false; // Or Widget

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
        mIsApp               = true;
        mQuitTimer           = new QuitTimer();
        RezStrings.update();
        mApiStatus  = RezStrings.getChecking();
        mMenuStatus = RezStrings.getChecking();
        Settings.update();

        if (Settings.getApiKey().length() == 0) {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp getInitialView(): No API key in the application Settings.");
            }
            return ErrorView.create(RezStrings.getNoApiKey() + ".");
        } else if (Settings.getApiUrl().length() == 0) {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp getInitialView(): No API URL in the application Settings.");
            }
            return ErrorView.create(RezStrings.getNoApiUrl() + ".");
        } else if (Settings.getApiUrl().substring(-1, Settings.getApiUrl().length()).equals("/")) {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp getInitialView(): API URL must not have a trailing slash '/'.");
            }
            return ErrorView.create(RezStrings.getTrailingSlashErr() + ".");
        } else if (Settings.getConfigUrl().length() == 0) {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp getInitialView(): No configuration URL in the application settings.");
            }
            return ErrorView.create(RezStrings.getNoConfigUrl() + ".");
        } else if (! System.getDeviceSettings().phoneConnected) {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp fetchMenuConfig(): No Phone connection, skipping API call.");
            }
            return ErrorView.create(RezStrings.getNoPhone() + ".");
        } else if (! System.getDeviceSettings().connectionAvailable) {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp fetchMenuConfig(): No Internet connection, skipping API call.");
            }
            return ErrorView.create(RezStrings.getNoInternet() + ".");
        } else {
            fetchMenuConfig();
            fetchApiStatus();
            if (WidgetApp.isWidget) {
                return [new RootView(self), new RootViewDelegate(self)] as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>;
            } else {
                return [new WatchUi.View(), new WatchUi.BehaviorDelegate()] as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>;
            }
        }
    }

    // Callback function after completing the GET request to fetch the configuration menu.
    //
    (:glance)
    function onReturnFetchMenuConfig(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        if (Globals.scDebug) {
            System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Code: " + responseCode);
            System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Data: " + data);
        }

        mMenuStatus = RezStrings.getUnavailable();
        switch (responseCode) {
            case Communications.BLE_HOST_TIMEOUT:
            case Communications.BLE_CONNECTION_UNAVAILABLE:
                if (Globals.scDebug) {
                    System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Code: BLE_HOST_TIMEOUT or BLE_CONNECTION_UNAVAILABLE, Bluetooth connection severed.");
                }
                if (!mIsGlance) {
                    ErrorView.show(RezStrings.getNoPhone() + ".");
                }
                break;

            case Communications.BLE_QUEUE_FULL:
                if (Globals.scDebug) {
                    System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Code: BLE_QUEUE_FULL, API calls too rapid.");
                }
                if (!mIsGlance) {
                    ErrorView.show(RezStrings.getApiFlood());
                }
                break;

            case Communications.NETWORK_REQUEST_TIMED_OUT:
                if (Globals.scDebug) {
                    System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Code: NETWORK_REQUEST_TIMED_OUT, check Internet connection.");
                }
                if (!mIsGlance) {
                    ErrorView.show(RezStrings.getNoResponse());
                }
                break;

            case Communications.INVALID_HTTP_BODY_IN_NETWORK_RESPONSE:
                if (Globals.scDebug) {
                    System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Code: INVALID_HTTP_BODY_IN_NETWORK_RESPONSE, check JSON is returned.");
                }
                if (!mIsGlance) {
                    ErrorView.show(RezStrings.getNoJson());
                }
                break;

            case 404:
                if (Globals.scDebug) {
                    System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Code: 404, page not found. Check Configuration URL setting.");
                }
                if (!mIsGlance) {
                    ErrorView.show(RezStrings.getConfigUrlNotFound());
                }
                break;

            case 200:
                mMenuStatus = RezStrings.getAvailable();
                if (!mIsGlance) {
                    mHaMenu = new HomeAssistantView(data, null);
                    mQuitTimer.begin();
                    if (Settings.getIsWidgetStartNoTap()) {
                        // As soon as the menu has been fetched start show the menu of items.
                        // This behaviour is inconsistent with the standard Garmin User Interface, but has been
                        // requested by users so has been made the non-default option.
                        pushHomeAssistantMenuView();
                    }
                    mItemsToUpdate = mHaMenu.getItemsToUpdate();
                    // Start the continuous update process that continues for as long as the application is running.
                    // The chain of functions from 'updateNextMenuItem()' calls 'updateNextMenuItem()' on completion.
                    if (mItemsToUpdate.size() > 0) {
                        updateNextMenuItem();
                    }
                    if (!WidgetApp.isWidget) {
                        WatchUi.switchToView(mHaMenu, new HomeAssistantViewDelegate(false), WatchUi.SLIDE_IMMEDIATE);
                    }
                }
                break;

            default:
                if (Globals.scDebug) {
                    System.println("HomeAssistantApp onReturnFetchMenuConfig(): Unhandled HTTP response code = " + responseCode);
                }
                if (!mIsGlance) {
                    ErrorView.show(RezStrings.getUnhandledHttpErr() + responseCode);
                }
                break;
        }
        WatchUi.requestUpdate();
    }

    (:glance)
    function fetchMenuConfig() as Void {
        if (Settings.getConfigUrl().equals("")) {
            mMenuStatus = RezStrings.getUnconfigured();
            WatchUi.requestUpdate();
        } else {
            if (! System.getDeviceSettings().phoneConnected) {
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem getState(): No Phone connection, skipping API call.");
                }
                if (mIsGlance) {
                    WatchUi.requestUpdate();
                } else {
                    ErrorView.show(RezStrings.getNoPhone() + ".");
                }
                mMenuStatus = RezStrings.getUnavailable();
            } else if (! System.getDeviceSettings().connectionAvailable) {
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem getState(): No Internet connection, skipping API call.");
                }
                if (mIsGlance) {
                    WatchUi.requestUpdate();
                } else {
                    ErrorView.show(RezStrings.getNoInternet() + ".");
                }
                mMenuStatus = RezStrings.getUnavailable();
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
        }
    }

    // Callback function after completing the GET request to fetch the API status.
    //
    (:glance)
    function onReturnFetchApiStatus(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        if (Globals.scDebug) {
            System.println("HomeAssistantApp onReturnFetchApiStatus() Response Code: " + responseCode);
            System.println("HomeAssistantApp onReturnFetchApiStatus() Response Data: " + data);
        }

        mApiStatus = RezStrings.getUnavailable();
        switch (responseCode) {
            case Communications.BLE_HOST_TIMEOUT:
            case Communications.BLE_CONNECTION_UNAVAILABLE:
                if (Globals.scDebug) {
                    System.println("HomeAssistantApp onReturnFetchApiStatus() Response Code: BLE_HOST_TIMEOUT or BLE_CONNECTION_UNAVAILABLE, Bluetooth connection severed.");
                }
                if (!mIsGlance) {
                    ErrorView.show(RezStrings.getNoPhone() + ".");
                }
                break;

            case Communications.BLE_QUEUE_FULL:
                if (Globals.scDebug) {
                    System.println("HomeAssistantApp onReturnFetchApiStatus() Response Code: BLE_QUEUE_FULL, API calls too rapid.");
                }
                if (!mIsGlance) {
                    ErrorView.show(RezStrings.getApiFlood());
                }
                break;

            case Communications.NETWORK_REQUEST_TIMED_OUT:
                if (Globals.scDebug) {
                    System.println("HomeAssistantApp onReturnFetchApiStatus() Response Code: NETWORK_REQUEST_TIMED_OUT, check Internet connection.");
                }
                if (!mIsGlance) {
                    ErrorView.show(RezStrings.getNoResponse());
                }
                break;

            case Communications.INVALID_HTTP_BODY_IN_NETWORK_RESPONSE:
                if (Globals.scDebug) {
                    System.println("HomeAssistantApp onReturnFetchApiStatus() Response Code: INVALID_HTTP_BODY_IN_NETWORK_RESPONSE, check JSON is returned.");
                }
                if (!mIsGlance) {
                    ErrorView.show(RezStrings.getNoJson());
                }
                break;

            case 404:
                if (Globals.scDebug) {
                    System.println("HomeAssistantApp onReturnFetchApiStatus() Response Code: 404, page not found. Check Configuration URL setting.");
                }
                if (!mIsGlance) {
                    ErrorView.show(RezStrings.getConfigUrlNotFound());
                }
                break;

            case 200:
                var msg = null;
                if (data != null) {
                    msg = data.get("message");
                }
                if (msg.equals("API running.")) {
                    mApiStatus = RezStrings.getAvailable();
                } else {
                    if (!mIsGlance) {
                        ErrorView.show("API " + mApiStatus + ".");
                    }
                }
                break;

            default:
                if (Globals.scDebug) {
                    System.println("HomeAssistantApp onReturnFetchApiStatus(): Unhandled HTTP response code = " + responseCode);
                }
                if (!mIsGlance) {
                    ErrorView.show(RezStrings.getUnhandledHttpErr() + responseCode);
                }
        }
        WatchUi.requestUpdate();
    }

    (:glance)
    function fetchApiStatus() as Void {
        if (Settings.getApiUrl().equals("")) {
            mApiStatus = RezStrings.getUnconfigured();
            WatchUi.requestUpdate();
        } else {
            if (! System.getDeviceSettings().phoneConnected) {
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem getState(): No Phone connection, skipping API call.");
                }
                mApiStatus = RezStrings.getUnavailable();
                if (mIsGlance) {
                    WatchUi.requestUpdate();
                } else {
                    ErrorView.show(RezStrings.getNoPhone() + ".");
                }
            } else if (! System.getDeviceSettings().connectionAvailable) {
                if (Globals.scDebug) {
                    System.println("HomeAssistantToggleMenuItem getState(): No Internet connection, skipping API call.");
                }
                mApiStatus = RezStrings.getUnavailable();
                if (mIsGlance) {
                    WatchUi.requestUpdate();
                } else {
                    ErrorView.show(RezStrings.getNoInternet() + ".");
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

    // We need to spread out the API calls so as not to overload the results queue and cause Communications.BLE_QUEUE_FULL
    // (-101) error. This function is called by a timer every Globals.menuItemUpdateInterval ms.
    function updateNextMenuItem() as Void {
        var itu = mItemsToUpdate as Lang.Array<HomeAssistantToggleMenuItem>;
        if (itu == null) {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp updateNextMenuItem(): No menu items to update");
            }
            if (!mIsGlance) {
                ErrorView.show(RezStrings.getConfigUrlNotFound());
            }
        } else {
            itu[mNextItemToUpdate].getState();
            mNextItemToUpdate = (mNextItemToUpdate + 1) % itu.size();
        }
    }

    function getQuitTimer() as QuitTimer {
        return mQuitTimer;
    }

    function getGlanceView() as Lang.Array<WatchUi.GlanceView or WatchUi.GlanceViewDelegate> or Null {
        mIsGlance = true;
        RezStrings.update_glance();
        mApiStatus  = RezStrings.getChecking();
        mMenuStatus = RezStrings.getChecking();
        updateGlance();
        Settings.update();
        mTimer = new Timer.Timer();
        mTimer.start(method(:updateGlance), Globals.scApiBackoff, true);
        return [new HomeAssistantGlanceView(self)];
    }

    // Required for the Glance update timer.
    function updateGlance() as Void {
        fetchMenuConfig();
        fetchApiStatus();
    }

    // Replace this functionality with a more central settings class as proposed in
    // https://github.com/house-of-abbey/GarminHomeAssistant/pull/17.
    function onSettingsChanged() as Void {
        if (Globals.scDebug) {
            System.println("HomeAssistantApp onSettingsChanged()");
        }
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
