import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class RootView extends WatchUi.View {

    var width,height;
    var mApp as HomeAssistantApp;

    function initialize(app as HomeAssistantApp) {
        View.initialize();
        mApp=app;
    }

    function onLayout(dc as Dc) as Void {
        width=dc.getWidth();
		height=dc.getHeight();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_BLACK);
		dc.clear();
		dc.setColor(Graphics.COLOR_BLUE,Graphics.COLOR_TRANSPARENT);
		if(mApp.homeAssistantMenuIsLoaded()) {
		    dc.drawText(width/2,height/2,Graphics.FONT_SMALL,"Hit Back to Exit\nTap to stay",Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);	
		} else {
            dc.drawText(width/2,height/2,Graphics.FONT_SMALL,"Loading...",Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
		}
    }
}

class RootViewDelegate extends WatchUi.BehaviorDelegate {

    var mApp  as HomeAssistantApp;

    function initialize(app as HomeAssistantApp ) {
        BehaviorDelegate.initialize();
        mApp=app;
    }

    public function onTap(evt as ClickEvent) as Boolean {
        return backToMainMenu();
    }

    public function onSelect() as Boolean {
        return backToMainMenu();
    }

    function onMenu(){
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
