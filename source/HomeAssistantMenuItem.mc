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
    //! Plain menu items displaying menu items without their type icon, keyed by the menu item they
    //! display. Only created when the type icons are hidden, so otherwise there is no cost per menu item.
    private static var mPlainItems   as Lang.Dictionary? = null;
    //! Options shared by all the plain menu items.
    private static var mPlainOptions as { :alignment as WatchUi.MenuItem.Alignment }? = null;
    private var mTemplate as Lang.String?;

    //! Class Constructor
    //!
    //! A `WatchUi.IconMenuItem` always reserves space for its icon, even an empty one, and it cannot
    //! be created without an icon. So when the type icon is to be hidden, a plain `WatchUi.MenuItem`
    //! identifying this menu item is created to be displayed in its place, see `getMenuItem()`. This
    //! menu item still provides all the behaviour and state.
    //!
    //! @param label    Menu item label
    //! @param template Menu item template
    //! @param options  Menu item options to be passed on, and `:hideIcon` to hide the type icon.
    //
    function initialize(
        label    as Lang.String or Lang.Symbol,
        template as Lang.String,
        options  as {
            :alignment as WatchUi.MenuItem.Alignment,
            :icon      as Graphics.BitmapType or WatchUi.Drawable or Lang.Symbol,
            :hideIcon  as Lang.Boolean
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
        if (options[:hideIcon]) {
            if (mPlainItems == null) {
                mPlainItems   = {};
                mPlainOptions = { :alignment => options[:alignment] };
            }
            mPlainItems[self] = new WatchUi.MenuItem(label, null, self, mPlainOptions);
        }
    }

    //! Return the menu item to add to a menu, i.e. the plain menu item displaying this one without
    //! its type icon, or this menu item when the type icons are shown.
    //!
    //! @return The menu item to display.
    //
    function getMenuItem() as WatchUi.MenuItem {
        if (mPlainItems != null) {
            var plain = mPlainItems[self] as WatchUi.MenuItem?;
            if (plain != null) {
                return plain;
            }
        }
        return self;
    }

    //! Return the menu item providing the behaviour for a menu item taken from a menu, i.e. the menu
    //! item that a plain menu item is displaying, otherwise the menu item itself.
    //!
    //! @param item A menu item taken from a menu.
    //!
    //! @return The menu item providing the behaviour.
    //
    static function fromMenuItem(item as WatchUi.MenuItem) as WatchUi.MenuItem {
        var id = item.getId();
        if (id instanceof HomeAssistantMenuItem) {
            return id;
        }
        return item;
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

    //! Set the sub label of the menu item being displayed, i.e. this one or the plain menu item
    //! displaying it without its type icon.
    //!
    //! @param subLabel The new sub label.
    //
    function setSubLabel(subLabel as Lang.String or Lang.ResourceId or Null) as Void {
        var item = getMenuItem();
        if (item == self) {
            WatchUi.IconMenuItem.setSubLabel(subLabel);
        } else {
            item.setSubLabel(subLabel);
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
