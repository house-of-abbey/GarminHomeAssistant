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

using Toybox.Lang;
using Toybox.Graphics;
using Toybox.WatchUi;

class HomeAssistantView extends WatchUi.Menu2 {
    hidden var strMenuItemTap as Lang.String;
    // List of items that need to have their status updated periodically
    hidden var mListToggleItems = [];
    hidden var mListMenuItems   = [];

    function initialize(
        definition as Lang.Dictionary,
        options as {
            :focus as Lang.Number,
            :icon  as Graphics.BitmapType or WatchUi.Drawable or Lang.Symbol,
            :theme as WatchUi.MenuTheme or Null
        } or Null
    ) {
        strMenuItemTap = WatchUi.loadResource($.Rez.Strings.MenuItemTap);
        var toggle_obj = {
            :enabled  => WatchUi.loadResource($.Rez.Strings.MenuItemOn) as Lang.String,
            :disabled => WatchUi.loadResource($.Rez.Strings.MenuItemOff) as Lang.String
        };

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
            var type    = items[i].get("type")    as Lang.String or Null;
            var name    = items[i].get("name")    as Lang.String or Null;
            var entity  = items[i].get("entity")  as Lang.String or Null;
            var service = items[i].get("service") as Lang.String or Null;
            if (type != null && name != null && entity != null) {
                if (type.equals("toggle")) {
                    var item = new HomeAssistantToggleMenuItem(
                        name,
                        toggle_obj,
                        entity,
                        false,
                        null
                    );
                    addItem(item);
                    mListToggleItems.add(item);
                } else if (type.equals("tap") && service != null) {
                    addItem(
                        new HomeAssistantMenuItem(
                            name,
                            strMenuItemTap,
                            entity,
                            service,
                            null
                        )
                    );
                } else if (type.equals("group")) {
                    var item = new HomeAssistantViewMenuItem(items[i]);
                    addItem(item);
                    mListMenuItems.add(item);
                }
            }
        }
    }

    function getItemsToUpdate() as Lang.Array<HomeAssistantToggleMenuItem> {
        var fullList = [];
        var lmi = mListMenuItems as Lang.Array<HomeAssistantViewMenuItem>;
        for(var i = 0; i < lmi.size(); i++) {
            fullList.addAll(lmi[i].getMenuView().getItemsToUpdate());
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

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
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
            haItem.execScript();
        } else if (item instanceof HomeAssistantViewMenuItem) {
            var haMenuItem = item as HomeAssistantViewMenuItem;
            if (Globals.scDebug) {
                System.println("Menu: " + haMenuItem.getLabel() + " " + haMenuItem.getId());
            }
            // No delegate state to be amended, so re-use 'self'.
            WatchUi.pushView(haMenuItem.getMenuView(), self, WatchUi.SLIDE_LEFT);
        } else {
            if (Globals.scDebug) {
                System.println(item.getLabel() + " " + item.getId());
            }
        }
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

}