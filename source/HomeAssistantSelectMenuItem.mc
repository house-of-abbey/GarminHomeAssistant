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
// @abstractionnl & P A Abbey & J D Abbey, 7 September 2026
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics;

//! Menu button with an icon that opens a select picker and optionally renders
//! a Home Assistant Template.
//
(:selectView)
class HomeAssistantSelectMenuItem extends HomeAssistantMenuItem {
    private var mHomeAssistantService as HomeAssistantService?;
    private var mAction               as Lang.String?;
    private var mConfirm              as Lang.Boolean or Lang.String or Null;
    private var mExit                 as Lang.Boolean;
    private var mPin                  as Lang.Boolean;
    private var mData                 as Lang.Dictionary?;
    private var mDataAttribute        as Lang.String;
    private var mSelectedValue        as Lang.String?;
    private var mPendingValue         as Lang.String?;
    private var mLabels               as Lang.Array<Lang.String>;
    private var mValues               as Lang.Array<Lang.String>;
    private var mHasManualOptions     as Lang.Boolean;

    //! Class Constructor
    //
    function initialize(
        label            as Lang.String or Lang.Symbol,
        template         as Lang.String,
        action           as Lang.String?,
        data             as Lang.Dictionary?,
        dataAttribute    as Lang.String,
        labels           as Lang.Array<Lang.String>,
        values           as Lang.Array<Lang.String>,
        options          as {
            :alignment as WatchUi.MenuItem.Alignment,
            :icon      as Graphics.BitmapType or WatchUi.Drawable or Lang.Symbol,
            :exit      as Lang.Boolean,
            :confirm   as Lang.Boolean,
            :pin       as Lang.Boolean
        }?,
        haService        as HomeAssistantService
    ) {
        mAction               = action;
        mData                 = data;
        mDataAttribute        = dataAttribute;
        mLabels               = labels;
        mValues               = values;
        mHasManualOptions     = labels.size() > 0;
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
    }

    //! Call a Home Assistant action only after checks have been done for confirmation or PIN entry.
    //!
    //! @param value The value to include in the action's data Dictionary in the mDataAttribute field.
    //
    function callAction(value as Lang.String) as Void {
        mPendingValue = value;
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
                        :type   => "action",
                        :action => mAction,
                        :data   => getActionData(value),
                        :exit   => mExit,
                    }, dialog),
                    WatchUi.SLIDE_LEFT
                );
            } else {
                var view;
                if (mConfirm instanceof Lang.String) {
                    view = new HomeAssistantConfirmation(mConfirm as Lang.String?);
                } else {
                    view = new HomeAssistantConfirmation(null);
                }
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
        var value = mPendingValue;
        mPendingValue = null;

        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        WatchUi.requestUpdate();
        if (mAction != null && value != null) {
            var data = getActionData(value);
            if (data != null) {
                mHomeAssistantService.call(
                    mAction,
                    data,
                    mExit
                );
            }
        }
    }

    //! Get the action's data Dictionary to send to Home Assistant with an API call.
    //!
    //! @param value The value to include in the action's data Dictionary in the mDataAttribute field.
    //!
    //! @return A Dictionary containing the action's data to send to Home Assistant with an API call.
    //
    private function getActionData(value as Lang.String) as Lang.Dictionary? {
        var entity_id = null as Lang.String?;
        if (mData != null) {
            entity_id = mData["entity_id"] as Lang.String?;
        }

        if (entity_id == null) {
            return null;
        }

        var data = {} as Lang.Dictionary;
        if (mData != null) {
            var keys = mData.keys();
            for (var i = 0; i < keys.size(); i++) {
                data[keys[i]] = mData[keys[i]];
            }
        }
        data["entity_id"]    = entity_id.toString();
        data[mDataAttribute] = value;
        return data;
    }

    //! Create a Home Assistant template to fetch the current selected value from Home Assistant.
    //!
    //! @return A String containing a template to fetch the currently selected value.
    //
    function getSelectTemplate() as Lang.String? {
        if (mData == null) {
            return null;
        }
        var entity_id = mData["entity_id"] as Lang.String?;
        if (entity_id == null) {
            return null;
        }
        return "{{states('" + entity_id.toString() + "')}}";
    }

    //! Create a Home Assistant Home Assistant template to fetch the available options from entity
    //! attributes (entity-based mode only).
    //!
    //! @return A String containing a template to fetch the the available options.
    //
    function getOptionsTemplate() as Lang.String? {
        if (mHasManualOptions || mData == null) {
            return null;
        }
        var entity_id = mData["entity_id"] as Lang.String?;
        if (entity_id == null) {
            return null;
        }
        return "{{state_attr('" + entity_id.toString() + "','options')|join('\\n')}}";
    }

    public function updateState(data as Lang.String or Lang.Dictionary or Lang.Number or Lang.Float or Null) as Void {
        if (data == null) {
            setSubLabel($.Rez.Strings.Empty);
        } else if (data instanceof Lang.String) {
            setSubLabel(data);
        } else {
            setSubLabel(WatchUi.loadResource($.Rez.Strings.TemplateError) as Lang.String);
        }
        WatchUi.requestUpdate();
    }

    //! Parse newline-joined options string from Home Assistant into label and value arrays.
    //!
    //! @param data A string containing newline-joined options.
    //
    public function updateOptions(data as Lang.String) as Void {
        var labels = [] as Lang.Array<Lang.String>;
        var values = [] as Lang.Array<Lang.String>;
        var str    = data;
        var idx    = str.find("\n");
        while (idx != null) {
            var opt = str.substring(0, idx);
            labels.add(opt);
            values.add(opt);
            str = str.substring(idx + 1, str.length());
            idx = str.find("\n");
        }
        if (str.length() > 0) {
            labels.add(str);
            values.add(str);
        }
        mLabels = labels;
        mValues = values;
    }

    //! Set the selected value to display on the menu item.
    //
    public function setSelectedValue(value as Lang.String?) as Void {
        mSelectedValue = value;
        if (getTemplate() == null && value != null) {
            setSubLabel(value);
            WatchUi.requestUpdate();
        }
    }

    //! Get the selected value displayed on the menu item.
    //!
    //! @return The displayed String or Null.
    //
    public function getSelectedValue() as Lang.String? {
        return mSelectedValue;
    }

    //! Get the array of labels used by the selector.
    //!
    //! @return The array of labels used by the selector.
    //
    public function getLabels() as Lang.Array<Lang.String> {
        return mLabels;
    }

    //! Get the array of values used by the selector.
    //!
    //! @return The array of values used by the selector.
    //
    public function getValues() as Lang.Array<Lang.String> {
        return mValues;
    }

    //! Does the menu item have manually specified options?
    //! See https://github.com/house-of-abbey/GarminHomeAssistant/blob/main/examples/Select.md#manual-options.
    //!
    //! @return `true` if the menu item has manually specified options, otherwise `false`.
    //
    public function hasManualOptions() as Lang.Boolean {
        return mHasManualOptions;
    }

    //! Determine if the selector has any options based on the number of labels in the internal array.
    //!
    //! @return `true` if the array of labels is greater than 0 in length, otherwise `false`.
    //
    public function hasOptions() as Lang.Boolean {
        return mLabels.size() > 0;
    }
}
