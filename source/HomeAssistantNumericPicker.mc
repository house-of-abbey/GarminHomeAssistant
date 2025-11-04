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
//------------------------------------------------------------

using Toybox.Application;
using Toybox.Lang;
using Toybox.Graphics;
using Toybox.System;
using Toybox.WatchUi;

//! Picker that allows the user to choose a float value
//
class HomeAssistantNumericPicker extends WatchUi.Picker {
    private var mItem as HomeAssistantNumericMenuItem;

    //! Constructor
    //
    public function initialize(
        factory as HomeAssistantNumericFactory,
        haItem  as HomeAssistantNumericMenuItem
    ) {
        mItem      = haItem;
        var picker = mItem.getPicker();
        var min    = (picker.get("min") as Lang.String).toFloat();
        var step   = (picker.get("step") as Lang.String).toFloat();
        var val    = haItem.getValue();

        if (min == null) {
            min = 0.0;
        }
        if (step == null) {
            step = 1.0;
        }

        WatchUi.Picker.initialize({
            :title    => new WatchUi.Text({
                :text => haItem.getLabel(),
                :locX => WatchUi.LAYOUT_HALIGN_CENTER,
                :locY => WatchUi.LAYOUT_VALIGN_BOTTOM
            }),
            :pattern  => [factory],
            :defaults => [((val - min) / step).toNumber()]
        });
    }

    //! Called when the user has completed picking.
    //!
    //! @param value Value user selected
    //! @return true if user is done, false otherwise
    //
    public function onConfirm(value as Lang.Number or Lang.Float) as Void {
        mItem.setValue(value);
        mItem.callAction();
    }
}

//! Responds to a numeric picker selection or cancellation.
//
class HomeAssistantNumericPickerDelegate extends WatchUi.PickerDelegate {
    private var mPicker as HomeAssistantNumericPicker;

    //! Constructor
    //
    public function initialize(picker as HomeAssistantNumericPicker) {
        PickerDelegate.initialize();
        mPicker = picker;
    }

    //! Handle a cancel event from the picker
    //!
    //! @return true if handled, false otherwise
    //
    public function onCancel() as Lang.Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    //! Handle a confirm event from the picker
    //!
    //! @param values The values chosen in the picker
    //! @return true if handled, false otherwise
    //
    public function onAccept(values as Lang.Array) as Lang.Boolean {
        mPicker.onConfirm(values[0]);
        return true;
    }
}
