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
// P A Abbey & J D Abbey, 10 January 2024
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.Communications;
using Toybox.System;
using Toybox.WatchUi;

//! Home Assistant Webhook creation.
//!
//! NB. Because we can use push view (E.g. `ErrorView.show()`) this class must never
//! be run in a glance context.
//!
//! Reference: https://developers.home-assistant.io/docs/api/native-app-integration
//
(:glance)
class WebhookManager {
    private var mSensors as Lang.Array<Lang.Object> = [];

    //! Callback for requesting a Webhook ID.
    //!
    //! @param responseCode Response code
    //! @param data         Return data
    //
    function onReturnRequestWebhookId(
        responseCode as Lang.Number,
        data         as Null or Lang.Dictionary or Lang.String
    ) as Void {
        switch (responseCode) {
            case Communications.BLE_HOST_TIMEOUT:
            case Communications.BLE_CONNECTION_UNAVAILABLE:
                // System.println("WebhookManager onReturnRequestWebhookId() Response Code: BLE_HOST_TIMEOUT or BLE_CONNECTION_UNAVAILABLE, Bluetooth connection severed.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.WebhookFailed) as Lang.String + "\n" + WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String);
                break;

            case Communications.BLE_QUEUE_FULL:
                // System.println("WebhookManager onReturnRequestWebhookId() Response Code: BLE_QUEUE_FULL, API calls too rapid.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.WebhookFailed) as Lang.String + "\n" + WatchUi.loadResource($.Rez.Strings.ApiFlood) as Lang.String);
                break;

            case Communications.NETWORK_REQUEST_TIMED_OUT:
                // System.println("WebhookManager onReturnRequestWebhookId() Response Code: NETWORK_REQUEST_TIMED_OUT, check Internet connection.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.WebhookFailed) as Lang.String + "\n" + WatchUi.loadResource($.Rez.Strings.NoResponse) as Lang.String);
                break;

            case Communications.NETWORK_RESPONSE_OUT_OF_MEMORY:
                // System.println("WebhookManager onReturnRequestWebhookId() Response Code: NETWORK_RESPONSE_OUT_OF_MEMORY, are we going too fast?");
                // Ignore and see if we can carry on
                break;
            case Communications.INVALID_HTTP_BODY_IN_NETWORK_RESPONSE:
                // System.println("WebhookManager onReturnRequestWebhookId() Response Code: INVALID_HTTP_BODY_IN_NETWORK_RESPONSE, check JSON is returned.");
                Settings.unsetIsSensorsEnabled();
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.WebhookFailed) as Lang.String + "\n" + WatchUi.loadResource($.Rez.Strings.NoJson) as Lang.String);
                break;

