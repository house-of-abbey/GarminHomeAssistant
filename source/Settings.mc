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
// P A Abbey & J D Abbey, SomeoneOnEarth & moesterheld & vincentezw, 23 November 2023
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.Application.Properties;
using Toybox.WatchUi;
using Toybox.System;
// Battery Level Reporting
using Toybox.Background;
using Toybox.Time;

//! Home Assistant settings. 
//!
//! <em>WARNING!</em> Careful putting ErrorView.show() calls in here. They need to be
//! guarded so that they do not get called when only displaying the glance view.
//
(:glance, :background)
class Settings {
    private static var mApiKey                as Lang.String  = "";
    private static var mWebhookId             as Lang.String  = "";
    private static var mApiUrl                as Lang.String  = "";
    private static var mConfigUrl             as Lang.String  = "";
    private static var mCacheConfig           as Lang.Boolean = false;
    private static var mClearCache            as Lang.Boolean = false;
    private static var mVibrate               as Lang.Boolean = false;
    private static var mWifiLteExecution      as Lang.Boolean = false;
    //! seconds
    private static var mAppTimeout            as Lang.Number  = 0;
    //! seconds
    private static var mPollDelay             as Lang.Number  = 0;
    //! seconds
    private static var mConfirmTimeout        as Lang.Number  = 3;
    private static var mPin                   as Lang.String? = "0000";
    private static var mMenuAlignment         as Lang.Number  = WatchUi.MenuItem.MENU_ITEM_LABEL_ALIGN_LEFT;
    private static var mIsSensorsLevelEnabled as Lang.Boolean = false;
    //! minutes
    private static var mBatteryRefreshRate    as Lang.Number  = 15;
    private static var mIsApp                 as Lang.Boolean = false;
    private static var mHasService            as Lang.Boolean = false;
    //! Must keep the object so it doesn't get garbage collected.
    private static var mWebhookManager        as WebhookManager?;

    //! Called on application start and then whenever the settings are changed.
    //
    static function update() {
        mIsApp                 = getApp().getIsApp();
        mApiKey                = Properties.getValue("api_key");
        mWebhookId             = Properties.getValue("webhook_id");
        mApiUrl                = Properties.getValue("api_url");
        mConfigUrl             = Properties.getValue("config_url");
        mCacheConfig           = Properties.getValue("cache_config");
        mClearCache            = Properties.getValue("clear_cache");
        mWifiLteExecution      = Properties.getValue("wifi_lte_execution");
        mVibrate               = Properties.getValue("enable_vibration");
        mAppTimeout            = Properties.getValue("app_timeout");
        mPollDelay             = Properties.getValue("poll_delay_combined");
        mConfirmTimeout        = Properties.getValue("confirm_timeout");
        mPin                   = validatePin();
        mMenuAlignment         = Properties.getValue("menu_alignment");
        mIsSensorsLevelEnabled = Properties.getValue("enable_battery_level");
        mBatteryRefreshRate    = Properties.getValue("battery_level_refresh_rate");
    }

    //! A webhook is required for non-privileged API calls.
    //
    static function webhook() {
        if (System has :ServiceDelegate) {
            mHasService = true;
        }

        // Manage this inside the application or widget only (not a glance or background service process)
        if (mIsApp) {
            if (mHasService) {
                if (System.getDeviceSettings().phoneConnected) {
                    mWebhookManager = new WebhookManager();
                    if (getWebhookId().equals("")) {
                        // System.println("Settings update(): Doing full webhook & sensor creation.");
                        mWebhookManager.requestWebhookId();
                    } else {
                        // System.println("Settings update(): Doing just sensor creation.");
                        // We already have a Webhook ID, so just enable or disable the sensor in Home Assistant.
                        mWebhookManager.registerWebhookSensors();
                    }
                    if (mIsSensorsLevelEnabled) {
                        // Create the timed activity
                        if ((Background.getTemporalEventRegisteredTime() == null) or
                            (Background.getTemporalEventRegisteredTime() != (mBatteryRefreshRate * 60))) {
                            Background.registerForTemporalEvent(new Time.Duration(mBatteryRefreshRate * 60)); // Convert to seconds
                            Background.registerForActivityCompletedEvent();
                        }
                    } else if (Background.getTemporalEventRegisteredTime() != null) {
                        Background.deleteTemporalEvent();
                        Background.deleteActivityCompletedEvent();
                    }
                }
            } else {
                // Explicitly disable the background event which persists when the application closes.
                // If !mHasService disable the Settings option as user feedback
                unsetIsSensorsLevelEnabled();
                unsetWebhookId();
            }
        }
        // System.println("Settings webhook(): getTemporalEventRegisteredTime() = " + Background.getTemporalEventRegisteredTime());
        // if (Background.getTemporalEventRegisteredTime() != null) {
        //     System.println("Settings webhook(): getTemporalEventRegisteredTime().value() = " + Background.getTemporalEventRegisteredTime().value().format("%d") + " seconds");
        // } else {
        //     System.println("Settings webhook(): getTemporalEventRegisteredTime() = null");
        // }
     }

