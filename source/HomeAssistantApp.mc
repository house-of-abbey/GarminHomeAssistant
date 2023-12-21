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
using Toybox.Application.Properties;

class HomeAssistantApp extends Application.AppBase {
    private var strNoApiKey          as Lang.String or Null;
    private var strNoApiUrl          as Lang.String or Null;
    private var strNoConfigUrl       as Lang.String or Null;
    private var strNoPhone           as Lang.String or Null;
    private var strNoInternet        as Lang.String or Null;
    private var strNoResponse        as Lang.String or Null;
    private var strApiFlood          as Lang.String or Null;
    private var strConfigUrlNotFound as Lang.String or Null;
    private var strNoJson            as Lang.String or Null;
    private var strUnhandledHttpErr  as Lang.String or Null;
    private var strTrailingSlashErr  as Lang.String or Null;
    private var strAvailable         = WatchUi.loadResource($.Rez.Strings.Available);
    private var strUnavailable       = WatchUi.loadResource($.Rez.Strings.Unavailable);

    private var mApiKey              as Lang.String;
    private var mApiStatus           as Lang.String = WatchUi.loadResource($.Rez.Strings.Checking);
    private var mMenuStatus          as Lang.String = WatchUi.loadResource($.Rez.Strings.Checking);
    private var mHaMenu              as HomeAssistantView or Null;
    private var mQuitTimer           as QuitTimer or Null;
    private var mItemsToUpdate;           // Array initialised by onReturnFetchMenuConfig()
    private var mNextItemToUpdate    = 0; // Index into the above array
    private var mIsGlance            as Lang.Boolean = false;

