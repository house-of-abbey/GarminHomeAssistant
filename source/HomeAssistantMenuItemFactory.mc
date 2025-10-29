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
    //! @param options   Menu item options to be passed on, including both SDK and menu options, e.g. exit, confirm & pin.
    //
    function toggle(
        label     as Lang.String or Lang.Symbol,
        entity_id as Lang.String?,
        template  as Lang.String?,
        options   as {
            :exit    as Lang.Boolean,
            :confirm as Lang.Boolean,
            :pin     as Lang.Boolean
        }
    ) as WatchUi.MenuItem {
        var keys = mMenuItemOptions.keys();
        for (var i = 0; i < keys.size(); i++) {
            options.put(keys[i], mMenuItemOptions.get(keys[i]));
        }
        return new HomeAssistantToggleMenuItem(
            label,
            template,
            { "entity_id" => entity_id },
            options
        );
    }

    //! Tap menu item.
    //!
    //! @param label     Menu item label.
    //! @param entity_id Home Assistant Entity ID (optional)
    //! @param template  Template for Home Assistant to render (optional)
    //! @param service   Template for Home Assistant to render (optional)
    //! @param data      Sourced from the menu JSON, this is the `data` field from the `tap_action` field.
    //! @param options   Menu item options to be passed on, including both SDK and menu options, e.g. exit, confirm & pin.
    //
    function tap(
        label     as Lang.String or Lang.Symbol,
        entity_id as Lang.String?,
        template  as Lang.String?,
        service   as Lang.String?,
        data      as Lang.Dictionary?,
        options   as {
            :exit    as Lang.Boolean,
            :confirm as Lang.Boolean,
            :pin     as Lang.Boolean
        }
    ) as WatchUi.MenuItem {
        if (entity_id != null) {
            if (data == null) {
                data = { "entity_id" => entity_id };
            } else {
                data.put("entity_id", entity_id);
            }
        }
        var keys = mMenuItemOptions.keys();
        for (var i = 0; i < keys.size(); i++) {
            options.put(keys[i], mMenuItemOptions.get(keys[i]));
        }
        if (service != null) {
            options.put(:icon, mTapTypeIcon);
            return new HomeAssistantTapMenuItem(
                label,
                template,
                service,
                data,
                options,
                mHomeAssistantService
            );
        } else {
            options.put(:icon, mInfoTypeIcon);
            return new HomeAssistantTapMenuItem(
                label,
                template,
                null,
                data,
                options,
                mHomeAssistantService
            );
        }
    }
    //! Numeric menu item.
    //!
    //! @param definition Items array from the JSON that defines this sub menu.
    //! @param template   Template for Home Assistant to render (optional)
    //
    function numeric(
        label     as Lang.String or Lang.Symbol,
        entity_id as Lang.String?,
        template  as Lang.String?,
        service   as Lang.String?,
        picker    as Lang.Dictionary,
        options   as {
            :exit    as Lang.Boolean,
            :confirm as Lang.Boolean,
            :pin     as Lang.Boolean,
            :icon    as WatchUi.Bitmap
        }
    ) as WatchUi.MenuItem {
        var data = null;
        if (entity_id != null) {
            data = { "entity_id" => entity_id };
        }
        var keys = mMenuItemOptions.keys();
        for (var i = 0; i < keys.size(); i++) {
            options.put(keys[i], mMenuItemOptions.get(keys[i]));
        }
        options.put(:icon, mTapTypeIcon);
        return new HomeAssistantNumericMenuItem(
            label,
            template,
            service,
            data,
            picker,
            options,
            mHomeAssistantService
        );
    }
    //! Group menu item.
    //!
    //! @param definition Items array from the JSON that defines this sub menu.
    //! @param template   Template for Home Assistant to render (optional)
    //
    function group(
        definition as Lang.Dictionary,
        template   as Lang.String?
    ) as WatchUi.MenuItem {
        return new HomeAssistantGroupMenuItem(
            definition,
            template,
            mGroupTypeIcon,
            mMenuItemOptions
        );
    }
}
