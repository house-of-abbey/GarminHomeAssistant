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
    public static const MENU_STYLE_ICONS = 0;
    public static const MENU_STYLE_TEXT  = 1;

    private static var mApiKey                as Lang.String  = "";
    private static var mApiUrl                as Lang.String  = "";
    private static var mConfigUrl             as Lang.String  = "";
    private static var mAppTimeout            as Lang.Number  = 0;  // seconds
    private static var mConfirmTimeout        as Lang.Number  = 3;  // seconds
    private static var mMenuStyle             as Lang.Number  = MENU_STYLE_ICONS;
    private static var mMenuAlignment         as Lang.Number  = WatchUi.MenuItem.MENU_ITEM_LABEL_ALIGN_LEFT;
    private static var mIsWidgetStartNoTap    as Lang.Boolean = false;
    private static var mIsBatteryLevelEnabled as Lang.Boolean = false;
    private static var mBatteryRefreshRate    as Lang.Number  = 15; // minutes
    private static var mIsApp                 as Lang.Boolean = false;

    // Called on application start and then whenever the settings are changed.
    static function update() {
        mIsApp                 = getApp().getIsApp();
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

    static function getApiKey() as Lang.String {
        return mApiKey;
    }

    static function getApiUrl() as Lang.String {
        return mApiUrl;
    }

    static function getConfigUrl() as Lang.String {
        return mConfigUrl;
    }
    
    static function getAppTimeout() as Lang.Number {
        return mAppTimeout * 1000; // Convert to milliseconds
    }

    static function getConfirmTimeout() as Lang.Number {
        return mConfirmTimeout * 1000; // Convert to milliseconds
    }

    static function getMenuStyle() as Lang.Number {
        return mMenuStyle; // Either MENU_STYLE_ICONS or MENU_STYLE_TEXT
    }

    static function getMenuAlignment() as Lang.Number {
        return mMenuAlignment; // Either WatchUi.MenuItem.MENU_ITEM_LABEL_ALIGN_RIGHT or WatchUi.MenuItem.MENU_ITEM_LABEL_ALIGN_LEFT
    }

    static function getIsWidgetStartNoTap() as Lang.Boolean {
        return mIsWidgetStartNoTap;
    }

}
