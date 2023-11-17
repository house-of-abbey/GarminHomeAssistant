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
// P A Abbey & J D Abbey & SomeoneOnEarth, 17 November 2023
//
//
// Description:
//
// MenuItems Factory.
//
//-----------------------------------------------------------------------------------

using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi;

class HomeAssistantMenuItemFactory {

    private var mRightLabelAlignement;
    private var mLabelToggle;
    private var strMenuItemTap;
    private var bLeanDesign;

    private var mTapIcon;

    private var mMenuIcon;

    private static var instance;

    private function initialize() {
        mLabelToggle = {
                            :enabled  => WatchUi.loadResource($.Rez.Strings.MenuItemOn) as Lang.String,
                            :disabled => WatchUi.loadResource($.Rez.Strings.MenuItemOff) as Lang.String
                       };
        
        bLeanDesign = Application.Properties.getValue("lean_ui") as Lang.Boolean;

        mRightLabelAlignement = {:alignment => WatchUi.MenuItem.MENU_ITEM_LABEL_ALIGN_RIGHT};

        strMenuItemTap = WatchUi.loadResource($.Rez.Strings.MenuItemTap);
        mTapIcon = new WatchUi.Bitmap({
                            :rezId=>$.Rez.Drawables.TapIcon
                       });

        mMenuIcon = new WatchUi.Bitmap({
                            :rezId=>Rez.Drawables.MenuIcon,
                            :locX=>WatchUi.LAYOUT_HALIGN_CENTER,
                            :locY=>WatchUi.LAYOUT_VALIGN_CENTER
        });


        
    }

    static function create() {
        if (instance == null) {
            instance = new HomeAssistantMenuItemFactory();
        }
        return instance;
    }

    function toggle(label as Lang.String or Lang.Symbol, identifier as Lang.Object or Null) as WatchUi.MenuItem{
        var subLabel = null;

        if (bLeanDesign == false){
            subLabel=mLabelToggle;
        }
     
        return new HomeAssistantToggleMenuItem(
            label,
            subLabel,
            identifier,
            false,
            null
        );
    }

    function tap(label as Lang.String or Lang.Symbol, identifier as Lang.Object or Null, service as Lang.String or Null) as WatchUi.MenuItem{
        if (bLeanDesign) {
            return new HomeAssistantIconMenuItem(
                                label,
                                null,
                                identifier,
                                service,
                                mTapIcon,
                                mRightLabelAlignement
                    );
            
        } else {
            return new HomeAssistantMenuItem(
                                label,
                                strMenuItemTap,
                                identifier,
                                service,
                                null
                            );
        }
    }

    function group(definition as Lang.Dictionary) as WatchUi.MenuItem{
        if (bLeanDesign) {
            return new HomeAssistantViewIconMenuItem(definition, mMenuIcon, mRightLabelAlignement);
        } else {
            return new HomeAssistantViewMenuItem(definition);
        }
    }
}
