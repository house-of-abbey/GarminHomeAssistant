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
// P A Abbey & J D Abbey & SomeoneOnEarth, 5 December 2023
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

    private var mApp                  as HomeAssistantApp;
    private var strFetchingMenuConfig as Lang.String;
    private var strExit               as Lang.String;
    private var mTextAreaExit         as WatchUi.TextArea or Null;
    private var mTextAreaFetching     as WatchUi.TextArea or Null; 

    function initialize(app as HomeAssistantApp) {
        ScalableView.initialize();
        mApp=app;

        strFetchingMenuConfig = WatchUi.loadResource($.Rez.Strings.FetchingMenuConfig);

        if (System.getDeviceSettings().isTouchScreen){
            strExit = WatchUi.loadResource($.Rez.Strings.ExitViewTouch);
        } else {
            strExit = WatchUi.loadResource($.Rez.Strings.ExitViewButtons);
        }
    }

    function onLayout(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        mTextAreaExit = new WatchUi.TextArea({
            :text          => strExit,
            :color         => Graphics.COLOR_WHITE,
            :font          => Graphics.FONT_XTINY,
            :justification => Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
            :locX          => 0,
            :locY          => 83,
            :width         => w,
            :height        => h - 166
        });

         mTextAreaFetching = new WatchUi.TextArea({
            :text              => strFetchingMenuConfig,
            :color             => Graphics.COLOR_WHITE,
            :font              => Graphics.FONT_XTINY,
            :justification     => Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
            :locX              => 0,
            :locY              => 83,
            :width             => w,
            :height            => h - 166
        });
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        if(dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        if(mApp.homeAssistantMenuIsLoaded()) {
            mTextAreaExit.draw(dc);
        } else {
            mTextAreaFetching.draw(dc);
        }
    }
}

class RootViewDelegate extends WatchUi.BehaviorDelegate {

    var mApp  as HomeAssistantApp;

    function initialize(app as HomeAssistantApp ) {
        BehaviorDelegate.initialize();
        mApp=app;
    }

    function onTap(evt as WatchUi.ClickEvent) as Lang.Boolean {
        return backToMainMenu();
    }

    function onSelect() as Lang.Boolean {
        return backToMainMenu();
    }

    function onMenu() as Lang.Boolean{
        return backToMainMenu();
    }

    private function backToMainMenu() as Lang.Boolean{
        if(mApp.homeAssistantMenuIsLoaded()){
            mApp.pushHomeAssistantMenuView();
            return true;
        }
        return false;
    }
}
