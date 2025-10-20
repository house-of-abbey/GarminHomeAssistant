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
// P A Abbey & J D Abbey & Someone0nEarth & moesterheld, 31 October 2023
//
//-----------------------------------------------------------------------------------

using Toybox.Application;
using Toybox.Lang;
using Toybox.Graphics;
using Toybox.System;
using Toybox.WatchUi;

//! Home Assistant menu construction.
//
class HomeAssistantView extends WatchUi.Menu2 {

    //! Class Constructor
    //
    function initialize(
        definition as Lang.Dictionary,
        options as {
            :focus as Lang.Number,
            :icon  as Graphics.BitmapType or WatchUi.Drawable or Lang.Symbol
        }?
    ) {
        if (options == null) {
            options = { :title => definition.get("title") as Lang.String };
        } else {
            options[:title] = definition.get("title") as Lang.String;
        }
        WatchUi.Menu2.initialize(options);

        var items = definition.get("items") as Lang.Array<Lang.Dictionary>;
        for (var i = 0; i < items.size(); i++) {
            if (items[i] instanceof(Lang.Dictionary)) {
                var type       = items[i].get("type")       as Lang.String?;
                var name       = items[i].get("name")       as Lang.String?;
                var content    = items[i].get("content")    as Lang.String?;
                var entity     = items[i].get("entity")     as Lang.String?;
                var tap_action = items[i].get("tap_action") as Lang.Dictionary?;
                var action    = items[i].get("service")    as Lang.String?; // Deprecated schema
                var confirm    = false                      as Lang.Boolean?;
                var pin        = false                      as Lang.Boolean?;
                var data       = null                       as Lang.Dictionary?;
                var enabled    = true                       as Lang.Boolean?;
                var exit       = false                      as Lang.Boolean?;
                if (items[i].get("enabled") != null) {
                    enabled = items[i].get("enabled");       // Optional
                }
                if (items[i].get("exit") != null) {
                    exit = items[i].get("exit");             // Optional
                }
                if (tap_action != null) {
                    action = tap_action.get("service");      // Deprecated
                    if (tap_action.get("action") != null) {
                        action = tap_action.get("action");   // Optional
                    }
                    data    = tap_action.get("data");        // Optional
                    if (tap_action.get("confirm") != null) {
                        confirm = tap_action.get("confirm"); // Optional
                    }
                    if (tap_action.get("pin") != null) {
                        pin = tap_action.get("pin");         // Optional
                    }
                }
                if (type != null && name != null && enabled) {
                    if (type.equals("toggle") && entity != null) {
                        addItem(HomeAssistantMenuItemFactory.create().toggle(
                            name,
                            entity,
                            content,
                            {
                                :exit    => exit,
                                :confirm => confirm,
                                :pin     => pin
                            }
                        ));
                    } else if (type.equals("tap") && action != null) {
                        addItem(HomeAssistantMenuItemFactory.create().tap(
                            name,
                            entity,
                            content,
                            action,
                            data,
                            {
                                :exit    => exit,
                                :confirm => confirm,
                                :pin     => pin
                            }
                        ));
                    } else if (type.equals("template") && content != null) {
                        // NB. "template" is deprecated in the schema and remains only for backward compatibility. All menu items can now use templates, so the replacement is "info".
                        // The exit option is dependent on the type of template.
                        if (tap_action == null) {
                            // No exit from an information only item
                            addItem(HomeAssistantMenuItemFactory.create().tap(
                                name,
                                entity,
                                content,
                                action,
                                data,
                                {
                                    :exit    => false,
                                    :confirm => confirm,
                                    :pin     => pin
                                }
                            ));
                        } else {
                            // You may exit from template item with a 'tap_action'.
                            addItem(HomeAssistantMenuItemFactory.create().tap(
                                name,
                                entity,
                                content,
                                action,
                                data,
                                {
                                    :exit    => exit,
                                    :confirm => confirm,
                                    :pin     => pin
                                }
                            ));
                        }
                    } else if (type.equals("numeric") && action != null) {
                        if (tap_action != null) {
                            var picker = tap_action.get("picker") as Lang.Dictionary?;
                            if (picker != null) {
                                addItem(HomeAssistantMenuItemFactory.create().numeric(
                                    name,
                                    entity,
                                    content,
                                    action,
                                    picker,
                                    {
                                        :exit    => exit,
                                        :confirm => confirm,
                                        :pin     => pin
                                    }
                                ));
                            }
                        }
                    } else if (type.equals("info") && content != null) {
                        // Cannot exit from a non-actionable information only menu item.
                        addItem(HomeAssistantMenuItemFactory.create().tap(
                            name,
                            entity,
                            content,
                            action,
                            data,
                            {
                                :exit    => false,
                                :confirm => confirm,
                                :pin     => pin
                            }
                        ));
                    } else if (type.equals("group")) {
                        addItem(HomeAssistantMenuItemFactory.create().group(items[i], content));
                    }
                }
            }
        }
    }

