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
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.Application.Properties;
using Toybox.Background;
using Toybox.System;
using Toybox.Activity;

//! The background service delegate reports the Garmin watch's various status values
//! back to the Home Assistant instance.
//
(:background)
class BackgroundServiceDelegate extends System.ServiceDelegate {

    //! Class Constructor
    //
    function initialize() {
        ServiceDelegate.initialize();
    }

    //! Callback function for doUpdate().
    //!
    //! @param responseCode Response code
    //! @param data         Return data
    //
    function onReturnDoUpdate(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        // System.println("BackgroundServiceDelegate onReturnDoUpdate() Response Code: " + responseCode);
        // System.println("BackgroundServiceDelegate onReturnDoUpdate() Response Data: " + data);
        Background.exit(null);
    }

    //! Called on completion of an activity.
    //!
    //! @param activity Specified as a Dictionary with two items.<br>
    //!   `{`<br>
    //!   &emsp; `:sport    as Activity.Sport`<br>
    //!   &emsp; `:subSport as Activity.SubSport`<br>
    //!   `}`
    //
    function onActivityCompleted(
        activity as {
            :sport    as Activity.Sport,
            :subSport as Activity.SubSport
        }
    ) as Void {
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

    //! Called periodically to send status updates to the Home Assistant instance.
    //
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

    //! Combined update function to collect the data to be sent as updates to the Home Assistant instance.
    //!
    //! @param activity     Activity.Sport
    //! @param sub_activity Activity.SubSport
    //
    private function doUpdate(
        activity     as Lang.Number?,
        sub_activity as Lang.Number?
    ) {
        // System.println("BackgroundServiceDelegate onTemporalEvent(): Making API call.");
        var position = Position.getInfo();
        // System.println("BackgroundServiceDelegate onTemporalEvent(): GPS      : " + position.position.toDegrees());
        // System.println("BackgroundServiceDelegate onTemporalEvent(): Speed    : " + position.speed);
        // System.println("BackgroundServiceDelegate onTemporalEvent(): Course   : " + position.heading + " radians (" + (position.heading * 180 / Math.PI) + "°)");
        // System.println("BackgroundServiceDelegate onTemporalEvent(): Altitude : " + position.altitude);
        // System.println("BackgroundServiceDelegate onTemporalEvent(): Battery  : " + System.getSystemStats().battery);
        // System.println("BackgroundServiceDelegate onTemporalEvent(): Charging : " + System.getSystemStats().charging);
        // System.println("BackgroundServiceDelegate onTemporalEvent(): Activity : " + Activity.getProfileInfo().name);

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

            var data = { "gps_accuracy" => accuracy };
            // Only add the non-null fields as all the values are optional in Home Assistant, and it avoid submitting fake values.
            if (position.position != null) {
                data.put("gps", position.position.toDegrees());
            }
            if (position.speed != null) {
                data.put("speed", Math.round(position.speed));
            }
            if (position.heading != null) {
                var heading = Math.round(position.heading * 180 / Math.PI);
                while (heading < 0) {
                    heading += 360;
                }
                data.put("course", heading);
            }
            if (position.altitude != null) {
                data.put("altitude", Math.round(position.altitude));
            }
            // System.println("BackgroundServiceDelegate onTemporalEvent(): data = " + data.toString());

            Communications.makeWebRequest(
                (Properties.getValue("api_url") as Lang.String) + "/webhook/" + (Properties.getValue("webhook_id") as Lang.String),
                {
                    "type" => "update_location",
                    "data" => data
                },
                {
                    :method       => Communications.HTTP_REQUEST_METHOD_POST,
                    :headers      => Settings.augmentHttpHeaders({
                        "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
                    }),
                    :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
                },
                method(:onReturnDoUpdate)
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
            }
        ];

        if (ActivityMonitor.Info has :floorsClimbed) {
            data.add({
                "state"     => activityInfo.floorsClimbed == null ? "unknown" : activityInfo.floorsClimbed,
                "type"      => "sensor",
                "unique_id" => "floors_climbed_today",
                "icon"      => "mdi:stairs-up"
            });
        }

        if (ActivityMonitor.Info has :floorsDescended) {
            data.add({
                "state"     => activityInfo.floorsDescended == null ? "unknown" : activityInfo.floorsDescended,
                "type"      => "sensor",
                "unique_id" => "floors_descended_today",
                "icon"      => "mdi:stairs-down"
            });
        }

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
                :headers      => Settings.augmentHttpHeaders({
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
                }),
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onReturnDoUpdate)
        );
    }

}
