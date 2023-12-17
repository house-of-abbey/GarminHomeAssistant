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
// P A Abbey & J D Abbey & Someone0nEarth, 23 November 2023
//
//
// Description:
//
// Glance view for GarminHomeAssistant
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics;

(:glance)
class HomeAssistantGlanceView extends WatchUi.GlanceView {

    private var mText as Lang.String;

    function initialize() {
        GlanceView.initialize();

        mText = WatchUi.loadResource($.Rez.Strings.AppName);
    }

    function onUpdate(dc) as Void {
        GlanceView.onUpdate(dc);
      
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(0, dc.getHeight() / 2, Graphics.FONT_TINY, mText, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
