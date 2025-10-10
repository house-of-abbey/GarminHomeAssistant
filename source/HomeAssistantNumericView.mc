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


using Toybox.Application.Properties;
using Toybox.Timer;


//! Home Assistant menu construction.
//
class HomeAssistantNumericView extends WatchUi.Menu2 {

    private var mMenuItem as HomeAssistantNumericMenuItem;


    //! Class Constructor
    //
    function initialize(
       menuItem as HomeAssistantNumericMenuItem

    ) {
        mMenuItem = menuItem;        

        WatchUi.Menu2.initialize({:title => mMenuItem.getLabel()});
        
        addItem(mMenuItem);

        //updateState(mData);
        
    }
    
    //! Return the menu item
    //!
    //! @return A HomeAssitantTapMenuItem (or null).
    //
    function getMenuItem() as HomeAssistantNumericMenuItem? {
        return mMenuItem;
    }

    //! Update the menu item's sub label to display the template rendered by Home Assistant.
    //!
    //! @param data The rendered template (typically a string) to be placed in the sub label. This may
    //!             unusually be a number if the SDK interprets the JSON returned by Home Assistant as such.
    //
    function updateState(data as Lang.String or Lang.Dictionary or Lang.Number or Lang.Float or Null) as Void {
        if (data == null) {
            mMenuItem.setSubLabel($.Rez.Strings.Empty);
        } else if(data instanceof Lang.String) {
            mMenuItem.setSubLabel(data);
        } else if(data instanceof Lang.Number) {
            var d = data as Lang.Number;
            mMenuItem.setSubLabel(d.format("%d"));
        } else if(data instanceof Lang.Float) {
            var f = data as Lang.Float;
            mMenuItem.setSubLabel(f.format("%f"));
        } else if(data instanceof Lang.Dictionary) {
            // System.println("HomeAssistantMenuItem updateState() data = " + data);
            if (data.get("error") != null) {
                mMenuItem.setSubLabel($.Rez.Strings.TemplateError);
            } else {
                mMenuItem.setSubLabel($.Rez.Strings.PotentialError);
            }
        } else {
            // The template must return a Lang.String, Number or Float, or the item cannot be formatted locally without error.
            mMenuItem.setSubLabel(WatchUi.loadResource($.Rez.Strings.TemplateError) as Lang.String);
        }
        WatchUi.requestUpdate();
    }
    

    //! Return a list of items that need to be updated within this menu structure.
    //!
    //! MN. Lang.Array.addAll() fails structural type checking without including "Null" in the return type
    //!
    //! @return An array of menu items that need to be updated periodically to reflect the latest Home Assistant state.
    //
    function getItemsToUpdate() as Lang.Array<HomeAssistantToggleMenuItem or HomeAssistantTapMenuItem or HomeAssistantGroupMenuItem or Null> {
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
    function onShow() as Void {}
}


//! Delegate for the HomeAssistantView.
//!
//! Reference: https://developer.garmin.com/connect-iq/core-topics/input-handling/
//
class HomeAssistantNumericViewDelegate extends WatchUi.Menu2InputDelegate {
    private var mIsRootMenuView as Lang.Boolean = false;
    private var mTimer          as QuitTimer;
    private var mItem           as HomeAssistantNumericMenuItem;

    //! Class Constructor
    //!
    //! @param isRootMenuView As menus can be nested, this state marks the top level menu so that the
    //!                       back event can exit the application completely rather than just popping
    //!                       a menu view.
    //tap
    function initialize(isRootMenuView as Lang.Boolean, item as HomeAssistantNumericMenuItem) {
        Menu2InputDelegate.initialize();
        mIsRootMenuView = isRootMenuView;
        mTimer          = getApp().getQuitTimer();
        mItem           = item;
    }

    //! Handle the back button (ESC)
    //
    function onBack() {
        mTimer.reset();

        mItem.setValueChanged(false);

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

    // Decrease Value
    function onNextPage() as Lang.Boolean {
        mItem.decreaseValue();
        return true;
    }
    //Increase Value
    function onPreviousPage() as Lang.Boolean {
        mItem.increaseValue();
        return true;
    }

   
    //! Select event
    //!
    //! @param item Selected menu item.
    //
    function onSelect(item as WatchUi.MenuItem) as Void {
        mTimer.reset();
        mItem.callService();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return;
    }

    //! Only for CustomMenu
    //
    function onTitle() {
        mTimer.reset();
    }


}


