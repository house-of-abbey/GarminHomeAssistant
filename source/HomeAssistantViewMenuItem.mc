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

class HomeAssistantViewMenuItem extends WatchUi.MenuItem {
    hidden var menu as HomeAssistantView;

    function initialize(definition as Lang.Dictionary) {
        // definitions.get(...) are Strings here as they have been checked by HomeAssistantView first
        WatchUi.MenuItem.initialize(
            definition.get("name") as Lang.String,
            "Menu",
            definition.get("entity") as Lang.String,
            null
        );

        menu = new HomeAssistantView(definition, null);
    }

    function getMenuView() as HomeAssistantView {
        return menu;
    }

}
