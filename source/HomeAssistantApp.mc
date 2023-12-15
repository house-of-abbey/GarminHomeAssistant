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
// P A Abbey & J D Abbey, 31 October 2023
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
    private var mHaMenu              as HomeAssistantView or Null;
    private var mQuitTimer           as QuitTimer or Null;
    private var strNoApiKey          as Lang.String or Null;
    private var strNoApiUrl          as Lang.String or Null;
    private var strNoConfigUrl       as Lang.String or Null;
    private var strNoPhone           as Lang.String or Null;
    private var strNoInternet        as Lang.String or Null;
    private var strNoResponse        as Lang.String or Null;
    private var strNoMenu            as Lang.String or Null;
    private var strApiFlood          as Lang.String or Null;
    private var strConfigUrlNotFound as Lang.String or Null;
    private var strUnhandledHttpErr  as Lang.String or Null;
    private var strTrailingSlashErr  as Lang.String or Null;
    private var mItemsToUpdate;        // Array initialised by onReturnFetchMenuConfig()
    private var mNextItemToUpdate = 0; // Index into the above array

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Lang.Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Lang.Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>? {

        strNoApiKey          = WatchUi.loadResource($.Rez.Strings.NoAPIKey);
        strNoApiUrl          = WatchUi.loadResource($.Rez.Strings.NoApiUrl);
        strNoConfigUrl       = WatchUi.loadResource($.Rez.Strings.NoConfigUrl);
        strNoPhone           = WatchUi.loadResource($.Rez.Strings.NoPhone);
        strNoInternet        = WatchUi.loadResource($.Rez.Strings.NoInternet);
        strNoResponse        = WatchUi.loadResource($.Rez.Strings.NoResponse);
        strNoMenu            = WatchUi.loadResource($.Rez.Strings.NoMenu);
        strApiFlood          = WatchUi.loadResource($.Rez.Strings.ApiFlood);
        strConfigUrlNotFound = WatchUi.loadResource($.Rez.Strings.ConfigUrlNotFound);
        strUnhandledHttpErr  = WatchUi.loadResource($.Rez.Strings.UnhandledHttpErr);
        strTrailingSlashErr  = WatchUi.loadResource($.Rez.Strings.TrailingSlashErr);
        mQuitTimer            = new QuitTimer();

        var api_url = Properties.getValue("api_url") as Lang.String;

        if ((Properties.getValue("api_key") as Lang.String).length() == 0) {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp getInitialView(): No API key in the application settings.");
            }
            return [new ErrorView(strNoApiKey + "."), new ErrorDelegate()] as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>;
        } else if (api_url.length() == 0) {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp getInitialView(): No API URL in the application settings.");
            }
            return [new ErrorView(strNoApiUrl + "."), new ErrorDelegate()] as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>;
        } else if (api_url.substring(-1, api_url.length()).equals("/")) {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp getInitialView(): API URL must not have a trailing slash '/'.");
            }
            return [new ErrorView(strTrailingSlashErr + "."), new ErrorDelegate()] as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>;
        } else if ((Properties.getValue("config_url") as Lang.String).length() == 0) {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp getInitialView(): No configuration URL in the application settings.");
            }
            return [new ErrorView(strNoConfigUrl + "."), new ErrorDelegate()] as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>;
        } else if (! System.getDeviceSettings().phoneConnected) {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp fetchMenuConfig(): No Phone connection, skipping API call.");
            }
            return [new ErrorView(strNoPhone + "."), new ErrorDelegate()] as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>;
        } else if (! System.getDeviceSettings().connectionAvailable) {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp fetchMenuConfig(): No Internet connection, skipping API call.");
            }
            return [new ErrorView(strNoInternet + "."), new ErrorDelegate()] as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>;
        } else {
            fetchMenuConfig();
            return [new RootView(self), new RootViewDelegate(self)] as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>;
        }
    }

    // Callback function after completing the GET request to fetch the configuration menu.
    //
    function onReturnFetchMenuConfig(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        if (Globals.scDebug) {
            System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Code: " + responseCode);
            System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Data: " + data);
        }
        if (responseCode == Communications.BLE_HOST_TIMEOUT || responseCode == Communications.BLE_CONNECTION_UNAVAILABLE) {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Code: BLE_HOST_TIMEOUT or BLE_CONNECTION_UNAVAILABLE, Bluetooth connection severed.");
            }
            WatchUi.pushView(new ErrorView(strNoPhone + "."), new ErrorDelegate(), WatchUi.SLIDE_UP);
        } else if (responseCode == Communications.BLE_QUEUE_FULL) {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Code: BLE_QUEUE_FULL, API calls too rapid.");
            }
            if (!(WatchUi.getCurrentView()[0] instanceof ErrorView)) {
                // Avoid pushing multiple ErrorViews
                WatchUi.pushView(new ErrorView(strApiFlood), new ErrorDelegate(), WatchUi.SLIDE_UP);
            }
        } else if (responseCode == Communications.NETWORK_REQUEST_TIMED_OUT) {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Code: NETWORK_REQUEST_TIMED_OUT, check Internet connection.");
            }
            WatchUi.pushView(new ErrorView(strNoResponse), new ErrorDelegate(), WatchUi.SLIDE_UP);
        } else if (responseCode == 404) {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp onReturnFetchMenuConfig() Response Code: 404, page not found. Check Configuration URL setting.");
            }
            WatchUi.pushView(new ErrorView(strConfigUrlNotFound), new ErrorDelegate(), WatchUi.SLIDE_UP);
        } else if (responseCode == 200) {
            mHaMenu = new HomeAssistantView(data, null);
            mQuitTimer.begin();
            pushHomeAssistantMenuView();
            mItemsToUpdate = mHaMenu.getItemsToUpdate();
            // Start the continuous update process that continues for as long as the application is running.
            // The chain of functions from 'updateNextMenuItem()' calls 'updateNextMenuItem()' on completion.
            if (mItemsToUpdate.size() > 0) {
                updateNextMenuItem();
            }
        } else if (responseCode == Communications.NETWORK_REQUEST_TIMED_OUT) {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp onReturnFetchMenuConfig(): Network request timeout.");
            }
            WatchUi.pushView(new ErrorView(strNoMenu + ". " + strNoInternet + "?"), new ErrorDelegate(), WatchUi.SLIDE_UP);
        } else {
            if (Globals.scDebug) {
                System.println("HomeAssistantApp onReturnFetchMenuConfig(): Unhandled HTTP response code = " + responseCode);
            }
            WatchUi.pushView(new ErrorView(strUnhandledHttpErr + responseCode ), new ErrorDelegate(), WatchUi.SLIDE_UP);
        }
    }

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

    function homeAssistantMenuIsLoaded() as Lang.Boolean{
        return mHaMenu!=null;
    }

    function pushHomeAssistantMenuView() as Void{
        WatchUi.pushView(mHaMenu, new HomeAssistantViewDelegate(true), WatchUi.SLIDE_IMMEDIATE);
    }

    // We need to spread out the API calls so as not to overload the results queue and cause Communications.BLE_QUEUE_FULL (-101) error.
    // This function is called by a timer every Globals.menuItemUpdateInterval ms.
    function updateNextMenuItem() as Void {
        var itu = mItemsToUpdate as Lang.Array<HomeAssistantToggleMenuItem>;
        itu[mNextItemToUpdate].getState();
        mNextItemToUpdate = (mNextItemToUpdate + 1) % itu.size();
    }

    function getQuitTimer() as QuitTimer{
        return mQuitTimer;
    }

    (:glance)
    function getGlanceView() {
        return [new HomeAssistantGlanceView()];
    }
}

function getApp() as HomeAssistantApp {
    return Application.getApp() as HomeAssistantApp;
}
