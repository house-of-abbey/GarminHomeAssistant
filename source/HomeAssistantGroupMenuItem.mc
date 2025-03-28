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
// Menu button with an icon that opens a sub-menu, i.e. group, and optionally renders
// a Home Assistant Template.
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.WatchUi;

class HomeAssistantGroupMenuItem extends HomeAssistantMenuItem {
    private var mMenu as HomeAssistantView;

    function initialize(
        definition as Lang.Dictionary,
        template   as Lang.String,
        icon       as WatchUi.Drawable,
        options    as {
            :alignment as WatchUi.MenuItem.Alignment
        } or Null
    ) {
        if (options != null) {
            options.put(:icon, icon);
        } else {
            options = { :icon => icon };
        }

        HomeAssistantMenuItem.initialize(
            definition.get("name") as Lang.String,
            template,
            options
        );

        mMenu = new HomeAssistantView(definition, null);
    }

    function getMenuView() as HomeAssistantView {
        return mMenu;
    }

}
