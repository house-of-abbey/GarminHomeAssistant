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
// Menu button that opens a sub-menu.
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.WatchUi;

class HomeAssistantViewIconMenuItem extends WatchUi.IconMenuItem {
    hidden var mMenu as HomeAssistantView;

    function initialize(definition as Lang.Dictionary) {
        var label = definition.get("name") as Lang.String;
        var identifier = definition.get("entity") as Lang.String;

        var icon = new WatchUi.Bitmap({
            :rezId=>Rez.Drawables.LauncherIcon,
            :locX=>WatchUi.LAYOUT_HALIGN_CENTER,
            :locY=>WatchUi.LAYOUT_VALIGN_CENTER
        });

        var alignement = {:alignment => WatchUi.MenuItem.MENU_ITEM_LABEL_ALIGN_RIGHT};

        WatchUi.IconMenuItem.initialize(
            label,
            null,
            identifier,
            icon,
            alignement
        );

        mMenu = new HomeAssistantView(definition, null);
    }

    function getMenuView() as HomeAssistantView {
        return mMenu;
    }

}
