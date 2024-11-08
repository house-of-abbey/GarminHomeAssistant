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
    private var mTemplate             as Lang.String;
    private var mService              as Lang.String or Null;
    private var mConfirm              as Lang.Boolean;
    private var mData                 as Lang.Dictionary or Null;
    private var mPin                  as Lang.String or Null;

    function initialize(
        label     as Lang.String or Lang.Symbol,
        template  as Lang.String,
        service   as Lang.String or Null,
        confirm   as Lang.Boolean,
        pin       as Lang.String or Null,
        data      as Lang.Dictionary or Null,
        icon      as Graphics.BitmapType or WatchUi.Drawable,
        options   as {
            :alignment as WatchUi.MenuItem.Alignment
        } or Null,
        haService as HomeAssistantService
    ) {
        WatchUi.IconMenuItem.initialize(
            label,
            null,
            null,
            icon,
            options
        );

        mHomeAssistantService = haService;
        mTemplate             = template;
        mService              = service;
        mConfirm              = confirm;
        mData                 = data;
        mPin                  = pin;
    }

    function hasTemplate() as Lang.Boolean {
        return mTemplate != null;
    }

    function buildTemplate() as Lang.String or Null {
        return mTemplate;
    }

    function updateState(data as Lang.String or Lang.Dictionary or Null) as Void {
        if (data == null) {
            setSubLabel($.Rez.Strings.Empty);
        } else if(data instanceof Lang.String) {
            setSubLabel(data);
        } else if(data instanceof Lang.Dictionary) {
            // System.println("HomeAsistantTemplateMenuItem updateState() data = " + data);
            if (data.get("error") != null) {
                setSubLabel($.Rez.Strings.TemplateError);
            } else {
                setSubLabel($.Rez.Strings.PotentialError);
            }
        } else {
            // The template must return a Lang.String, a number can be either integer or float and hence cannot be formatted locally without error.
            setSubLabel(WatchUi.loadResource($.Rez.Strings.TemplateError) as Lang.String);
        }
        WatchUi.requestUpdate();
    }

    function callService() as Void {
        var hasTouchScreen = System.getDeviceSettings().isTouchScreen;
        if (mPin != null && hasTouchScreen) {
            WatchUi.pushView(
                new HomeAssistantPinConfirmationView(),
                new HomeAssistantPinConfirmationDelegate(method(:onConfirm), false, mPin),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (mConfirm || (mPin!=null && !hasTouchScreen)) {
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
