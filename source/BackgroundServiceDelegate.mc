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
// The background service delegate currently just reports the Garmin watch's battery
// level.
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.Application.Properties;
using Toybox.Background;
using Toybox.System;

(:background)
class BackgroundServiceDelegate extends System.ServiceDelegate {

    function initialize() {
        ServiceDelegate.initialize();
    }

    function onReturnBatteryUpdate(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        // System.println("BackgroundServiceDelegate onReturnBatteryUpdate() Response Code: " + responseCode);
        // System.println("BackgroundServiceDelegate onReturnBatteryUpdate() Response Data: " + data);
        Background.exit(null);
    }

    function onTemporalEvent() as Void {
        if (!System.getDeviceSettings().phoneConnected) {
            // System.println("BackgroundServiceDelegate onTemporalEvent(): No Phone connection, skipping API call.");
        } else if (!System.getDeviceSettings().connectionAvailable) {
            // System.println("BackgroundServiceDelegate onTemporalEvent(): No Internet connection, skipping API call.");
        } else {
            // System.println("BackgroundServiceDelegate onTemporalEvent(): Making API call.");
            var position = Position.getInfo();
            // System.println("BackgroundServiceDelegate onTemporalEvent(): gps: " + position.position.toDegrees());
            // System.println("BackgroundServiceDelegate onTemporalEvent(): speed: " + position.speed);
            // System.println("BackgroundServiceDelegate onTemporalEvent(): course: " + position.heading + "rad (" + (position.heading * 180 / Math.PI) + "°)");
            // System.println("BackgroundServiceDelegate onTemporalEvent(): altitude: " + position.altitude);
            // System.println("BackgroundServiceDelegate onTemporalEvent(): battery: " + System.getSystemStats().battery);
            // System.println("BackgroundServiceDelegate onTemporalEvent(): charging: " + System.getSystemStats().charging);
            // System.println("BackgroundServiceDelegate onTemporalEvent(): activity: " + Activity.getProfileInfo().name);

            // Don't use Settings.* here as the object lasts < 30 secs and is recreated each time the background service is run

            if (position.accuracy != Position.QUALITY_NOT_AVAILABLE && position.accuracy != Position.QUALITY_LAST_KNOWN) {
                var accuracy = 0;
                switch (position.accuracy) {
                    case Position.QUALITY_POOR:
                        accuracy = 500;
                        break;
                    case Position.QUALITY_USABLE:
                        accuracy = 100;
                        break;
                    case Position.QUALITY_GOOD:
                        accuracy = 10;
                        break;
                }
                Communications.makeWebRequest(
                    (Properties.getValue("api_url") as Lang.String) + "/webhook/" + (Properties.getValue("webhook_id") as Lang.String),
                    {
                        "type" => "update_location",
                        "data" => {
                            "gps"          => position.position.toDegrees(),
                            "gps_accuracy" => accuracy,
                            "speed"        => Math.round(position.speed),
                            "course"       => Math.round(position.heading * 180 / Math.PI),
                            "altitude"     => Math.round(position.altitude),
                        }
                    },
                    {
                        :method       => Communications.HTTP_REQUEST_METHOD_POST,
                        :headers      => {
                            "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
                        },
                        :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
                    },
                    method(:onReturnBatteryUpdate)
                );
            }
            var data = [
                {
                    "state"     => System.getSystemStats().battery,
                    "type"      => "sensor",
                    "unique_id" => "battery_level"
                },
                {
                    "state"     => System.getSystemStats().charging,
                    "type"      => "binary_sensor",
                    "unique_id" => "battery_is_charging"
                }
            ];
            if ((Activity has :getActivityInfo) and (Activity has :getProfileInfo)) {
                var activity     = Activity.getProfileInfo().sport;
                var sub_activity = Activity.getProfileInfo().subSport;
                // We need to check if we are actually tracking any activity
                if (Activity.getActivityInfo().elapsedTime == 0) {
                    // Indicate no activity with -1, not part of Garmin's activity codes.
                    // https://developer.garmin.com/connect-iq/api-docs/Toybox/Activity.html#Sport-module
                    activity     = -1;
                    sub_activity = -1;
                }
                System.println("activity = " + activity);
                data.add({
                    "state"     => activity,
                    "type"      => "sensor",
                    "unique_id" => "activity"
                });
                data.add({
                    "state"     => sub_activity,
                    "type"      => "sensor",
                    "unique_id" => "sub_activity"
                });
            }
            Communications.makeWebRequest(
                (Properties.getValue("api_url") as Lang.String) + "/webhook/" + (Properties.getValue("webhook_id") as Lang.String),
                {
                    "type" => "update_sensor_states",
                    "data" => data
                },
                {
                    :method       => Communications.HTTP_REQUEST_METHOD_POST,
                    :headers      => {
                        "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
                    },
                    :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
                },
                method(:onReturnBatteryUpdate)
            );
        }
    }

}