    //! Return a list of items that need to be updated within this menu structure.
    //!
    //! MN. Lang.Array.addAll() fails structural type checking without including "Null" in the return type
    //!
    //! @return An array of menu items that need to be updated periodically to reflect the latest Home Assistant state.
    //
    function getItemsToUpdate() as Lang.Array<HomeAssistantToggleMenuItem or HomeAssistantTapMenuItem or HomeAssistantGroupMenuItem  or HomeAssistantNumericMenuItem or Null> {
        var fullList = [];
        var lmi = mItems as Lang.Array<WatchUi.MenuItem>;

        for(var i = 0; i < mItems.size(); i++) {
            var item = lmi[i];
            if (item instanceof HomeAssistantGroupMenuItem) {
                // Group menu items can now have an optional template to evaluate
                var gmi = item as HomeAssistantGroupMenuItem;
                if (gmi.hasTemplate()) {
                    fullList.add(item);
                }
                fullList.addAll(item.getMenuView().getItemsToUpdate());
            } else if (item instanceof HomeAssistantNumericMenuItem) {
                // Numeric items can have an optional template to evaluate
                var nmi = item as HomeAssistantNumericMenuItem;
                if (nmi.hasTemplate()) {
                    fullList.add(item);
                }
            } else if (item instanceof HomeAssistantToggleMenuItem) {
                fullList.add(item);
            } else if (item instanceof HomeAssistantTapMenuItem) {
                var tmi = item as HomeAssistantTapMenuItem;
                if (tmi.hasTemplate()) {
                    fullList.add(item);
                }
            }
        }

        return fullList;
    }

    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    //
    function onShow() as Void {}
}

//! Delegate for the HomeAssistantView.
//!
//! Reference: https://developer.garmin.com/connect-iq/core-topics/input-handling/
//
class HomeAssistantViewDelegate extends WatchUi.Menu2InputDelegate {
    private var mIsRootMenuView as Lang.Boolean = false;
    private var mTimer          as QuitTimer;

    //! Class Constructor
    //!
    //! @param isRootMenuView As menus can be nested, this state marks the top level menu so that the
    //!                       back event can exit the application completely rather than just popping
    //!                       a menu view.
    //
    function initialize(isRootMenuView as Lang.Boolean) {
        Menu2InputDelegate.initialize();
        mIsRootMenuView = isRootMenuView;
        mTimer          = getApp().getQuitTimer();
    }

    //! Handle the back button (ESC)
    //
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

    //! Only for CheckboxMenu
    //
    function onDone() {
        mTimer.reset();
    }

    //! Only for CustomMenu
    //
    function onFooter() {
        mTimer.reset();
    }

    //! Select event
    //!
    //! @param item Selected menu item.
    //
    function onSelect(item as WatchUi.MenuItem) as Void {
        mTimer.reset();
        if (item instanceof HomeAssistantToggleMenuItem) {
            var haToggleItem = item as HomeAssistantToggleMenuItem;
            // System.println(haToggleItem.getLabel() + " " + haToggleItem.getId() + " " + haToggleItem.isEnabled());
            haToggleItem.callAction(haToggleItem.isEnabled());
        } else if (item instanceof HomeAssistantTapMenuItem) {
            var haItem = item as HomeAssistantTapMenuItem;
            // System.println(haItem.getLabel() + " " + haItem.getId());
            haItem.callAction();
        } else if (item instanceof HomeAssistantNumericMenuItem) {
            var haItem = item as HomeAssistantNumericMenuItem;
            // System.println(haItem.getLabel() + " " + haItem.getId());
            // create new view to select new value
            var mPickerFactory  = new HomeAssistantNumericFactory((haItem as HomeAssistantNumericMenuItem).getPicker());
            var mPicker         = new HomeAssistantNumericPicker(mPickerFactory,haItem);
            var mPickerDelegate = new HomeAssistantNumericPickerDelegate(mPicker);
            WatchUi.pushView(mPicker,mPickerDelegate,WatchUi.SLIDE_LEFT);
        } else if (item instanceof HomeAssistantGroupMenuItem) {
            var haMenuItem = item as HomeAssistantGroupMenuItem;
            WatchUi.pushView(haMenuItem.getMenuView(), new HomeAssistantViewDelegate(false), WatchUi.SLIDE_LEFT);
        }
    }

    //! Only for CustomMenu
    //
    function onTitle() {
        mTimer.reset();
    }

}