    //! Get the API key supplied as part of the Settings.
    //!
    //! @return The API Key
    //
    static function getApiKey() as Lang.String {
        return mApiKey;
    }

    //! Get the Webhook ID supplied as part of the Settings.
    //!
    //! @return The Webhook ID
    //
    static function getWebhookId() as Lang.String {
        return mWebhookId;
    }

    //! Set the Webhook ID supplied as part of the Settings.
    //!
    //! @param webhookId The Webhook ID value to be saved.
    //
    static function setWebhookId(webhookId as Lang.String) {
        mWebhookId = webhookId;
        Properties.setValue("webhook_id", mWebhookId);
    }

    //! Delete the Webhook ID saved as part of the Settings.
    //
    static function unsetWebhookId() {
        mWebhookId = "";
        Properties.setValue("webhook_id", mWebhookId);
    }

    //! Get the API URL supplied as part of the Settings.
    //!
    //! @return The API URL
    //
    static function getApiUrl() as Lang.String {
        return mApiUrl;
    }

    //! Get the menu configuration URL supplied as part of the Settings.
    //!
    //! @return The menu configuration URL
    //
    static function getConfigUrl() as Lang.String {
        return mConfigUrl;
    }

    //! Get the menu cache Boolean option supplied as part of the Settings.
    //!
    //! @return Boolean for whether the menu should be cached to save application
    //!         start up time.
    //
    static function getCacheConfig() as Lang.Boolean {
        return mCacheConfig;
    }

    //! Get the clear cache Boolean option supplied as part of the Settings.
    //!
    //! @return Boolean for whether the cache should be cleared next time the
    //!         application is started, forcing a menu refresh.
    //
    static function getClearCache() as Lang.Boolean {
        return mClearCache;
    }

    //! Unset the clear cache Boolean option supplied as part of the Settings.
    //
    static function unsetClearCache() {
        mClearCache = false;
        Properties.setValue("clear_cache", mClearCache);
    }

    //! Get the value of the Wi-Fi/LTE toggle in settings.
    //!
    //! @return The state of the toggle.
    //
    static function getWifiLteExecutionEnabled() as Lang.Boolean {
        // Wi-Fi/LTE sync execution on a cached menu
        if (!mCacheConfig) {
            return false;
        }
        return mWifiLteExecution;
    }

    //! Get the vibration Boolean option supplied as part of the Settings.
    //!
    //! @return Boolean for whether vibration is enabled.
    //
    static function getVibrate() as Lang.Boolean {
        return mVibrate;
    }

    //! Get the application timeout value supplied as part of the Settings.
    //!
    //! @return The application timeout in milliseconds.
    //
    static function getAppTimeout() as Lang.Number {
        return mAppTimeout * 1000; // Convert to milliseconds
    }

    //! Get the application API polling interval supplied as part of the Settings.
    //!
    //! @return The application API polling interval in milliseconds.
    //
    static function getPollDelay() as Lang.Number {
        return mPollDelay * 1000; // Convert to milliseconds
    }

    //! Get the menu item confirmation delay supplied as part of the Settings.
    //!
    //! @return The menu item confirmation delay in milliseconds.
    //
    static function getConfirmTimeout() as Lang.Number {
        return mConfirmTimeout * 1000; // Convert to milliseconds
    }

    //! Get the menu item security PIN supplied as part of the Settings.
    //!
    //! @return The menu item security PIN.
    //
    static function getPin() as Lang.String? {
        return mPin;
    }

    //! Check the user selected PIN confirms to 4 digits as a string.
    //!
    //! @return The validated 4 digit string.
    //
    private static function validatePin() as Lang.String? {
        var pin = Properties.getValue("pin");
        if (pin.toNumber() == null || pin.length() != 4) {
            return null;
        }
        return pin;
    }

    //! Get the menu item alignment as part of the Settings.
    //!
    //! @return The menu item alignment.
    //
    static function getMenuAlignment() as Lang.Number {
        return mMenuAlignment; // Either WatchUi.MenuItem.MENU_ITEM_LABEL_ALIGN_RIGHT or WatchUi.MenuItem.MENU_ITEM_LABEL_ALIGN_LEFT
    }

    //! Is logging of the watch sensors enabled? E.g. battery, activity etc.
    //!
    //! @return Boolean for whether logging of the watch sensors is enabled.
    //
    static function isSensorsLevelEnabled() as Lang.Boolean {
        return mIsSensorsLevelEnabled;
    }

    //! Disable logging of the watch's sensors.
    //
    static function unsetIsSensorsLevelEnabled() {
        mIsSensorsLevelEnabled = false;
        Properties.setValue("enable_battery_level", mIsSensorsLevelEnabled);
        if (mHasService and (Background.getTemporalEventRegisteredTime() != null)) {
            Background.deleteTemporalEvent();
            Background.deleteActivityCompletedEvent();
        }
    }

}
