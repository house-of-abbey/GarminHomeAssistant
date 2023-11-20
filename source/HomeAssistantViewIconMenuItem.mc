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
// P A Abbey & J D Abbey & SomeoneOnEarth, 16 November 2023
//
//
// Description:
//
// Menu button with an icon that opens a sub-menu.
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.WatchUi;

class HomeAssistantViewIconMenuItem extends WatchUi.IconMenuItem {
    private var mMenu as HomeAssistantView;

    function initialize(definition as Lang.Dictionary, icon as WatchUi.Drawable, options as {
            :alignment as WatchUi.MenuItem.Alignment
        } or Null) {
        var label = definition.get("name") as Lang.String;
        var identifier = definition.get("entity") as Lang.String;
        
        WatchUi.IconMenuItem.initialize(
            label,
            null,
            identifier,
            icon,
            options
        );

        mMenu = new HomeAssistantView(definition, null);
    }

    function getMenuView() as HomeAssistantView {
        return mMenu;
    }

}
