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

class HomeAssistantGroupMenuItem extends TemplateMenuItem {
    private var mMenu as HomeAssistantView;

    function initialize(
        definition as Lang.Dictionary,
        template   as Lang.String,
        icon       as WatchUi.Drawable,
        options    as {
            :alignment as WatchUi.MenuItem.Alignment
        } or Null
    ) {

        TemplateMenuItem.initialize(
            definition.get("name") as Lang.String,
            template,
            // Now this feels very "closely coupled" to the application, but it is the most reliable method instead of using a timer.
            getApp().method(:updateNextMenuItem),
            icon,
            options
        );

        mMenu = new HomeAssistantView(definition, null);
    }

    function getMenuView() as HomeAssistantView {
        return mMenu;
    }

}
