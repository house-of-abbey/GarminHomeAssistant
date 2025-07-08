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
// P A Abbey & J D Abbey & Someone0nEarth, 17 November 2023
//
//-----------------------------------------------------------------------------------

using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi;

//! MenuItems Factory class.
//
class HomeAssistantMenuItemFactory {
    private var mMenuItemOptions      as Lang.Dictionary;
    private var mTapTypeIcon          as WatchUi.Bitmap;
    private var mGroupTypeIcon        as WatchUi.Bitmap;
    private var mInfoTypeIcon         as WatchUi.Bitmap;
    private var mHomeAssistantService as HomeAssistantService;

    private static var instance;

    //! Class Constructor
    //
    private function initialize() {
        mMenuItemOptions = {
            :alignment => Settings.getMenuAlignment()
        };

        mTapTypeIcon = new WatchUi.Bitmap({
            :rezId => $.Rez.Drawables.TapTypeIcon,
            :locX  => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY  => WatchUi.LAYOUT_VALIGN_CENTER
        });

        mGroupTypeIcon = new WatchUi.Bitmap({
            :rezId => $.Rez.Drawables.GroupTypeIcon,
            :locX  => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY  => WatchUi.LAYOUT_VALIGN_CENTER
        });

        mInfoTypeIcon = new WatchUi.Bitmap({
            :rezId => $.Rez.Drawables.InfoTypeIcon,
            :locX  => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY  => WatchUi.LAYOUT_VALIGN_CENTER
        });

        mHomeAssistantService = new HomeAssistantService();
    }

    //! Create the one and only instance of this class.
    //
    static function create() as HomeAssistantMenuItemFactory {
        if (instance == null) {
            instance = new HomeAssistantMenuItemFactory();
        }
        return instance;
    }

    //! Toggle menu item.
    //!
    //! @param label     Menu item label.
    //! @param entity_id Home Assistant Entity ID (optional)
    //! @param template  Template for Home Assistant to render (optional)
    //! @param confirm   Should this menu item selection be confirmed?
    //! @param pin       Should this menu item selection request the security PIN?
    //
    function toggle(
        label     as Lang.String or Lang.Symbol,
        entity_id as Lang.String or Null,
        template  as Lang.String or Null,
        exit      as Lang.Boolean,
        confirm   as Lang.Boolean,
        pin       as Lang.Boolean
    ) as WatchUi.MenuItem {
        return new HomeAssistantToggleMenuItem(
            label,
            template,
            { "entity_id" => entity_id },
            exit,
            confirm,
            pin,
            mMenuItemOptions
        );
    }

    //! Tap menu item.
    //!
    //! @param label     Menu item label.
    //! @param entity_id Home Assistant Entity ID (optional)
    //! @param template  Template for Home Assistant to render (optional)
    //! @param service   Template for Home Assistant to render (optional)
    //! @param confirm   Should this menu item selection be confirmed?
    //! @param pin       Should this menu item selection request the security PIN?
    //! @param data      Sourced from the menu JSON, this is the `data` field from the `tap_action` field.
    //
    function tap(
        label     as Lang.String     or Lang.Symbol,
        entity_id as Lang.String     or Null,
        template  as Lang.String     or Null,
        service   as Lang.String     or Null,
        data      as Lang.Dictionary or Null,
        exit      as Lang.Boolean,
        confirm   as Lang.Boolean,
        pin       as Lang.Boolean
    ) as WatchUi.MenuItem {
        if (entity_id != null) {
            if (data == null) {
                data = { "entity_id" => entity_id };
            } else {
                data.put("entity_id", entity_id);
            }
        }
        if (service != null) {
            return new HomeAssistantTapMenuItem(
                label,
                template,
                service,
                data,
                exit,
                confirm,
                pin,
                mTapTypeIcon,
                mMenuItemOptions,
                mHomeAssistantService
            );
        } else {
            return new HomeAssistantTapMenuItem(
                label,
                template,
                service,
                data,
                exit,
                confirm,
                pin,
                mInfoTypeIcon,
                mMenuItemOptions,
                mHomeAssistantService
            );
        }
    }

    //! Group menu item.
    //!
    //! @param definition Items array from the JSON that defines this sub menu.
    //! @param template   Template for Home Assistant to render (optional)
    //
    function group(
        definition as Lang.Dictionary,
        template   as Lang.String or Null
    ) as WatchUi.MenuItem {
        return new HomeAssistantGroupMenuItem(
            definition,
            template,
            mGroupTypeIcon,
            mMenuItemOptions
        );
    }
}
