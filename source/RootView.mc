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

class RootView extends WatchUi.View {

    var width,height;
    var mApp                  as HomeAssistantApp;
    var strFetchingMenuConfig as Lang.String;
    var strExitView           as Lang.String;

    function initialize(app as HomeAssistantApp) {
        View.initialize();
        mApp=app;

        strFetchingMenuConfig = WatchUi.loadResource($.Rez.Strings.FetchingMenuConfig);

        if (System.getDeviceSettings().isTouchScreen){
            strExitView = WatchUi.loadResource($.Rez.Strings.ExitViewTouch);
        } else {
            strExitView = WatchUi.loadResource($.Rez.Strings.ExitViewButtons);
        }
    }

    function onLayout(dc as Graphics.Dc) as Void {
        width=dc.getWidth();
		height=dc.getHeight();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_BLACK);
		dc.clear();
		dc.setColor(Graphics.COLOR_BLUE,Graphics.COLOR_TRANSPARENT);
		if(mApp.homeAssistantMenuIsLoaded()) {
		    dc.drawText(width/2,height/2,Graphics.FONT_SMALL,strExitView,Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);	
		} else {
            dc.drawText(width/2,height/2,Graphics.FONT_SMALL,strFetchingMenuConfig,Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
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
