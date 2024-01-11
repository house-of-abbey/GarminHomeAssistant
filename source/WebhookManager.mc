using Toybox.Lang;
using Toybox.Communications;
using Toybox.System;

// Can use push view so must never be run in a glance context
class WebhookManager {
    function onReturnRequestWebhookId(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        switch (responseCode) {
            case Communications.BLE_HOST_TIMEOUT:
            case Communications.BLE_CONNECTION_UNAVAILABLE:
                if (Globals.scDebug) {
                    System.println("WebhookManager onReturnRequestWebhookId() Response Code: BLE_HOST_TIMEOUT or BLE_CONNECTION_UNAVAILABLE, Bluetooth connection severed.");
                }
                ErrorView.show(RezStrings.getWebhookFailed()+ "\n" + RezStrings.getNoPhone() + ".");
                break;

            case Communications.BLE_QUEUE_FULL:
                if (Globals.scDebug) {
                    System.println("WebhookManager onReturnRequestWebhookId() Response Code: BLE_QUEUE_FULL, API calls too rapid.");
                }
                ErrorView.show(RezStrings.getWebhookFailed()+ "\n" + RezStrings.getApiFlood());
                break;

            case Communications.NETWORK_REQUEST_TIMED_OUT:
                if (Globals.scDebug) {
                    System.println("WebhookManager onReturnRequestWebhookId() Response Code: NETWORK_REQUEST_TIMED_OUT, check Internet connection.");
                }
                ErrorView.show(RezStrings.getWebhookFailed()+ "\n" + RezStrings.getNoResponse());
                break;

            case Communications.NETWORK_RESPONSE_OUT_OF_MEMORY:
                if (Globals.scDebug) {
                    System.println("WebhookManager onReturnRequestWebhookId() Response Code: NETWORK_RESPONSE_OUT_OF_MEMORY, are we going too fast?");
                }
                // Ignore and see if we can carry on
                break;
            case Communications.INVALID_HTTP_BODY_IN_NETWORK_RESPONSE:
                if (Globals.scDebug) {
                    System.println("WebhookManager onReturnRequestWebhookId() Response Code: INVALID_HTTP_BODY_IN_NETWORK_RESPONSE, check JSON is returned.");
                }
                ErrorView.show(RezStrings.getWebhookFailed()+ "\n" + RezStrings.getNoJson());
                break;

            case 404:
                if (Globals.scDebug) {
                    System.println("WebhookManager onReturnRequestWebhookId() Response Code: 404, page not found. Check API URL setting.");
                }
                ErrorView.show(RezStrings.getWebhookFailed()+ "\n" + RezStrings.getApiUrlNotFound());
                break;

            case 201:
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
                } else {
                    if (Globals.scDebug) {
                        System.println("WebhookManager onReturnRequestWebhookId(): No webhook id in response data.");
                    }
                }
                break;

            default:
                if (Globals.scDebug) {
                    System.println("WebhookManager onReturnRequestWebhookId(): Unhandled HTTP response code = " + responseCode);
                }
                ErrorView.show(RezStrings.getWebhookFailed()+ "\n" + RezStrings.getUnhandledHttpErr() + responseCode);
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
