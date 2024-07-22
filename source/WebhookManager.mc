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
//
// Description:
//
// Home Assistant Webhook creation.
//
// Reference:
//  * https://developers.home-assistant.io/docs/api/native-app-integration
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.Communications;
using Toybox.System;
using Toybox.WatchUi;

// Can use push view so must never be run in a glance context
class WebhookManager {

    function onReturnRequestWebhookId(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        switch (responseCode) {
            case Communications.BLE_HOST_TIMEOUT:
            case Communications.BLE_CONNECTION_UNAVAILABLE:
                // System.println("WebhookManager onReturnRequestWebhookId() Response Code: BLE_HOST_TIMEOUT or BLE_CONNECTION_UNAVAILABLE, Bluetooth connection severed.");
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.WebhookFailed) as Lang.String + "\n" + WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String + ".");
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
                Settings.unsetIsSensorsLevelEnabled();
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.WebhookFailed) as Lang.String + "\n" + WatchUi.loadResource($.Rez.Strings.NoJson) as Lang.String);
                break;

            case 404:
                // System.println("WebhookManager onReturnRequestWebhookId() Response Code: 404, page not found. Check API URL setting.");
                Settings.unsetIsSensorsLevelEnabled();
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.WebhookFailed) as Lang.String + "\n" + WatchUi.loadResource($.Rez.Strings.ApiUrlNotFound) as Lang.String);
                break;

            case 200:
            case 201:
                var id = data.get("webhook_id") as Lang.String or Null;
                if (id != null) {
                    Settings.setWebhookId(id);
                    // System.println("WebhookManager onReturnRegisterWebhookSensor(): Registering first sensor: Battery Level");
                    registerWebhookSensor({
                        "device_class"        => "battery",
                        "name"                => "Battery Level",
                        "state"               => System.getSystemStats().battery,
                        "type"                => "sensor",
                        "unique_id"           => "battery_level",
                        "unit_of_measurement" => "%",
                        "state_class"         => "measurement",
                        "entity_category"     => "diagnostic",
                        "disabled"            => !Settings.isSensorsLevelEnabled()
                    }, 0);
                } else {
                    // System.println("WebhookManager onReturnRequestWebhookId(): No webhook id in response data.");
                    Settings.unsetIsSensorsLevelEnabled();
                    ErrorView.show(WatchUi.loadResource($.Rez.Strings.WebhookFailed) as Lang.String);
                }
                break;

            default:
                // System.println("WebhookManager onReturnRequestWebhookId(): Unhandled HTTP response code = " + responseCode);
                Settings.unsetIsSensorsLevelEnabled();
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.WebhookFailed) as Lang.String + "\n" + WatchUi.loadResource($.Rez.Strings.UnhandledHttpErr) as Lang.String + responseCode);
        }
    }

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
                :headers      => {
                    "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON,
                    "Authorization" => "Bearer " + Settings.getApiKey()
                },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onReturnRequestWebhookId)
        );
    }

    function onReturnRegisterWebhookSensor(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String, step as Lang.Number) as Void {
        switch (responseCode) {
            case Communications.BLE_HOST_TIMEOUT:
            case Communications.BLE_CONNECTION_UNAVAILABLE:
                // System.println("WebhookManager onReturnRegisterWebhookSensor() Response Code: BLE_HOST_TIMEOUT or BLE_CONNECTION_UNAVAILABLE, Bluetooth connection severed.");
                Settings.unsetWebhookId();
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.WebhookFailed) as Lang.String + "\n" + WatchUi.loadResource($.Rez.Strings.NoPhone) as Lang.String + ".");
                break;

            case Communications.BLE_QUEUE_FULL:
                // System.println("WebhookManager onReturnRegisterWebhookSensor() Response Code: BLE_QUEUE_FULL, API calls too rapid.");
                Settings.unsetWebhookId();
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.WebhookFailed) as Lang.String + "\n" + WatchUi.loadResource($.Rez.Strings.ApiFlood) as Lang.String);
                break;

            case Communications.NETWORK_REQUEST_TIMED_OUT:
                // System.println("WebhookManager onReturnRegisterWebhookSensor() Response Code: NETWORK_REQUEST_TIMED_OUT, check Internet connection.");
                Settings.unsetWebhookId();
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.WebhookFailed) as Lang.String + "\n" + WatchUi.loadResource($.Rez.Strings.NoResponse) as Lang.String);
                break;

            case Communications.NETWORK_RESPONSE_OUT_OF_MEMORY:
                // System.println("WebhookManager onReturnRegisterWebhookSensor() Response Code: NETWORK_RESPONSE_OUT_OF_MEMORY, are we going too fast?");
                Settings.unsetWebhookId();
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
                var d = data as Lang.Dictionary;
                if ((d.get("success") as Lang.Boolean or Null) != false) {
                    // System.println("WebhookManager onReturnRegisterWebhookSensor(): Success");
                    switch (step) {
                        case 0:
                            // System.println("WebhookManager onReturnRegisterWebhookSensor(): Registering next sensor: Battery is Charging");
                            registerWebhookSensor({
                                "device_class"    => "battery_charging",
                                "name"            => "Battery is Charging",
                                "state"           => System.getSystemStats().charging,
                                "type"            => "binary_sensor",
                                "unique_id"       => "battery_is_charging",
                                "entity_category" => "diagnostic",
                                "disabled"        => !Settings.isSensorsLevelEnabled()
                            }, 1);
                            break;
                        case 1:
                            // System.println("WebhookManager onReturnRegisterWebhookSensor(): Registering next sensor: Activity");
                            if (Activity has :getProfileInfo) {
                                var activity = Activity.getProfileInfo().sport;
                                if ((Activity.getActivityInfo() != null) and
                                    ((Activity.getActivityInfo().elapsedTime == null) or
                                     (Activity.getActivityInfo().elapsedTime == 0))) {
                                    // Indicate no activity with -1, not part of Garmin's activity codes.
                                    // https://developer.garmin.com/connect-iq/api-docs/Toybox/Activity.html#Sport-module
                                    activity = -1;
                                }
                                registerWebhookSensor({
                                    "name"      => "Activity",
                                    "state"     => activity,
                                    "type"      => "sensor",
                                    "unique_id" => "activity",
                                    "disabled"  => !Settings.isSensorsLevelEnabled()
                                }, 2);
                                break;
                            }
                        case 2:
                            // System.println("WebhookManager onReturnRegisterWebhookSensor(): Registering next sensor: Sub-Activity");
                            if (Activity has :getProfileInfo) {
                                var sub_activity = Activity.getProfileInfo().subSport;
                                if ((Activity.getActivityInfo() != null) and
                                    ((Activity.getActivityInfo().elapsedTime == null) or
                                     (Activity.getActivityInfo().elapsedTime == 0))) {
                                    // Indicate no activity with -1, not part of Garmin's activity codes.
                                    // https://developer.garmin.com/connect-iq/api-docs/Toybox/Activity.html#Sport-module
                                    sub_activity = -1;
                                }
                                registerWebhookSensor({
                                    "name"      => "Sub-activity",
                                    "state"     => sub_activity,
                                    "type"      => "sensor",
                                    "unique_id" => "sub_activity",
                                    "disabled"  => !Settings.isSensorsLevelEnabled()
                                }, 3);
                                break;
                            }
                        case 3:
                            getApp().startUpdates();
                        default:
                    }
                } else {
                    // System.println("WebhookManager onReturnRegisterWebhookSensor(): Failure");
                    Settings.unsetWebhookId();
                    Settings.unsetIsSensorsLevelEnabled();
                    ErrorView.show(WatchUi.loadResource($.Rez.Strings.WebhookFailed) as Lang.String);
                }
                break;

            default:
                // System.println("WebhookManager onReturnRequestWebhookId(): Unhandled HTTP response code = " + responseCode);
                Settings.unsetWebhookId();
                Settings.unsetIsSensorsLevelEnabled();
                ErrorView.show(WatchUi.loadResource($.Rez.Strings.WebhookFailed) as Lang.String + "\n" + WatchUi.loadResource($.Rez.Strings.UnhandledHttpErr) as Lang.String + responseCode);
        }
    }

    function registerWebhookSensor(sensor as Lang.Object, step as Lang.Number) {
        var url = Settings.getApiUrl() + "/webhook/" + Settings.getWebhookId();
        // System.println("WebhookManager registerWebhookSensor(): Registering webhook sensor: " + sensor.toString());
        // System.println("WebhookManager registerWebhookSensor(): URL=" + url);
        // https://developers.home-assistant.io/docs/api/native-app-integration/sensors/#registering-a-sensor
        Communications.makeWebRequest(
            url,
            {
                "type" => "register_sensor",
                "data" => sensor
            },
            {
                :method       => Communications.HTTP_REQUEST_METHOD_POST,
                :headers      => {
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
                },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
                :context      => step
            },
            method(:onReturnRegisterWebhookSensor)
        );
    }

}
