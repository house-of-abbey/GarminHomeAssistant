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
// Home Assistant menu construction.
//
//-----------------------------------------------------------------------------------

using Toybox.Application;
using Toybox.Lang;
using Toybox.Graphics;
using Toybox.System;
using Toybox.WatchUi;

class HomeAssistantView extends WatchUi.Menu2 {
    // List of items that need to have their status updated periodically
    private var mListToggleItems   = [];
    private var mListMenuItems     = [];

    function initialize(
        definition as Lang.Dictionary,
        options as {
            :focus as Lang.Number,
            :icon  as Graphics.BitmapType or WatchUi.Drawable or Lang.Symbol,
            :theme as WatchUi.MenuTheme or Null
        } or Null
    ) {

        if (options == null) {
            options = {
                :title => definition.get("title") as Lang.String
            };
        } else {
            options.put(:title, definition.get("title") as Lang.String);
        }
        WatchUi.Menu2.initialize(options);

        var items = definition.get("items") as Lang.Dictionary;
        for(var i = 0; i < items.size(); i++) {
            var type       = items[i].get("type")       as Lang.String or Null;
            var name       = items[i].get("name")       as Lang.String or Null;
            var entity     = items[i].get("entity")     as Lang.String or Null;
            var tap_action = items[i].get("tap_action") as Lang.Dictionary or Null;
            var service    = items[i].get("service")    as Lang.String or Null;
            var confirm    = false                      as Lang.Boolean;
            if (tap_action != null) {
                service = tap_action.get("service");
                confirm = tap_action.get("confirm");
                if (confirm == null) {
                    confirm = false;
                }
            }
            if (type != null && name != null && entity != null) {
                if (type.equals("toggle")) {
                    var item = HomeAssistantMenuItemFactory.create().toggle(name, entity);
                    addItem(item);
                    mListToggleItems.add(item);
                } else if (type.equals("tap") && service != null) {
                    addItem(HomeAssistantMenuItemFactory.create().tap(name, entity, service, confirm));
                } else if (type.equals("group")) {
                    var item = HomeAssistantMenuItemFactory.create().group(items[i]);
                    addItem(item);
                    mListMenuItems.add(item);
                }
            }
        }
    }

    function getItemsToUpdate() as Lang.Array<HomeAssistantToggleMenuItem> {
        var fullList = [];
        
        var lmi = mListMenuItems as Lang.Array<WatchUi.MenuItem>;
        for(var i = 0; i < mListMenuItems.size(); i++) {
            var item = lmi[i];
            if (item instanceof HomeAssistantViewMenuItem || item instanceof HomeAssistantViewIconMenuItem) {
                fullList.addAll(item.getMenuView().getItemsToUpdate()); 
            }
        }

        return fullList.addAll(mListToggleItems);
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {}

}

//
// Reference: https://developer.garmin.com/connect-iq/core-topics/input-handling/
//
class HomeAssistantViewDelegate extends WatchUi.Menu2InputDelegate {

    private var mIsRootMenuView = false;

    function initialize(isRootMenuView as Lang.Boolean) {
        Menu2InputDelegate.initialize();
        mIsRootMenuView = isRootMenuView;
    }

    function onBack() {
        getApp().getQuitTimer().reset();

        if (mIsRootMenuView){
            // If its started from glance or as an activity, directly exit the widget/app
            // (on widgets without glance, this exit() won`t do anything,
            // so the base view will be shown instead, through the popView below this "if body")
            System.exit();
        } 

        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    // Only for CheckboxMenu
    function onDone() {
        getApp().getQuitTimer().reset();
    }

    // Only for CustomMenu
    function onFooter() {
        getApp().getQuitTimer().reset();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        getApp().getQuitTimer().reset();
        if (item instanceof HomeAssistantToggleMenuItem) {
            var haToggleItem = item as HomeAssistantToggleMenuItem;
            if (Globals.scDebug) {
                System.println(haToggleItem.getLabel() + " " + haToggleItem.getId() + " " + haToggleItem.isEnabled());
            }
            haToggleItem.setState(haToggleItem.isEnabled());
        } else if (item instanceof HomeAssistantMenuItem) {
            var haItem = item as HomeAssistantMenuItem;
            if (Globals.scDebug) {
                System.println(haItem.getLabel() + " " + haItem.getId());
            }
            haItem.callService();
        } else if (item instanceof HomeAssistantIconMenuItem) {
            var haItem = item as HomeAssistantIconMenuItem;
            if (Globals.scDebug) {
                System.println(haItem.getLabel() + " " + haItem.getId());
            }
            haItem.callService();
        } else if (item instanceof HomeAssistantViewMenuItem) {
            var haMenuItem = item as HomeAssistantViewMenuItem;
            if (Globals.scDebug) {
                System.println("Menu: " + haMenuItem.getLabel() + " " + haMenuItem.getId());
            }
            WatchUi.pushView(haMenuItem.getMenuView(), new HomeAssistantViewDelegate(false), WatchUi.SLIDE_LEFT);
        } else if (item instanceof HomeAssistantViewIconMenuItem) {
            var haMenuItem = item as HomeAssistantViewIconMenuItem;
            if (Globals.scDebug) {
                System.println("IconMenu: " + haMenuItem.getLabel() + " " + haMenuItem.getId());
            }
            WatchUi.pushView(haMenuItem.getMenuView(), new HomeAssistantViewDelegate(false), WatchUi.SLIDE_LEFT);
        } else {
            if (Globals.scDebug) {
                System.println(item.getLabel() + " " + item.getId());
            }
        }
    }

    // Only for CustomMenu
    function onTitle() {
        getApp().getQuitTimer().reset();
    }

}
