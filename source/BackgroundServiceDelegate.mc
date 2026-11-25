//-----------------------------------------------------------------------------------
//
// Distributed under MIT Licence
//   See https://github.com/house-of-abbey/GarminHomeAssistant/blob/main/LICENSE
//
//-----------------------------------------------------------------------------------
//
// GarminHomeAssistant is a Garmin IQ application written in Monkey C and routinely
// tested on a Venu 2 device. The source code is provided at:
//            https://github.com/house-of-abbey/GarminHomeAssistant
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

    //! Requests still to send in this background run, each [type, data]. They go out one after
    //! another: Background.exit() ends the run, so no request may still be pending then.
    private var mQueue as Lang.Array<Lang.Array> = [] as Lang.Array<Lang.Array>;
    //! The request in flight, sent again after a Bluetooth error.
    private var mCurrent as Lang.Array or Null = null;
    private var mRetries as Lang.Number = 0;
    //! A background run's first request can be refused at once with a Bluetooth error (Edge 850,
    //! firmware 33.22: -102 BLE_REQUEST_TOO_LARGE for ~200 bytes, every run); sent again right
    //! away it goes through.
    private const MAX_RETRIES = 2;

    //! Class Constructor
    //
    function initialize() {
        ServiceDelegate.initialize();
    }

    //! Callback for every queued request: after a Bluetooth error (-1 to -104) the same request
    //! again, otherwise the next one, and after the last the run ends.
    //!
    //! @param responseCode Response code
    //! @param data         Return data
    //
    function onReturnQueued(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        // System.println("BackgroundServiceDelegate onReturnQueued() Response Code: " + responseCode);
        if (responseCode <= -1 and responseCode >= -104 and mCurrent != null and mRetries < MAX_RETRIES) {
            mRetries++;
            send(mCurrent);
        } else {
            sendNext();
        }
    }

    //! Send the next queued request, or end the background run when none is left.
    //
    private function sendNext() as Void {
        if (mQueue.size() == 0) {
            mCurrent = null;
            Background.exit(null);
            return;
        }
        mCurrent = mQueue[0];
        mQueue   = mQueue.slice(1, null);
        mRetries = 0;
        send(mCurrent);
    }

    //! Send one queued request.
    //!
    //! @param request [type, data]
    //
    private function send(request as Lang.Array) as Void {
        post(request[0] as Lang.String, request[1] as Lang.Dictionary or Lang.Array, method(:onReturnQueued));
    }

    //! POST one webhook request.
    //!
    //! @param type     Webhook request type, e.g. "update_sensor_states"
    //! @param data     The request's "data"
    //! @param callback Called with the answer
    //
    private function post(
        type     as Lang.String,
        data     as Lang.Dictionary or Lang.Array,
        callback as Lang.Method
    ) as Void {
        Communications.makeWebRequest(
            (Properties.getValue("api_url") as Lang.String) + "/webhook/" + (Properties.getValue("webhook_id") as Lang.String),
            {
                "type" => type,
                "data" => data
            },
            {
                :method       => Communications.HTTP_REQUEST_METHOD_POST,
                :headers      => Settings.augmentHttpHeaders({
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
                }),
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            callback
        );
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
        var location = null;
        if (position.accuracy != Position.QUALITY_NOT_AVAILABLE) {
            var accuracy = 0;
            switch (position.accuracy) {
                case Position.QUALITY_LAST_KNOWN:
                    // Location is no longer tied to the timestamp, hence the larger inaccuracy.
                    accuracy = 200;
                    break;
                case Position.QUALITY_POOR:
                    accuracy = 100;
                    break;
                case Position.QUALITY_USABLE:
                    accuracy = 50;
                    break;
                case Position.QUALITY_GOOD:
                    accuracy = 10;
                    break;
            }

            var data = { "gps_accuracy" => accuracy };
            // Only add the non-null fields as all the values are optional in Home Assistant, and it avoid submitting fake values.
            if (position.position != null) {
                data["gps"] = position.position.toDegrees();
            }
            if (position.speed != null) {
                data["speed"] = Math.round(position.speed);
            }
            if (position.heading != null) {
                var heading = Math.round(position.heading * 180 / Math.PI);
                while (heading < 0) {
                    heading += 360;
                }
                data["course"] = heading;
            }
            if (position.altitude != null) {
                data["altitude"] = Math.round(position.altitude);
            }
            // System.println("BackgroundServiceDelegate onTemporalEvent(): data = " + data.toString());
            location = data;
        }
        // Devices without all-day tracking (e.g. Edge bike computers) have no ActivityMonitor, and
        // getActivityInfo() can be null; as in WebhookManager.registerWebhookSensors().
        var info      = Activity.getActivityInfo();
        var heartRate = (info != null) ? info.currentHeartRate : null;
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
                "state"     => heartRate == null ? "unknown" : heartRate,
                "type"      => "sensor",
                "unique_id" => "heart_rate",
                "icon"      => "mdi:heart-pulse"
            }
        ];

        if (Toybox has :ActivityMonitor) {
            var activityInfo = ActivityMonitor.getInfo();
            data.add({
                "state"     => activityInfo.steps == null ? "unknown" : activityInfo.steps,
                "type"      => "sensor",
                "unique_id" => "steps_today",
                "icon"      => "mdi:walk"
            });

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
        // The sensor states (with the battery) first, then the location.
        mQueue = [["update_sensor_states", data]] as Lang.Array<Lang.Array>;
        if (location != null) {
            mQueue.add(["update_location", location]);
        }
        sendNext();
    }

}
