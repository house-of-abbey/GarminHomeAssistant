//-----------------------------------------------------------------------------------
//
// Distributed under MIT Licence
//   See https://github.com/house-of-abbey/GarminHomeAssistantWidget/blob/main/LICENSE.
//
//-----------------------------------------------------------------------------------
//
// GarminHomeAssistantWidget is a Garmin IQ widget written in Monkey C. The source code is provided at:
//            https://github.com/house-of-abbey/GarminHomeAssistantWidget.
//
// P A Abbey & J D Abbey & Someone0nEarth, 31 October 2023
//
//
// Description:
//
// Menu button with an icon that opens a sub-menu, i.e. group.
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.WatchUi;

class HomeAssistantGroupMenuItem extends WatchUi.IconMenuItem {
    private var mMenu as HomeAssistantView;

    function initialize(
        definition as Lang.Dictionary,
        icon       as WatchUi.Drawable,
        options    as {
            :alignment as WatchUi.MenuItem.Alignment
        } or Null) {

        WatchUi.IconMenuItem.initialize(
            definition.get("name") as Lang.String,
            null,
            null,
            icon,
            options
        );

        mMenu = new HomeAssistantView(definition, null);
    }

    function getMenuView() as HomeAssistantView {
        return mMenu;
    }

}
