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
// P A Abbey & J D Abbey & Someone0nEarth & moesterheld & vincentezw, 31 October 2023
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics;

//! Menu button that triggers a service.
//
class HomeAssistantTapMenuItem extends HomeAssistantMenuItem {
    private var mHomeAssistantService as HomeAssistantService;
    private var mService              as Lang.String     or Null;
    private var mConfirm              as Lang.Boolean;
    private var mExit                 as Lang.Boolean;
    private var mPin                  as Lang.Boolean;
    private var mData                 as Lang.Dictionary or Null;

    //! Class Constructor
    //!
    //! @param label     Menu item label.
    //! @param template  Menu item template.
    //! @param service   Menu item service.
    //! @param data      Data to supply to the service call.
    //! @param exit      Should the service call complete and then exit?
    //! @param confirm   Should the service call be confirmed to avoid accidental invocation?
    //! @param pin       Should the service call be protected with a PIN for some low level of security?
    //! @param icon      Icon to use for the menu item.
    //! @param options   Menu item options to be passed on, including both SDK and menu options, e.g. exit, confirm & pin.
    //! @param haService Shared Home Assistant service object that will perform the required call. Only
    //!                  one of these objects is created for all menu items to re-use.
    //
    function initialize(
        label     as Lang.String     or Lang.Symbol,
        template  as Lang.String,
        service   as Lang.String     or Null,
        data      as Lang.Dictionary or Null,
        options   as {
            :alignment as WatchUi.MenuItem.Alignment,
            :icon      as Graphics.BitmapType or WatchUi.Drawable or Lang.Symbol,
            :exit      as Lang.Boolean,
            :confirm   as Lang.Boolean,
            :pin       as Lang.Boolean
        } or Null,
        haService as HomeAssistantService
    ) {
        HomeAssistantMenuItem.initialize(
            label,
            template,
            {
                :alignment => options.get(:alignment),
                :icon      => options.get(:icon)
            } 
        );

        mHomeAssistantService = haService;
        mService              = service;
        mData                 = data;
        mExit                 = options.get(:exit);
        mConfirm              = options.get(:confirm);
        mPin                  = options.get(:pin);
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
                    new HomeAssistantPinConfirmationDelegate({
                        :callback    => method(:onConfirm),
                        :pin         => pin, 
                        :state       => false,
                        :view        => pinConfirmationView,
                    }),
                    WatchUi.SLIDE_IMMEDIATE
                );
            }
        } else if (mConfirm) {
            var phoneConnected = System.getDeviceSettings().phoneConnected;
            var internetAvailable = System.getDeviceSettings().connectionAvailable;
            if ((! phoneConnected || ! internetAvailable) && Settings.getWifiLteExecutionEnabled()) {
                var dialogMsg = WatchUi.loadResource($.Rez.Strings.WifiLtePrompt) as Lang.String;
                var dialog = new WatchUi.Confirmation(dialogMsg);
                WatchUi.pushView(
                    dialog,
                    new WifiLteExecutionConfirmDelegate({
                        :type => "service",
                        :service => mService,
                        :data => mData,
                        :exit => mExit,
                    }, dialog),
                    WatchUi.SLIDE_LEFT
                );
            } else {
                var view = new HomeAssistantConfirmation();
                WatchUi.pushView(
                    view,
                    new HomeAssistantConfirmationDelegate({
                        :callback       => method(:onConfirm),
                        :confirmationView => view,
                        :state          => false,
                    }),
                    WatchUi.SLIDE_IMMEDIATE
                );
            }
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
            mHomeAssistantService.call(mService, mData, mExit);
        }
    }

}
