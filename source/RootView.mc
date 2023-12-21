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
// P A Abbey & J D Abbey & Someone0nEarth, 5 December 2023
//
//
// Description:
//
// Application root view for GarminHomeAssistant
//
//-----------------------------------------------------------------------------------

using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;

class RootView extends ScalableView {

    // ATTENTION when the app is running as a "widget" (that means, it runs on devices
    // without glance view support), the input events in this view are limited, as
    // described under "Base View and the Widget Carousel" on:
    //
    // https://developer.garmin.com/connect-iq/connect-iq-basics/app-types/
    //
    // Also the view type of the base view is limited too (for example "WatchUi.Menu2"
    // is not possible)).
    //
    // Also System.exit() is not working/do nothing when running as a widget: A widget will be
    // terminated automatically by OS after some time or can be quit manually, when on the base
    // view a swipe to left / "back button" press is done.

    private static const scMidSep = 10; // Middle Separator "text:_text" in pixels
    private var mApp        as HomeAssistantApp;
    private var mTitle      as WatchUi.Text or Null;
    private var mApiText    as WatchUi.Text or Null;
    private var mApiStatus  as WatchUi.Text or Null;
    private var mMenuText   as WatchUi.Text or Null;
    private var mMenuStatus as WatchUi.Text or Null;

    function initialize(app as HomeAssistantApp) {
        ScalableView.initialize();
        mApp = app;
    }

    function onLayout(dc as Graphics.Dc) as Void {
        var strChecking = WatchUi.loadResource($.Rez.Strings.Checking);
        var w           = dc.getWidth();

        mTitle = new WatchUi.Text({
            :text          => WatchUi.loadResource($.Rez.Strings.AppName),
            :color         => Graphics.COLOR_WHITE,
            :font          => Graphics.FONT_TINY,
            :justification => Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
            :locX          => w/2,
            :locY          => pixelsForScreen(30.0)
        });

        mApiText = new WatchUi.Text({
            :text          => "API:",
            :color         => Graphics.COLOR_WHITE,
            :font          => Graphics.FONT_XTINY,
            :justification => Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER,
            :locX          => w/2 - scMidSep/2,
            :locY          => pixelsForScreen(50.0)
        });
        mApiStatus = new WatchUi.Text({
            :text          => strChecking,
            :color         => Graphics.COLOR_WHITE,
            :font          => Graphics.FONT_XTINY,
            :justification => Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER,
            :locX          => w/2 + scMidSep/2,
            :locY          => pixelsForScreen(50.0)
        });
        mMenuText = new WatchUi.Text({
            :text          => WatchUi.loadResource($.Rez.Strings.GlanceMenu) + ":",
            :color         => Graphics.COLOR_WHITE,
            :font          => Graphics.FONT_XTINY,
            :justification => Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER,
            :locX          => w/2 - scMidSep/2,
            :locY          => pixelsForScreen(70.0)
        });
        mMenuStatus = new WatchUi.Text({
            :text          => strChecking,
            :color         => Graphics.COLOR_WHITE,
            :font          => Graphics.FONT_XTINY,
            :justification => Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER,
            :locX          => w/2 + scMidSep/2,
            :locY          => pixelsForScreen(70.0)
        });
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        // Initialise this locally, otherwise the venu1 device runs out of memory when stored at class level.
        var launcherIcon = Application.loadResource(Rez.Drawables.LauncherIcon);
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.drawBitmap(w/2 - launcherIcon.getWidth()/2, h/8 - launcherIcon.getHeight()/2, launcherIcon);
        mTitle.draw(dc);
        mApiText.draw(dc);
        mApiStatus.setText(mApp.getApiStatus());
        mApiStatus.draw(dc);
        mMenuText.draw(dc);
        mMenuStatus.setText(mApp.getMenuStatus());
        mMenuStatus.draw(dc);
    }
}

class RootViewDelegate extends WatchUi.BehaviorDelegate {

    var mApp as HomeAssistantApp;

    function initialize(app as HomeAssistantApp) {
        BehaviorDelegate.initialize();
        mApp = app;
    }

    function onTap(evt as WatchUi.ClickEvent) as Lang.Boolean {
        return backToMainMenu();
    }

    function onSelect() as Lang.Boolean {
        return backToMainMenu();
    }

    function onMenu() as Lang.Boolean {
        return backToMainMenu();
    }

    private function backToMainMenu() as Lang.Boolean {
        if (mApp.isHomeAssistantMenuLoaded()) {
            mApp.pushHomeAssistantMenuView();
            return true;
        }
        return false;
    }
}
