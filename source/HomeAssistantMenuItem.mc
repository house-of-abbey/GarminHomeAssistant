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

//! Generic menu item with an icon that optionally renders a Home Assistant Template.
//! With version 3.17, KostaMadorsky provided an efficient means to render menu items
//! without icons, and avoiding the awkwardnesses of dual inheritance. The feature
//! adds a non-icon menu item to an instance of this object, which does increase memory
//! usage when the option is selected, but crucially avoids consuming too much more
//! memory for older 98k devices by keeping the option de-selected. The effect of this
//! change is to allow the space for the type icon to be reclaimed for text via an
//! global application toggle option in the settings.
//
class HomeAssistantMenuItem extends WatchUi.IconMenuItem {
    private var mTemplate as Lang.String?;

    //! Class Constructor
    //!
    //! A `WatchUi.IconMenuItem` always reserves space for its icon, even an empty one, and cannot be
    //! created without one. So when the type icons are hidden, a plain `WatchUi.MenuItem` is
    //! displayed in place of this menu item. Each is the other's identifier, see
    //! `HomeAssistantView.addItem()` and `getDisplayedItem()`.
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
            // options[:icon] will just be ignored, no need to create a new Lang.Dictionary.
            /* identifier: */ Settings.isShowTypeIcons() ? null : new WatchUi.MenuItem(label, null, self, options),
            options[:icon],
            options
        );
        mTemplate = template;
    }

    //! Returns the menu item to be displayed. Either the item passed in, if icons are shown, or the non-icon item.
    //! The non-icon item is the *identifier* of the icon menu item passed when it is initialised, see `initialize()`.
    //!
    //! @param item A HomeAssistantMenuItem
    //!
    //! @return The menu item providing the behaviour and state.
    //
    static function getDisplayedItem(item as WatchUi.MenuItem) as WatchUi.MenuItem {
        // `getId()` returns the non-icon menu item passed as *identifier* when initialised
        var behind = item.getId();
        return (behind instanceof HomeAssistantMenuItem) ? behind : item;
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

    //! Overrides `WatchUi.MenuItem.setSubLabel()` so that the sub label updates made by
    //! `updateState()`, here and in the subclasses, reach the plain menu item being displayed
    //! when the type icons are hidden. This override effectively proxies the sub label update
    //! call and redirects to which ever menu item object is currently being displayed.
    //!
    //! @param subLabel The new sub label.
    //
    function setSubLabel(subLabel as Lang.String or Lang.ResourceId or Null) as Void {
        var plain = getId() as WatchUi.MenuItem?;
        if (plain == null) {
            WatchUi.IconMenuItem.setSubLabel(subLabel);
        } else {
            plain.setSubLabel(subLabel);
        }
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