    function initialize() {
        AppBase.initialize();
        mApiKey = Properties.getValue("api_key");
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
        strNoApiKey          = WatchUi.loadResource($.Rez.Strings.NoAPIKey);
        strNoApiUrl          = WatchUi.loadResource($.Rez.Strings.NoApiUrl);
        strNoConfigUrl       = WatchUi.loadResource($.Rez.Strings.NoConfigUrl);
        strNoPhone           = WatchUi.loadResource($.Rez.Strings.NoPhone);
        strNoInternet        = WatchUi.loadResource($.Rez.Strings.NoInternet);
        strNoResponse        = WatchUi.loadResource($.Rez.Strings.NoResponse);
        strApiFlood          = WatchUi.loadResource($.Rez.Strings.ApiFlood);
        strConfigUrlNotFound = WatchUi.loadResource($.Rez.Strings.ConfigUrlNotFound);
        strNoJson            = WatchUi.loadResource($.Rez.Strings.NoJson);
        strUnhandledHttpErr  = WatchUi.loadResource($.Rez.Strings.UnhandledHttpErr);
        strTrailingSlashErr  = WatchUi.loadResource($.Rez.Strings.TrailingSlashErr);
        mQuitTimer           = new QuitTimer();

        var api_url = Properties.getValue("api_url") as Lang.String;

        if ((Properties.getValue("api_key") as Lang.String).length() == 0) {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp getInitialView(): No API key in the application settings.");
            }
            return ErrorView.create(strNoApiKey + ".");
        } else if (api_url.length() == 0) {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp getInitialView(): No API URL in the application settings.");
            }
            return ErrorView.create(strNoApiUrl + ".");
        } else if (api_url.substring(-1, api_url.length()).equals("/")) {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp getInitialView(): API URL must not have a trailing slash '/'.");
            }
            return ErrorView.create(strTrailingSlashErr + ".");
        } else if ((Properties.getValue("config_url") as Lang.String).length() == 0) {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp getInitialView(): No configuration URL in the application settings.");
            }
            return ErrorView.create(strNoConfigUrl + ".");
        } else if (! System.getDeviceSettings().phoneConnected) {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp fetchMenuConfig(): No Phone connection, skipping API call.");
            }
            return ErrorView.create(strNoPhone + ".");
        } else if (! System.getDeviceSettings().connectionAvailable) {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp fetchMenuConfig(): No Internet connection, skipping API call.");
            }
            return ErrorView.create(strNoInternet + ".");
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

        mMenuStatus = strUnavailable;
        switch (responseCode) {
            case Communications.BLE_HOST_TIMEOUT:
            case Communications.BLE_CONNECTION_UNAVAILABLE:
                if (Globals.scDebug) {
                    System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Code: BLE_HOST_TIMEOUT or BLE_CONNECTION_UNAVAILABLE, Bluetooth connection severed.");
                }
                if (!mIsGlance) {
                    ErrorView.show(strNoPhone + ".");
                }
                break;

            case Communications.BLE_QUEUE_FULL:
                if (Globals.scDebug) {
                    System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Code: BLE_QUEUE_FULL, API calls too rapid.");
                }
                if (!mIsGlance) {
                    ErrorView.show(strApiFlood);
                }
                break;

            case Communications.NETWORK_REQUEST_TIMED_OUT:
                if (Globals.scDebug) {
                    System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Code: NETWORK_REQUEST_TIMED_OUT, check Internet connection.");
                }
                if (!mIsGlance) {
                    ErrorView.show(strNoResponse);
                }
                break;

            case Communications.INVALID_HTTP_BODY_IN_NETWORK_RESPONSE:
                if (Globals.scDebug) {
                    System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Code: INVALID_HTTP_BODY_IN_NETWORK_RESPONSE, check JSON is returned.");
                }
                if (!mIsGlance) {
                    ErrorView.show(strNoJson);
                }
                break;

            case 404:
                if (Globals.scDebug) {
                    System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Code: 404, page not found. Check Configuration URL setting.");
                }
                if (!mIsGlance) {
                    ErrorView.show(strConfigUrlNotFound);
                }
                break;

            case 200:
                mMenuStatus = strAvailable;
                if (!mIsGlance) {
                    mHaMenu = new HomeAssistantView(data, null);
                    mQuitTimer.begin();
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
                WatchUi.requestUpdate();
                break;

            default:
                if (Globals.scDebug) {
                    System.println("HomeAssistantApp onReturnFetchMenuConfig(): Unhandled HTTP response code = " + responseCode);
                }
                if (!mIsGlance) {
                    ErrorView.show(strUnhandledHttpErr + responseCode);
                }
                break;
        }
    }

    (:glance)
    function fetchMenuConfig() as Void {
        var options = {
            :method       => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Communications.makeWebRequest(
            Properties.getValue("config_url"),
            null,
            options,
            method(:onReturnFetchMenuConfig)
        );
    }

    // Callback function after completing the GET request to fetch the API status.
    //
    (:glance)
    function onReturnFetchApiStatus(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        if (Globals.scDebug) {
            System.println("HomeAssistantApp onReturnFetchApiStatus() Response Code: " + responseCode);
            System.println("HomeAssistantApp onReturnFetchApiStatus() Response Data: " + data);
        }

        mApiStatus = strUnavailable;
        switch (responseCode) {
            case Communications.BLE_HOST_TIMEOUT:
            case Communications.BLE_CONNECTION_UNAVAILABLE:
                if (Globals.scDebug) {
                    System.println("HomeAssistantApp onReturnFetchApiStatus() Response Code: BLE_HOST_TIMEOUT or BLE_CONNECTION_UNAVAILABLE, Bluetooth connection severed.");
                }
                if (!mIsGlance) {
                    ErrorView.show(strNoPhone + ".");
                }
                break;

            case Communications.BLE_QUEUE_FULL:
                if (Globals.scDebug) {
                    System.println("HomeAssistantApp onReturnFetchApiStatus() Response Code: BLE_QUEUE_FULL, API calls too rapid.");
                }
                if (!mIsGlance) {
                    ErrorView.show(strApiFlood);
                }
                break;

            case Communications.NETWORK_REQUEST_TIMED_OUT:
                if (Globals.scDebug) {
                    System.println("HomeAssistantApp onReturnFetchApiStatus() Response Code: NETWORK_REQUEST_TIMED_OUT, check Internet connection.");
                }
                if (!mIsGlance) {
                    ErrorView.show(strNoResponse);
                }
                break;

            case Communications.INVALID_HTTP_BODY_IN_NETWORK_RESPONSE:
                if (Globals.scDebug) {
                    System.println("HomeAssistantApp onReturnFetchApiStatus() Response Code: INVALID_HTTP_BODY_IN_NETWORK_RESPONSE, check JSON is returned.");
                }
                if (!mIsGlance) {
                    ErrorView.show(strNoJson);
                }
                break;

            case 404:
                if (Globals.scDebug) {
                    System.println("HomeAssistantApp onReturnFetchApiStatus() Response Code: 404, page not found. Check Configuration URL setting.");
                }
                if (!mIsGlance) {
                    ErrorView.show(strConfigUrlNotFound);
                }
                break;

            case 200:
                var msg = null;
                if (data != null) {
                    msg = data.get("message");
                }
                if (msg.equals("API running.")) {
                    mApiStatus = strAvailable;
                } else {
                    if (!mIsGlance) {
                        ErrorView.show("API " + mApiStatus + ".");
                    }
                }
                WatchUi.requestUpdate();
                break;

            default:
                if (Globals.scDebug) {
                    System.println("HomeAssistantApp onReturnFetchApiStatus(): Unhandled HTTP response code = " + responseCode);
                }
                if (!mIsGlance) {
                    ErrorView.show(strUnhandledHttpErr + responseCode);
                }
        }
    }

    (:glance)
    function fetchApiStatus() as Void {
        var options = {
            :method       => Communications.HTTP_REQUEST_METHOD_GET,
            :headers      => {
                "Authorization" => "Bearer " + mApiKey
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Communications.makeWebRequest(
            Properties.getValue("api_url") + "/",
            null,
            options,
            method(:onReturnFetchApiStatus)
        );
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

    // We need to spread out the API calls so as not to overload the results queue and cause Communications.BLE_QUEUE_FULL (-101) error.
    // This function is called by a timer every Globals.menuItemUpdateInterval ms.
    function updateNextMenuItem() as Void {
        var itu = mItemsToUpdate as Lang.Array<HomeAssistantToggleMenuItem>;
        itu[mNextItemToUpdate].getState();
        mNextItemToUpdate = (mNextItemToUpdate + 1) % itu.size();
    }

    function getQuitTimer() as QuitTimer {
        return mQuitTimer;
    }

    (:glance)
    function getGlanceView() {
        mIsGlance = true;
        fetchMenuConfig();
        fetchApiStatus();
        return [new HomeAssistantGlanceView(self)];
    }
}

function getApp() as HomeAssistantApp {
    return Application.getApp() as HomeAssistantApp;
}
