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
    //! Options for the plain menu items displayed in place of menu items when the type icons are
    //! hidden, or null while the type icons are shown.
    private static var mPlainOptions as { :alignment as WatchUi.MenuItem.Alignment }? = null;
    private var mTemplate as Lang.String?;

    //! Hide the type icons of the menu items created from now on.
    //!
    //! @param alignment Menu item alignment.
    //
    static function hideTypeIcons(alignment as WatchUi.MenuItem.Alignment) as Void {
        mPlainOptions = { :alignment => alignment };
    }

    //! Class Constructor
    //!
    //! A `WatchUi.IconMenuItem` always reserves space for its icon, even an empty one, and cannot be
    //! created without one. So when the type icons are hidden, a plain `WatchUi.MenuItem` is
    //! displayed in place of this menu item, see `getDisplayedItem()`. The two are each other's
    //! identifier, a reference cycle that is harmless as menus last until the application exits.
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
        var plain = (mPlainOptions == null) ? null : new WatchUi.MenuItem(label, null, self, mPlainOptions);
        WatchUi.IconMenuItem.initialize(
            label,
            null,
            plain,
            options[:icon],
            options
        );
        mTemplate = template;
    }

    //! Return the menu item to display for this one, i.e. the plain menu item displayed in its place
    //! when the type icons are hidden, otherwise this menu item.
    //!
    //! @return The menu item to display.
    //
    function getDisplayedItem() as WatchUi.MenuItem {
        var plain = getId() as WatchUi.MenuItem?;
        return (plain == null) ? self : plain;
    }

    //! Return the menu item behind a displayed menu item, i.e. the reverse of `getDisplayedItem()`.
    //! Any other menu item is returned unchanged.
    //!
    //! @param item A displayed menu item, e.g. taken from a menu.
    //!
    //! @return The menu item providing the behaviour and state.
    //
    static function fromDisplayedItem(item as WatchUi.MenuItem) as WatchUi.MenuItem {
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
    //! `updateState()`, here and in the subclasses, reach the displayed menu item.
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
