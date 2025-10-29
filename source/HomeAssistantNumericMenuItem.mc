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
// P A Abbey & J D Abbey & @thmichel, 13 October 2025
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics;

//! Menu button with an icon that opens a sub-menu, i.e. group, and optionally renders
//! a Home Assistant Template.
//
class HomeAssistantNumericMenuItem extends HomeAssistantMenuItem {
    private var mHomeAssistantService as HomeAssistantService?;
    private var mService              as Lang.String?;
    private var mConfirm              as Lang.Boolean;
    private var mExit                 as Lang.Boolean;
    private var mPin                  as Lang.Boolean;
    private var mData                 as Lang.Dictionary?;
    private var mPicker               as Lang.Dictionary?;
    private var mValue                as Lang.Number or Lang.Float = 0;
    private var mFormatString         as Lang.String = "%d";

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
        label     as Lang.String or Lang.Symbol,
        template  as Lang.String,
        service   as Lang.String?,
        data      as Lang.Dictionary?,
        picker    as Lang.Dictionary,
        options   as {
            :alignment as WatchUi.MenuItem.Alignment,
            :icon      as Graphics.BitmapType or WatchUi.Drawable or Lang.Symbol,
            :exit      as Lang.Boolean,
            :confirm   as Lang.Boolean,
            :pin       as Lang.Boolean
        }?,
        haService as HomeAssistantService
    ) {
        mService              = service;
        mData                 = data;
        mPicker               = picker;
        mExit                 = options[:exit];
        mConfirm              = options[:confirm];
        mPin                  = options[:pin];
        mLabel                = label;
        mHomeAssistantService = haService;

        HomeAssistantMenuItem.initialize(
            label,
            template,
            {
                :alignment => options[:alignment],
                :icon      => options[:icon]
            }
        );

        if (picker != null) {
            var s = picker["step"];
            if (s != null) {
                var step = s.toFloat() as Lang.Float;
                var dp = 0;
                while (step < 1.0) {
                    step *= 10;
                    dp++;
                    // Assigned inside the loop and in each iteration to avoid clobbering the default '%d'.
                    mFormatString = "%." + dp.toString() + "f";
                }
            }
        }
    }

    function callService() as Void {
        var hasTouchScreen = System.getDeviceSettings().isTouchScreen;
        if (mPin && hasTouchScreen) {
            var pin = Settings.getPin();
            if (pin != null) {
                var pinConfirmationView = new HomeAssistantPinConfirmationView();
                WatchUi.pushView(
                    pinConfirmationView,
                    new HomeAssistantPinConfirmationDelegate({
                        :callback => method(:onConfirm),
                        :pin      => pin,
                        :state    => false,
                        :view     => pinConfirmationView,
                    }),
                    WatchUi.SLIDE_IMMEDIATE
                );
            }
        } else if (mConfirm) {
            if ((! System.getDeviceSettings().phoneConnected ||
                 ! System.getDeviceSettings().connectionAvailable) &&
                Settings.getWifiLteExecutionEnabled()) {
                var dialogMsg = WatchUi.loadResource($.Rez.Strings.WifiLtePrompt) as Lang.String;
                var dialog = new WatchUi.Confirmation(dialogMsg);
                WatchUi.pushView(
                    dialog,
                    new WifiLteExecutionConfirmDelegate({
                        :type    => "service",
                        :service => mService,
                        :data    => mData,
                        :exit    => mExit,
                    }, dialog),
                    WatchUi.SLIDE_LEFT
                );
            } else {
                var view = new HomeAssistantConfirmation();
                WatchUi.pushView(
                    view,
                    new HomeAssistantConfirmationDelegate({
                        :callback         => method(:onConfirm),
                        :confirmationView => view,
                        :state            => false,
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
        var dataAttribute = mPicker["data_attribute"];
        if (dataAttribute == null) {
            //return without call service if no data attribute is set to avoid crash
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return;
        }
        var entity_id = mData["entity_id"];
        if (entity_id == null) {
            //return without call service if no entity_id is set to avoid crash
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return;
        }
        mHomeAssistantService.call(
            mService,
            {
                "entity_id"              => entity_id.toString(),
                dataAttribute.toString() => mValue
            },
            mExit
        );
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    //! Return a numeric menu item's fetch state template.
    //!
    //! @return A string with the menu item's template definition (or null).
    //
    function getNumericTemplate() as Lang.String? {
        var entity_id = mData["entity_id"];
        var attribute = mPicker["attribute"] as Lang.String?;
        if (entity_id == null) {
            return null;
        } else {
            if (attribute == null) {
                return "{{states('" + entity_id.toString() + "')}}";
            } else {
                return "{{state_attr('" + entity_id.toString() + "','" + attribute + "')}}";
            }
        }
    }

    //! Update the menu item's sub label to display the template rendered by Home Assistant.
    //!
    //! @param data The rendered template (typically a string) to be placed in the sub label. This may
    //!             unusually be a number if the SDK interprets the JSON returned by Home Assistant as such.
    //
    public function updateState(data as Lang.String or Lang.Dictionary or Lang.Number or Lang.Float or Null) as Void {
        if (data == null) {
            setSubLabel($.Rez.Strings.Empty);
        } else if(data instanceof Lang.Float) {
            var f = data as Lang.Float;
            setSubLabel(f.format(mFormatString));
        } else if(data instanceof Lang.Number) {
            var f = data.toFloat() as Lang.Float;
            setSubLabel(f.format(mFormatString));
        } else if (data instanceof Lang.String) {
            // This should not happen
            setSubLabel(data);
        } else {
            // The template must return a Float on Numeric value, or the item cannot be formatted locally without error.
            setSubLabel(WatchUi.loadResource($.Rez.Strings.TemplateError) as Lang.String);
        }
        WatchUi.requestUpdate();
    }

    //! Set the Picker's value. Needed to set new value via the Service call
    //!
    //! @param value New value to set.
    //
    public function setValue(value as Lang.Number or Lang.Float) as Void {
        mValue = value;
    }

    //! Get the Picker's value.
    //!
    //! Needed to set new value via the Service call
    //
    public function getValue() as Lang.Number or Lang.Float {
        return mValue;
    }

    //! Get the original 'data' field supplied by the JSON menu.
    //!
    //! @return Dictionary containing the 'data' field.
    //
    public function getData() as Lang.Dictionary {
        return mData;
    }

    // Get the original 'picker' field supplied by the JSON menu.
    //!
    //! @return Dictionary containing the 'picker' field.
    //
    public function getPicker() as Lang.Dictionary {
        return mPicker;
    }
}
