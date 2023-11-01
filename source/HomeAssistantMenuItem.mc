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
// P A Abbey & J D Abbey, 31 October 2023
//
//
// Description:
//
// Menu button that triggers a script.
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application.Properties;

class HomeAssistantMenuItem extends WatchUi.MenuItem {
    hidden var api_key = Properties.getValue("api_key");

    function initialize(
        label as Lang.String or Lang.Symbol,
        subLabel as Lang.String or Lang.Symbol or Null,
        identifier as Lang.Object or Null,
        options as {
            :alignment as WatchUi.MenuItem.Alignment,
            :icon      as Graphics.BitmapType or WatchUi.Drawable or Lang.Symbol
        } or Null
    ) {
        WatchUi.MenuItem.initialize(
            label,
            subLabel,
            identifier,
            options
        );
    }

    // Callback function after completing the POST request to call a script.
    //
    function onReturnExecScript(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        if (Globals.debug) {
            System.println("HomeAssistantToggleMenuItem onReturnGetState() Response Code: " + responseCode);
            System.println("HomeAssistantToggleMenuItem onReturnGetState() Response Data: " + data);
        }
        if (responseCode == 200) {
            var d = data as Lang.Array;
            for(var i = 0; i < d.size(); i++) {
                if ((d[i].get("entity_id") as Lang.String).equals(mIdentifier)) {
                    if (Globals.debug) {
                        System.println("HomeAssistantMenuItem Note - onReturnExecScript(): Correct script executed.");
                    }
                    new Alert({
                        :timeout => Globals.alertTimeout,
                        :font    => Graphics.FONT_SYSTEM_MEDIUM,
                        :text    => (d[i].get("attributes") as Lang.Dictionary).get("friendly_name"),
                        :fgcolor => Graphics.COLOR_WHITE,
                        :bgcolor => Graphics.COLOR_BLACK
                    }).pushView(WatchUi.SLIDE_IMMEDIATE);
                }
            }
        }
    }

    function execScript() as Void {
        var options = {
            :method  => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Authorization" => "Bearer " + api_key
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        if (System.getDeviceSettings().phoneConnected && System.getDeviceSettings().connectionAvailable) {
            var url = Properties.getValue("api_url") + "/services/" + mIdentifier.substring(0, mIdentifier.find(".")) + "/" + mIdentifier.substring(mIdentifier.find(".")+1, null);
            if (Globals.debug) {
                System.println("URL=" + url);
                System.println("mIdentifier=" + mIdentifier);
            }
            Communications.makeWebRequest(
                url,
                null,
                options,
                method(:onReturnExecScript)
            );
        } else {
            if (Globals.debug) {
                System.println("HomeAssistantMenuItem Note - executeScript(): No Internet connection, skipping API call.");
            }
            new Alert({
                :timeout => Globals.alertTimeout,
                :font    => Graphics.FONT_SYSTEM_MEDIUM,
                :text    => "No Internet connection",
                :fgcolor => Graphics.COLOR_RED,
                :bgcolor => Graphics.COLOR_BLACK
            }).pushView(WatchUi.SLIDE_IMMEDIATE);
        }
    }

}
