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
// Home Assistant menu construction.
//
//-----------------------------------------------------------------------------------

using Toybox.Application;
using Toybox.Lang;
using Toybox.Graphics;
using Toybox.System;
using Toybox.WatchUi;

class HomeAssistantView extends WatchUi.Menu2 {

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
            var type       = items[i].get("type")       as Lang.String     or Null;
            var name       = items[i].get("name")       as Lang.String     or Null;
            var content    = items[i].get("content")    as Lang.String     or Null;
            var entity     = items[i].get("entity")     as Lang.String     or Null;
            var tap_action = items[i].get("tap_action") as Lang.Dictionary or Null;
            var service    = items[i].get("service")    as Lang.String     or Null; // Deprecated schema
            var confirm    = false                      as Lang.Boolean    or Null;
            var data       = null                       as Lang.Dictionary or Null;
            if (tap_action != null) {
                service = tap_action.get("service");
                confirm = tap_action.get("confirm"); // Optional
                data    = tap_action.get("data");    // Optional
                if (confirm == null) {
                    confirm = false;
                }
            }
            if (type != null && name != null) {
                if (type.equals("toggle") && entity != null) {
                    addItem(HomeAssistantMenuItemFactory.create().toggle(name, entity));
                } else if (type.equals("template") && content != null) {
                    if (tap_action == null) {
                        addItem(HomeAssistantMenuItemFactory.create().template_notap(name, entity, content, service, confirm, data));
                    } else {
                        addItem(HomeAssistantMenuItemFactory.create().template_tap(name, entity, content, service, confirm, data));
                    }

                } else if (type.equals("tap") && entity != null && service != null) {
                    addItem(HomeAssistantMenuItemFactory.create().tap(name, entity, service, confirm, data));
                } else if (type.equals("group")) {
                    addItem(HomeAssistantMenuItemFactory.create().group(items[i]));
                }
            }
        }
    }

    function getItemsToUpdate() as Lang.Array<HomeAssistantToggleMenuItem or HomeAssistantTemplateMenuItem> {
        var fullList = [];

        var lmi = mItems as Lang.Array<WatchUi.MenuItem>;
        for(var i = 0; i < mItems.size(); i++) {
            var item = lmi[i];
            if (item instanceof HomeAssistantGroupMenuItem) {
                fullList.addAll(item.getMenuView().getItemsToUpdate());
            } else if (item instanceof HomeAssistantToggleMenuItem) {
                fullList.add(item);
            } else if (item instanceof HomeAssistantTemplateMenuItem) {
                fullList.add(item);
            }
        }

        return fullList;
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
    private var mIsRootMenuView as Lang.Boolean = false;
    private var mTimer          as QuitTimer;

    function initialize(isRootMenuView as Lang.Boolean) {
        Menu2InputDelegate.initialize();
        mIsRootMenuView = isRootMenuView;
        mTimer          = getApp().getQuitTimer();
    }

    function onBack() {
        mTimer.reset();

        if (mIsRootMenuView) {
            // If its started from glance or as an activity, directly exit the widget/app
            // (on widgets without glance, this exit() won't do anything,
            // so the base view will be shown instead, through the popView below this "if body")
            System.exit();
        }

        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    // Only for CheckboxMenu
    function onDone() {
        mTimer.reset();
    }

    // Only for CustomMenu
    function onFooter() {
        mTimer.reset();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        mTimer.reset();
        if (item instanceof HomeAssistantToggleMenuItem) {
            var haToggleItem = item as HomeAssistantToggleMenuItem;
            if (Globals.scDebug) {
                System.println(haToggleItem.getLabel() + " " + haToggleItem.getId() + " " + haToggleItem.isEnabled());
            }
            haToggleItem.setState(haToggleItem.isEnabled());
        } else if (item instanceof HomeAssistantTapMenuItem) {
            var haItem = item as HomeAssistantTapMenuItem;
            if (Globals.scDebug) {
                System.println(haItem.getLabel() + " " + haItem.getId());
            }
            haItem.callService();
        } else if (item instanceof HomeAssistantTemplateMenuItem) {
            var haItem = item as HomeAssistantTemplateMenuItem;
            if (Globals.scDebug) {
                System.println(haItem.getLabel() + " " + haItem.getId());
            }
            haItem.callService();
        } else if (item instanceof HomeAssistantGroupMenuItem) {
            var haMenuItem = item as HomeAssistantGroupMenuItem;
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
        mTimer.reset();
    }

}
