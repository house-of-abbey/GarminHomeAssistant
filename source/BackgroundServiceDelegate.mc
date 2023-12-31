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
        if (Globals.scDebug) {
            System.println("BackgroundServiceDelegate onReturnBatteryUpdate() Response Code: " + responseCode);
            System.println("BackgroundServiceDelegate onReturnBatteryUpdate() Response Data: " + data);
        }
        Background.exit(null);
    }

    function onTemporalEvent() as Void {
        if (! System.getDeviceSettings().phoneConnected) {
            if (Globals.scDebug) {
                System.println("BackgroundServiceDelegate onTemporalEvent(): No Phone connection, skipping API call.");
            }
        } else if (! System.getDeviceSettings().connectionAvailable) {
            if (Globals.scDebug) {
                System.println("BackgroundServiceDelegate onTemporalEvent(): No Internet connection, skipping API call.");
            }
        } else {
            // Don't use Settings.* here as the object lasts < 30 secs and is recreated each time the background service is run
            Communications.makeWebRequest(
                (Properties.getValue("api_url") as Lang.String) + "/events/garmin.battery_level",
                {
                    "level"       => System.getSystemStats().battery,
                    "is_charging" => System.getSystemStats().charging,
                    "device_id"   => System.getDeviceSettings().uniqueIdentifier
                },
                {
                    :method       => Communications.HTTP_REQUEST_METHOD_POST,
                    :headers      => {
                        "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON,
                        "Authorization" => "Bearer " + (Properties.getValue("api_key") as Lang.String)
                    },
                    :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
                },
                method(:onReturnBatteryUpdate)
            );
        }
    }

}
