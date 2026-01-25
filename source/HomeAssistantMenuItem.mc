//-----------------------------------------------------------------------------------
//
// Distributed under MIT Licence
//   See https://github.com/house-of-abbey/GarminHomeAssistant/blob/main/LICENSE
//
//-----------------------------------------------------------------------------------
//
// GarminHomeAssistant is a Garmin IQ application written in Monkey C and routinely
// tested on a Venu 2 device. The source code is provided at:
//            https://github.com/house-of-abbey/GarminHomeAssistant
//
// P A Abbey & J D Abbey & Someone0nEarth, 31 October 2023
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics;

//! Generic menu button with an icon that optionally renders a Home Assistant Template.
//
class HomeAssistantMenuItem extends WatchUi.IconMenuItem {
    private var mTemplate as Lang.String?;

    //! Class Constructor
    //!
    //! @param label    Menu item label
    //! @param template Menu item template
    //! @param options  Menu item options to be passed on.
    //
    function initialize(
        label    as Lang.String or Lang.Symbol,
        template as Lang.String,
        options  as {
            :alignment as WatchUi.MenuItem.Alignment,
            :icon      as Graphics.BitmapType or WatchUi.Drawable or Lang.Symbol
        }?
    ) {
        WatchUi.IconMenuItem.initialize(
            label,
            null,
            null,
            options[:icon],
            options
        );
        mTemplate = template;
    }

    //! Does this menu item use a template?
    //!
    //! @return True if the menu has a defined template else false.
    //
    function hasTemplate() as Lang.Boolean {
        return mTemplate != null;
    }

    //! Return the menu item's template.
    //!
    //! @return A string with the menu item's template definition (or null).
    //
    function getTemplate() as Lang.String? {
        return mTemplate;
    }

    //! Update the menu item's sub label to display the template rendered by Home Assistant.
    //!
    //! @param data The rendered template (typically a string) to be placed in the sub label. This may
    //!             unusually be a number if the SDK interprets the JSON returned by Home Assistant as such.
    //
    function updateState(data as Lang.String or Lang.Dictionary or Lang.Number or Lang.Float or Null) as Void {
        if (data == null) {
            setSubLabel($.Rez.Strings.Empty);
        } else if(data instanceof Lang.String) {
            setSubLabel(data);
        } else if(data instanceof Lang.Number) {
            var d = data as Lang.Number;
            setSubLabel(d.format("%d"));
        } else if(data instanceof Lang.Float) {
            var f = data as Lang.Float;
            setSubLabel(f.format("%f"));
        } else if(data instanceof Lang.Dictionary) {
            // System.println("HomeAssistantMenuItem updateState() data = " + data);
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

}
