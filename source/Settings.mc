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
// P A Abbey & J D Abbey, SomeoneOnEarth, 23 November 2023
//
//
// Description:
//
// Home Assistant settings.
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.Application.Properties;
using Toybox.WatchUi;
using Toybox.System;
// Battery Level Reporting
using Toybox.Background;
using Toybox.Time;

(:glance, :background)
class Settings {
    private static var instance;

    public static const MENU_STYLE_ICONS = 0;
    public static const MENU_STYLE_TEXT  = 1;

    private var mApiKey                as Lang.String  = "";
    private var mApiUrl                as Lang.String  = "";
    private var mConfigUrl             as Lang.String  = "";
    private var mAppTimeout            as Lang.Number  = 0;  // seconds
    private var mConfirmTimeout        as Lang.Number  = 3;  // seconds
    private var mMenuStyle             as Lang.Number  = MENU_STYLE_ICONS;
    private var mMenuAlignment         as Lang.Number  = WatchUi.MenuItem.MENU_ITEM_LABEL_ALIGN_LEFT;
    private var mIsWidgetStartNoTap    as Lang.Boolean = false;
    private var mIsBatteryLevelEnabled as Lang.Boolean = false;
    private var mBatteryRefreshRate    as Lang.Number  = 15; // minutes
    private var mIsApp                 as Lang.Boolean = false;

    private function initialize() {
        mIsApp = getApp().getIsApp();
        update();
    }

    // Called on application start and then whenever the settings are changed.
    function update() {
        mApiKey                = Properties.getValue("api_key");
        mApiUrl                = Properties.getValue("api_url");
        mConfigUrl             = Properties.getValue("config_url");
        mAppTimeout            = Properties.getValue("app_timeout");
        mConfirmTimeout        = Properties.getValue("confirm_timeout");
        mMenuStyle             = Properties.getValue("menu_theme");
        mMenuAlignment         = Properties.getValue("menu_alignment");
        mIsWidgetStartNoTap    = Properties.getValue("widget_start_no_tap");
        mIsBatteryLevelEnabled = Properties.getValue("enable_battery_level");
        mBatteryRefreshRate    = Properties.getValue("battery_level_refresh_rate");

        // Manage this inside the application or widget only (not a glance or background service process)
        if (mIsApp) {
            if (mIsBatteryLevelEnabled) {
                if ((System has :ServiceDelegate) and
                    ((Background.getTemporalEventRegisteredTime() == null) or
                    (Background.getTemporalEventRegisteredTime() != (mBatteryRefreshRate * 60)))) {
                    Background.registerForTemporalEvent(new Time.Duration(mBatteryRefreshRate * 60)); // Convert to seconds
                }
            } else {
                // Explicitly disable the background event which persists when the application closes.
                if ((System has :ServiceDelegate) and (Background.getTemporalEventRegisteredTime() != null)) {
                    Background.deleteTemporalEvent();
                }
            }
        } else {
            // Explicitly disable the background events for glances and ironically any use by the background service. However
            // that has been avoided more recently by not using this object in BackgroundServiceDelegate.
            if ((System has :ServiceDelegate) and (Background.getTemporalEventRegisteredTime() != null)) {
                Background.deleteTemporalEvent();
            }
        }
        if (Globals.scDebug) {
            System.println("Settings update(): getTemporalEventRegisteredTime() = " + Background.getTemporalEventRegisteredTime());
            if (Background.getTemporalEventRegisteredTime() != null) {
                System.println("Settings update(): getTemporalEventRegisteredTime().value() = " + Background.getTemporalEventRegisteredTime().value().format("%d") + " seconds");
            } else {
                System.println("Settings update(): getTemporalEventRegisteredTime() = null");
            }
        }
    }

    static function get() as Settings {
        if (instance == null) {
            instance = new Settings();
        }
        return instance;
    }

    function getApiKey() as Lang.String {
        return mApiKey;
    }

    function getApiUrl() as Lang.String {
        return mApiUrl;
    }

    function getConfigUrl() as Lang.String {
        return mConfigUrl;
    }
    
    function getAppTimeout() as Lang.Number {
        return mAppTimeout * 1000; // Convert to milliseconds
    }

    function getConfirmTimeout() as Lang.Number {
        return mConfirmTimeout * 1000; // Convert to milliseconds
    }

    function getMenuStyle() as Lang.Number {
        return mMenuStyle; // Either MENU_STYLE_ICONS or MENU_STYLE_TEXT
    }

    function getMenuAlignment() as Lang.Number {
        return mMenuAlignment; // Either WatchUi.MenuItem.MENU_ITEM_LABEL_ALIGN_RIGHT or WatchUi.MenuItem.MENU_ITEM_LABEL_ALIGN_LEFT
    }

    function getIsWidgetStartNoTap() as Lang.Boolean {
        return mIsWidgetStartNoTap;
    }

}
