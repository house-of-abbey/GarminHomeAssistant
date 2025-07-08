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
// P A Abbey & J D Abbey & Someone0nEarth & moesterheld, 31 October 2023
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics;

//! Menu button that triggers a service.
//
class HomeAssistantTapMenuItem extends HomeAssistantMenuItem {
    private var mHomeAssistantService as HomeAssistantService;
    private var mService              as Lang.String or Null;
    private var mConfirm              as Lang.Boolean;
    private var mExit                 as Lang.Boolean;
    private var mPin                  as Lang.Boolean;
    private var mData                 as Lang.Dictionary or Null;

    //! Class Constructor
    //!
    //! @param label     Menu item label.
    //! @param template  Menu item template.
    //! @param service   Menu item service.
    //! @param confirm   Should the service call be confirmed to avoid accidental invocation?
    //! @param pin       Should the service call be protected with a PIN for some low level of security?
    //! @param data      Data to supply to the service call.
    //! @param icon      Icon to use for the menu item.
    //! @param options   Menu item options to be passed on.
    //! @param haService Shared Home Assistant service object that will perform the required call. Only
    //!                  one of these objects is created for all menu items to re-use.
    //
    function initialize(
        label     as Lang.String or Lang.Symbol,
        template  as Lang.String,
        service   as Lang.String or Null,
        data      as Lang.Dictionary or Null,
        exit      as Lang.Boolean,
        confirm   as Lang.Boolean,
        pin       as Lang.Boolean,
        icon      as Graphics.BitmapType or WatchUi.Drawable,
        options   as {
            :alignment as WatchUi.MenuItem.Alignment,
            :icon      as Graphics.BitmapType or WatchUi.Drawable or Lang.Symbol
        } or Null,
        haService as HomeAssistantService
    ) {
        if (options != null) {
            options.put(:icon, icon);
        } else {
            options = { :icon => icon };
        }

        HomeAssistantMenuItem.initialize(
            label,
            template,
            options
        );

        mHomeAssistantService = haService;
        mService              = service;
        mData                 = data;
        mExit                 = exit;
        mConfirm              = confirm;
        mPin                  = pin;
    }

    //! Call a Home Assistant service only after checks have been done for confirmation or PIN entry.
    //
    function callService() as Void {
        var hasTouchScreen = System.getDeviceSettings().isTouchScreen;
        if (mPin && hasTouchScreen) {
            var pin = Settings.getPin();
            if (pin != null) {
                var pinConfirmationView = new HomeAssistantPinConfirmationView();
                WatchUi.pushView(
                    pinConfirmationView,
                    new HomeAssistantPinConfirmationDelegate(method(:onConfirm), false, pin, pinConfirmationView),
                    WatchUi.SLIDE_IMMEDIATE
                );
            }
        } else if (mConfirm) {
            WatchUi.pushView(
                new HomeAssistantConfirmation(),
                new HomeAssistantConfirmationDelegate(method(:onConfirm), false),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else {
            onConfirm(false);
        }
    }

    //! Callback function after the menu items selection has been (optionally) confirmed.
    //!
    //! @param b Ignored. It is included in order to match the expected function prototype of the callback method.
    //
    function onConfirm(b as Lang.Boolean) as Void {
        if (mService != null) {
            mHomeAssistantService.call(mService, mData);
        }
        if (mExit) {
            System.exit();
        }
    }

}