            case 404:
                // System.println("WebhookManager onReturnRequestWebhookId() Response Code: 404, page not found. Check API URL setting.");
                Settings.unsetIsSensorsEnabled();
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.WebhookFailed) as Lang.String + "\n" + WatchUi.loadResource($.Rez.Strings.ApiUrlNotFound) as Lang.String);
                break;

            case 200:
            case 201:
                var id = data.get("webhook_id") as Lang.String?;
                if (id != null) {
                    Settings.setWebhookId(id);
                    // System.println("WebhookManager onReturnRegisterWebhookSensor(): Registering first sensor: Battery Level");
                    registerWebhookSensors();
                } else {
                    // System.println("WebhookManager onReturnRequestWebhookId(): No webhook id in response data.");
                    Settings.unsetIsSensorsEnabled();
                    ErrorView.show(WatchUi.loadResource($.Rez.Strings.WebhookFailed) as Lang.String + ".");
                }
                break;

            default:
                // System.println("WebhookManager onReturnRequestWebhookId(): Unhandled HTTP response code = " + responseCode);
                Settings.unsetIsSensorsEnabled();
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.WebhookFailed) as Lang.String + "\n" + WatchUi.loadResource($.Rez.Strings.UnhandledHttpErr) as Lang.String + responseCode);
        }
    }

    //! Request a Webhook ID from Home Assistant for use in this application.
    //
    function requestWebhookId() {
        var deviceSettings = System.getDeviceSettings();
        // System.println("WebhookManager requestWebhookId(): Requesting webhook id for device = " + deviceSettings.uniqueIdentifier);
        Communications.makeWebRequest(
            Settings.getApiUrl() + "/mobile_app/registrations",
            {
                "device_id"           => deviceSettings.uniqueIdentifier,
                "app_id"              => "garmin_home_assistant",
                "app_name"            => WatchUi.loadResource($.Rez.Strings.AppName) as Lang.String,
                "app_version"         => "",
                "device_name"         => "Garmin Device",
                "manufacturer"        => "Garmin",
                // An unhelpful part number that can be translated to a familiar model name.
                "model"               => deviceSettings.partNumber,
                "os_name"             => "",
                "os_version"          => Lang.format("$1$.$2$", deviceSettings.firmwareVersion),
                "supports_encryption" => false,
                "app_data"            => {}
            },
            {
                :method       => Communications.HTTP_REQUEST_METHOD_POST,
                :headers      => Settings.augmentHttpHeaders({
                    "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON,
                    "Authorization" => "Bearer " + Settings.getApiKey()
                }),
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onReturnRequestWebhookId)
        );
    }

    //! Callback function for the POST request to register the watch's sensors on the Home Assistant instance.
    //!
    //! @param responseCode Response code.
    //! @param data         Response data.
    //! @param sensors      The remaining sensors to be processed. The list of sensors is iterated through
    //!                     until empty. Each POST request creating one sensor on the local Home Assistant.
    //
    function onReturnRegisterWebhookSensor(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        switch (responseCode) {
            case Communications.BLE_HOST_TIMEOUT:
            case Communications.BLE_CONNECTION_UNAVAILABLE:
                // System.println("WebhookManager onReturnRegisterWebhookSensor() Response Code: BLE_HOST_TIMEOUT or BLE_CONNECTION_UNAVAILABLE, Bluetooth connection severed.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.WebhookFailed) as Lang.String + "\n" + WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String);
                break;

            case Communications.BLE_QUEUE_FULL:
                // System.println("WebhookManager onReturnRegisterWebhookSensor() Response Code: BLE_QUEUE_FULL, API calls too rapid.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.WebhookFailed) as Lang.String + "\n" + WatchUi.loadResource($.Rez.Strings.ApiFlood) as Lang.String);
                break;

            case Communications.NETWORK_REQUEST_TIMED_OUT:
                // System.println("WebhookManager onReturnRegisterWebhookSensor() Response Code: NETWORK_REQUEST_TIMED_OUT, check Internet connection.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.WebhookFailed) as Lang.String + "\n" + WatchUi.loadResource($.Rez.Strings.NoResponse) as Lang.String);
                break;

            case Communications.NETWORK_RESPONSE_OUT_OF_MEMORY:
                // System.println("WebhookManager onReturnRegisterWebhookSensor() Response Code: NETWORK_RESPONSE_OUT_OF_MEMORY, are we going too fast?");
                // Ignore and see if we can carry on
                break;

            case Communications.INVALID_HTTP_BODY_IN_NETWORK_RESPONSE:
                // System.println("WebhookManager onReturnRegisterWebhookSensor() Response Code: INVALID_HTTP_BODY_IN_NETWORK_RESPONSE, check JSON is returned.");
                // Webhook ID might have been deleted on Home Assistant server
                Settings.unsetWebhookId();
                // System.println("WebhookManager onReturnRegisterWebhookSensor(): Webhook ID invalid, going full chain.");
                requestWebhookId();
                break;

            case 404:
                // System.println("WebhookManager onReturnRegisterWebhookSensor() Response Code: 404, page not found. Check API URL setting.");
                // Webhook ID might have been deleted on Home Assistant server
                Settings.unsetWebhookId();
                // System.println("WebhookManager onReturnRegisterWebhookSensor(): Webhook ID invalid, going full chain.");
                requestWebhookId();
                break;

            case 200:
            case 201:
                if (data instanceof Lang.Dictionary) {
                    var d = data             as Lang.Dictionary;
                    var b = d.get("success") as Lang.Boolean?;
                    if (b != null and b != false) {
                        mSensors = mSensors.slice(1, null);
                        if (mSensors.size() == 0) {
                            getApp().startUpdates();
                        } else {
                            registerWebhookSensor();
                        }
                    } else {
                        // System.println("WebhookManager onReturnRegisterWebhookSensor(): Failure, no 'success'.");
                        Settings.unsetWebhookId();
                        Settings.unsetIsSensorsEnabled();
                        ErrorView.show(WatchUi.loadResource($.Rez.Strings.WebhookFailed) as Lang.String + ".");
                    }
                } else {
                    // !! Speculative code for an application crash !!
                    // System.println("WebhookManager onReturnRegisterWebhookSensor(): Failure, not a Lang.Dict");
                    // Webhook ID might have been deleted on Home Assistant server and a Lang.String is trying to tell us an error message
                    Settings.unsetWebhookId();
                    Settings.unsetIsSensorsEnabled();
                    if (data == null) {
                        ErrorView.show(WatchUi.loadResource($.Rez.Strings.WebhookFailed) as Lang.String + "\nNull data");
                    } else {
                        // All objects have toString()
                        ErrorView.show(WatchUi.loadResource($.Rez.Strings.WebhookFailed) as Lang.String + "\n" + data.toString());
                    }
                }
                break;

            default:
                // System.println("WebhookManager onReturnRequestWebhookId(): Unhandled HTTP response code = " + responseCode);
                Settings.unsetWebhookId();
                Settings.unsetIsSensorsEnabled();
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.WebhookFailed) as Lang.String + "\n" + WatchUi.loadResource($.Rez.Strings.UnhandledHttpErr) as Lang.String + " " + responseCode);
        }
    }

    //! Local method to send the POST request to register a number of sensors. The sensors are taken from the class variable
    //! mSensors created by registerWebhookSensors().
    //
    private function registerWebhookSensor() {
        var url = Settings.getApiUrl() + "/webhook/" + Settings.getWebhookId();
        // System.println("WebhookManager registerWebhookSensor(): Registering webhook sensor: " + sensor.toString());
        // System.println("WebhookManager registerWebhookSensor(): URL=" + url);
        // https://developers.home-assistant.io/docs/api/native-app-integration/sensors/#registering-a-sensor
        Communications.makeWebRequest(
            url,
            {
                "type" => "register_sensor",
                "data" => mSensors[0]
            },
            {
                :method       => Communications.HTTP_REQUEST_METHOD_POST,
                :headers      => Settings.augmentHttpHeaders({
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
                }),
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onReturnRegisterWebhookSensor)
        );
    }

    //! Request the creation of all the supported watch sensors on the Home Assistant instance.
    //
    function registerWebhookSensors() {
        var heartRate = Activity.getActivityInfo().currentHeartRate;

        mSensors = [
            {
                "device_class"        => "battery",
                "name"                => "Battery Level",
                "state"               => System.getSystemStats().battery,
                "type"                => "sensor",
                "unique_id"           => "battery_level",
                "icon"                => "mdi:battery",
                "unit_of_measurement" => "%",
                "state_class"         => "measurement",
                "entity_category"     => "diagnostic",
                "disabled"            => !Settings.IsSensorsEnabled()
            },
            {
                "device_class"        => "battery_charging",
                "name"                => "Battery is Charging",
                "state"               => System.getSystemStats().charging,
                "type"                => "binary_sensor",
                "unique_id"           => "battery_is_charging",
                "icon"                => System.getSystemStats().charging ? "mdi:battery-plus" : "mdi:battery-minus",
                "entity_category"     => "diagnostic",
                "disabled"            => !Settings.IsSensorsEnabled()
            },
            {
                "name"                => "Heart rate",
                "state"               => heartRate == null ? "unknown" : heartRate,
                "type"                => "sensor",
                "unique_id"           => "heart_rate",
                "icon"                => "mdi:heart-pulse",
                "unit_of_measurement" => "bpm",
                "state_class"         => "measurement",
                "disabled"            => !Settings.IsSensorsEnabled()
            }
        ];

        if (Toybox has :ActivityMonitor) {
            // System.println("WebhookManager registerWebhookSensors(): has ActivityMonitor class");
            var activityInfo = ActivityMonitor.getInfo();
            mSensors.add({
                "name"                => "Steps today",
                "state"               => activityInfo.steps == null ? "unknown" : activityInfo.steps,
                "type"                => "sensor",
                "unique_id"           => "steps_today",
                "icon"                => "mdi:walk",
                "state_class"         => "total",
                "disabled"            => !Settings.IsSensorsEnabled()
            });

            if (ActivityMonitor.Info has :floorsClimbed) {
                mSensors.add({
                    "name"                => "Floors climbed today",
                    "state"               => activityInfo.floorsClimbed == null ? "unknown" : activityInfo.floorsClimbed,
                    "type"                => "sensor",
                    "unique_id"           => "floors_climbed_today",
                    "icon"                => "mdi:stairs-up",
                    "state_class"         => "total",
                    "disabled"            => !Settings.IsSensorsEnabled()
                });
            }

            if (ActivityMonitor.Info has :floorsDescended) {
                mSensors.add({
                    "name"                => "Floors descended today",
                    "state"               => activityInfo.floorsDescended == null ? "unknown" : activityInfo.floorsDescended,
                    "type"                => "sensor",
                    "unique_id"           => "floors_descended_today",
                    "icon"                => "mdi:stairs-down",
                    "state_class"         => "total",
                    "disabled"            => !Settings.IsSensorsEnabled()
                });
            }

            if (ActivityMonitor.Info has :respirationRate) {
                mSensors.add({
                    "name"                => "Respiration rate",
                    "state"               => activityInfo.respirationRate == null ? "unknown" : activityInfo.respirationRate,
                    "type"                => "sensor",
                    "unique_id"           => "respiration_rate",
                    "icon"                => "mdi:lungs",
                    "unit_of_measurement" => "bpm",
                    "state_class"         => "measurement",
                    "disabled"            => !Settings.IsSensorsEnabled()
                });
            }
        } else {
            //System.println("WebhookManager registerWebhookSensors(): has no ActivityMonitor class");
        }

        if (Activity has :getProfileInfo) {
            var activity     = Activity.getProfileInfo().sport;
            var sub_activity = Activity.getProfileInfo().subSport;

            if ((Activity.getActivityInfo() != null) and
                ((Activity.getActivityInfo().elapsedTime == null) or
                    (Activity.getActivityInfo().elapsedTime == 0))) {
                // Indicate no activity with -1, not part of Garmin's activity codes.
                // https://developer.garmin.com/connect-iq/api-docs/Toybox/Activity.html#Sport-module
                activity     = -1;
                sub_activity = -1;
            }
            mSensors.add({
                "name"      => "Activity",
                "state"     => activity,
                "type"      => "sensor",
                "unique_id" => "activity",
                "disabled"  => !Settings.IsSensorsEnabled()
            });
            mSensors.add({
                "name"      => "Sub-activity",
                "state"     => sub_activity,
                "type"      => "sensor",
                "unique_id" => "sub_activity",
                "disabled"  => !Settings.IsSensorsEnabled()
            });
        }

        registerWebhookSensor();
    }

}
