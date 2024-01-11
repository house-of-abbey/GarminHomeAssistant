using Toybox.Lang;
using Toybox.Communications;
using Toybox.System;

class WebhookManager {
    function onReturnRequestWebhookId(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        // TODO: Handle errors
        if (responseCode == 201) {
            var id = data.get("webhook_id") as Lang.String or Null;
            if (id != null) {
                Settings.setWebhookId(id);
                registerWebhookSensor({
                    "device_class"        => "battery",
                    "name"                => "Battery Level",
                    "state"               => System.getSystemStats().battery,
                    "type"                => "sensor",
                    "unique_id"           => "battery_level",
                    "unit_of_measurement" => "%",
                    "state_class"         => "measurement",
                    "entity_category"     => "diagnostic",
                    "disabled"            => false
                });
                registerWebhookSensor({
                    "device_class"    => "battery_charging",
                    "name"            => "Battery is Charging",
                    "state"           => System.getSystemStats().charging,
                    "type"            => "binary_sensor",
                    "unique_id"       => "battery_is_charging",
                    "entity_category" => "diagnostic",
                    "disabled"        => false
                });
            }
        } else {
            if (Globals.scDebug) {
                System.println("WebhookManager onReturnRequestWebhookId(): Error: " + responseCode);
            }
        }
    }

    function requestWebhookId() {
        if (Globals.scDebug) {
            System.println("WebhookManager requestWebhookId(): Requesting webhook id");
        }
        Communications.makeWebRequest(
            Settings.getApiUrl() + "/mobile_app/registrations",
            {
                "device_id"           => System.getDeviceSettings().uniqueIdentifier,
                "app_id"              => "garmin_home_assistant",
                "app_name"            => RezStrings.getAppName(),
                "app_version"         => "",
                "device_name"         => "Garmin Watch",
                "manufacturer"        => "Garmin",
                "model"               => "",
                "os_name"             => "",
                "os_version"          => Lang.format("$1$.$2$", System.getDeviceSettings().firmwareVersion),
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

    function onReturnRegisterWebhookSensor(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        // TODO: Handle errors
        if (responseCode == 201) {
            if ((data.get("success") as Lang.Boolean or Null) == true) {
                if (Globals.scDebug) {
                    System.println("WebhookManager onReturnRegisterWebhookSensor(): Success");
                }
            }
        } else {
            if (Globals.scDebug) {
                System.println("WebhookManager onReturnRegisterWebhookSensor(): Error: " + responseCode);
            }
        }
    }

    function registerWebhookSensor(sensor as Lang.Object) {
        if (Globals.scDebug) {
            System.println("WebhookManager registerWebhookSensor(): Registering webhook sensor: " + sensor.toString());
        }
        Communications.makeWebRequest(
            Settings.getApiUrl() + "/webhook/" + Settings.getWebhookId(),
            {
                "type" => "register_sensor",
                "data" => sensor
            },
            {
                :method       => Communications.HTTP_REQUEST_METHOD_POST,
                :headers      => {
                    "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON
                },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onReturnRegisterWebhookSensor)
        );
    }
}
