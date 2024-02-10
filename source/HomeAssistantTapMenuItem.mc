//-----------------------------------------------------------------------------------
//
// Distributed under MIT Licence
//   See https://github.com/house-of-abbey/GarminHomeAssistantWidget/blob/main/LICENSE.
//
//-----------------------------------------------------------------------------------
//
// GarminHomeAssistantWidget is a Garmin IQ widget written in Monkey C. The source code is provided at:
//            https://github.com/house-of-abbey/GarminHomeAssistantWidget.
//
// P A Abbey & J D Abbey & Someone0nEarth, 31 October 2023
//
//
// Description:
//
// Menu button that triggers a service.
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics;

class HomeAssistantTapMenuItem extends WatchUi.IconMenuItem {
    private var mHomeAssistantService as HomeAssistantService;
    private var mService              as Lang.String;
    private var mConfirm              as Lang.Boolean;
    private var mData                 as Lang.Dictionary or Null;

    function initialize(
        label      as Lang.String or Lang.Symbol,
        service    as Lang.String or Null,
        confirm    as Lang.Boolean,
        data       as Lang.Dictionary or Null,
        icon       as Graphics.BitmapType or WatchUi.Drawable,
        options    as {
            :alignment as WatchUi.MenuItem.Alignment
        } or Null,
        haService  as HomeAssistantService
    ) {
        WatchUi.IconMenuItem.initialize(
            label,
            null,
            null,
            icon,
            options
        );

        mHomeAssistantService = haService;
        mService              = service;
        mConfirm              = confirm;
        mData                 = data;
    }

    function callService() as Void {
        if (mConfirm) {
            WatchUi.pushView(
                new HomeAssistantConfirmation(),
                new HomeAssistantConfirmationDelegate(method(:onConfirm), false),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else {
            mHomeAssistantService.call(mService, mData);
        }
    }

    // NB. Parameter 'b' is ignored
    function onConfirm(b as Lang.Boolean) as Void {
        mHomeAssistantService.call(mService, mData);
    }

}
