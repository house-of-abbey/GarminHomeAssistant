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
using Toybox.Activity;

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

    function onActivityCompleted(activity as { :sport as Activity.Sport, :subSport as Activity.SubSport }) as Void {
        if (!System.getDeviceSettings().phoneConnected) {
            // System.println("BackgroundServiceDelegate onActivityCompleted(): No Phone connection, skipping API call.");
        } else if (!System.getDeviceSettings().connectionAvailable) {
            // System.println("BackgroundServiceDelegate onActivityCompleted(): No Internet connection, skipping API call.");
        } else {
            // Ensure we're logging completion, i.e. ignore 'activity' parameter
            // System.println("BackgroundServiceDelegate onActivityCompleted(): Event triggered");
            doUpdate(-1, -1);
        }
    }

    function onTemporalEvent() as Void {
        if (!System.getDeviceSettings().phoneConnected) {
            // System.println("BackgroundServiceDelegate onTemporalEvent(): No Phone connection, skipping API call.");
        } else if (!System.getDeviceSettings().connectionAvailable) {
            // System.println("BackgroundServiceDelegate onTemporalEvent(): No Internet connection, skipping API call.");
        } else {
            var activity     = null;
            var sub_activity = null;
            if ((Activity has :getActivityInfo) and (Activity has :getProfileInfo)) {
                activity     = Activity.getProfileInfo().sport;
                sub_activity = Activity.getProfileInfo().subSport;
                // We need to check if we are actually tracking any activity as the enumerated type does not include "No Sport".
                if ((Activity.getActivityInfo() != null) and
                    ((Activity.getActivityInfo().elapsedTime == null) or
                        (Activity.getActivityInfo().elapsedTime == 0))) {
                    // Indicate no activity with -1, not part of Garmin's activity codes.
                    // https://developer.garmin.com/connect-iq/api-docs/Toybox/Activity.html#Sport-module
                    activity     = -1;
                    sub_activity = -1;
                }
            }
            // System.println("BackgroundServiceDelegate onTemporalEvent(): Event triggered, activity = " + activity + " sub_activity = " + sub_activity);
            doUpdate(activity, sub_activity);
        }
    }

    private function doUpdate(activity as Lang.Number or Null, sub_activity as Lang.Number or Null) {
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
        var activityInfo = ActivityMonitor.getInfo();
        var heartRate = Activity.getActivityInfo().currentHeartRate;
        var data = [
            {
                "state"     => System.getSystemStats().battery,
                "type"      => "sensor",
                "unique_id" => "battery_level",
                "icon"      => "mdi:battery"
            },
            {
                "state"     => System.getSystemStats().charging,
                "type"      => "binary_sensor",
                "unique_id" => "battery_is_charging",
                "icon"      => System.getSystemStats().charging ? "mdi:battery-plus" : "mdi:battery-minus"
            },
            {
                "state"     => activityInfo.steps == null ? "unknown" : activityInfo.steps,
                "type"      => "sensor",
                "unique_id" => "steps_today",
                "icon"      => "mdi:walk"
            },
            {
                "state"     => heartRate == null ? "unknown" : heartRate,
                "type"      => "sensor",
                "unique_id" => "heart_rate",
                "icon"      => "mdi:heart-pulse"
            },
            {
                "state"     => activityInfo.floorsClimbed == null ? "unknown" : activityInfo.floorsClimbed,
                "type"      => "sensor",
                "unique_id" => "floors_climbed_today",
                "icon"      => "mdi:stairs-up"
            },
            {
                "state"     => activityInfo.floorsDescended == null ? "unknown" : activityInfo.floorsDescended,
                "type"      => "sensor",
                "unique_id" => "floors_descended_today",
                "icon"      => "mdi:stairs-down"
            }
        ];

        if (ActivityMonitor.Info has :respirationRate) {
            data.add({
                "state"     => activityInfo.respirationRate == null ? "unknown" : activityInfo.respirationRate,
                "type"      => "sensor",
                "unique_id" => "respiration_rate",
                "icon"      => "mdi:lungs"
            });
        }

        if (activity != null) {
            data.add({
                "state"     => activity,
                "type"      => "sensor",
                "unique_id" => "activity"
            });
        }
        if (sub_activity != null) {
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
