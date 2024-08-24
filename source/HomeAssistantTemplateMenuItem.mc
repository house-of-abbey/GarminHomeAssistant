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
// P A Abbey & J D Abbey, 12 January 2024
//
//
// Description:
//
// Menu button that renders a Home Assistant Template, and optionally triggers a service.
//
// Reference:
//  * https://developers.home-assistant.io/docs/api/rest/
//  * https://www.home-assistant.io/docs/configuration/templating
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics;

class HomeAssistantTemplateMenuItem extends TemplateMenuItem {
    private var mHomeAssistantService as HomeAssistantService;
    private var mService              as Lang.String or Null;
    private var mConfirm              as Lang.Boolean;
    private var mData                 as Lang.Dictionary or Null;

    function initialize(
        label     as Lang.String or Lang.Symbol,
        template  as Lang.String,
        service   as Lang.String or Null,
        confirm   as Lang.Boolean,
        data      as Lang.Dictionary or Null,
        icon      as Graphics.BitmapType or WatchUi.Drawable,
        options   as {
            :alignment as WatchUi.MenuItem.Alignment
        } or Null,
        haService as HomeAssistantService
    ) {
        TemplateMenuItem.initialize(
            label,
            template,
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
            onConfirm(false);
        }
    }

    // NB. Parameter 'b' is ignored
    function onConfirm(b as Lang.Boolean) as Void {
        if (mService != null) {
            mHomeAssistantService.call(mService, mData);
        }
    }

}
