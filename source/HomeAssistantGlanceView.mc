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
    private static const scLeftMargin =  5; // in pixels
    private static const scMidSep     = 10; // Middle Separator "text:_text" in pixels
    private var mApp        as HomeAssistantApp;
    private var mTitle      as WatchUi.Text or Null;
    private var mApiText    as WatchUi.Text or Null;
    private var mApiStatus  as WatchUi.Text or Null;
    private var mMenuText   as WatchUi.Text or Null;
    private var mMenuStatus as WatchUi.Text or Null;
    private var mAntiAlias  as Lang.Boolean = false;

    function initialize(app as HomeAssistantApp) {
        GlanceView.initialize();
        mApp = app;
        if (Graphics.Dc has :setAntiAlias) {
            mAntiAlias = true;
        }
    }

    function onLayout(dc as Graphics.Dc) as Void {
        var h  = dc.getHeight();
        var tw = dc.getTextWidthInPixels(WatchUi.loadResource($.Rez.Strings.GlanceMenu), Graphics.FONT_XTINY);

        mTitle = new WatchUi.Text({
            :text          => WatchUi.loadResource($.Rez.Strings.AppName),
            :color         => Graphics.COLOR_WHITE,
            :font          => Graphics.FONT_TINY,
            :justification => Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER,
            :locX          => scLeftMargin,
            :locY          => 1 * h / 6
        });

        mApiText = new WatchUi.Text({
            :text          => "API:",
            :color         => Graphics.COLOR_WHITE,
            :font          => Graphics.FONT_XTINY,
            :justification => Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER,
            :locX          => scLeftMargin,
            :locY          => 3 * h / 6
        });
        mApiStatus = new WatchUi.Text({
            :text          => WatchUi.loadResource($.Rez.Strings.Checking),
            :color         => Graphics.COLOR_WHITE,
            :font          => Graphics.FONT_XTINY,
            :justification => Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER,
            :locX          => scLeftMargin + scMidSep + tw,
            :locY          => 3 * h / 6
        });
        mMenuText = new WatchUi.Text({
            :text          => WatchUi.loadResource($.Rez.Strings.GlanceMenu) + ":",
            :color         => Graphics.COLOR_WHITE,
            :font          => Graphics.FONT_XTINY,
            :justification => Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER,
            :locX          => scLeftMargin,
            :locY          => 5 * h / 6
        });
        mMenuStatus = new WatchUi.Text({
            :text          => WatchUi.loadResource($.Rez.Strings.Checking),
            :color         => Graphics.COLOR_WHITE,
            :font          => Graphics.FONT_XTINY,
            :justification => Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER,
            :locX          => scLeftMargin + scMidSep + tw,
            :locY          => 5 * h / 6
        });
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        GlanceView.onUpdate(dc);
        if(mAntiAlias) {
            dc.setAntiAlias(true);
        }
        dc.setColor(
            Graphics.COLOR_WHITE,
            Graphics.COLOR_TRANSPARENT
        );
        dc.clear();
        mTitle.draw(dc);
        mApiText.draw(dc);
        mApiStatus.setText(mApp.getApiStatus());
        mApiStatus.draw(dc);
        mMenuText.draw(dc);
        mMenuStatus.setText(mApp.getMenuStatus());
        mMenuStatus.draw(dc);
    }
}
