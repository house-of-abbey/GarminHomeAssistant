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

class HomeAssistantGroupMenuItem extends WatchUi.IconMenuItem {
    private var mTemplate as Lang.String or Null;
    private var mMenu as HomeAssistantView;

    function initialize(
        definition as Lang.Dictionary,
        template   as Lang.String,
        icon       as WatchUi.Drawable,
        options    as {
            :alignment as WatchUi.MenuItem.Alignment
        } or Null
    ) {

        WatchUi.IconMenuItem.initialize(
            definition.get("name") as Lang.String,
            null,
            null,
            icon,
            options
        );

        mTemplate = template;
        mMenu = new HomeAssistantView(definition, null);
    }

    function hasTemplate() as Lang.Boolean {
        return mTemplate != null;
    }

    function buildTemplate() as Lang.String or Null {
        return mTemplate;
    }

    function updateState(data as Lang.String or Lang.Dictionary or Null) as Void {
        if (data == null) {
            setSubLabel(null);
        } else if(data instanceof Lang.String) {
            setSubLabel(data);
        } else if(data instanceof Lang.Number) {
            var d = data as Lang.Number;
            setSubLabel(d.format("%d"));
        } else if(data instanceof Lang.Float) {
            var f = data as Lang.Float;
            setSubLabel(f.format("%f"));
        } else if(data instanceof Lang.Dictionary) {
            // System.println("HomeAssistantGroupMenuItem updateState() data = " + data);
            if (data.get("error") != null) {
                setSubLabel($.Rez.Strings.TemplateError);
            } else {
                setSubLabel($.Rez.Strings.PotentialError);
            }
        } else {
            // The template must return a Lang.String, Number or Float, or the item cannot be formatted locally without error.
            setSubLabel(WatchUi.loadResource($.Rez.Strings.TemplateError) as Lang.String);
        }
        WatchUi.requestUpdate();
    }

    function getMenuView() as HomeAssistantView {
        return mMenu;
    }

}
