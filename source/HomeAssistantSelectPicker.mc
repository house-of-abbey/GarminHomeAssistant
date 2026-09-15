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

using Toybox.Application;
using Toybox.Lang;
using Toybox.Graphics;
using Toybox.System;
using Toybox.WatchUi;

//! Picker that allows the user to choose a string option.
//
(:selectView)
class HomeAssistantSelectPicker extends WatchUi.Picker {
    private var mItem as HomeAssistantSelectMenuItem;

    //! Constructor
    //
    public function initialize(
        factory as HomeAssistantSelectFactory,
        haItem  as HomeAssistantSelectMenuItem
    ) {
        mItem = haItem;
        var selected = haItem.getSelectedValue();
        var values   = haItem.getValues();
        var defIdx   = 0;

        if (selected != null) {
            for (var i = 0; i < values.size(); i++) {
                if (values[i].equals(selected)) {
                    defIdx = i;
                    break;
                }
            }
        }

        WatchUi.Picker.initialize({
            :title    => new WatchUi.Text({
                :text => haItem.getLabel(),
                :locX => WatchUi.LAYOUT_HALIGN_CENTER,
                :locY => WatchUi.LAYOUT_VALIGN_BOTTOM
            }),
            :pattern  => [factory],
            :defaults => [defIdx]
        });
    }

    //! Called when the user has completed picking.
    //!
    //! @param value A string representing the selected item.
    //
    public function onConfirm(value as Lang.String) as Void {
        mItem.setSelectedValue(value);
        mItem.callAction(value);
    }
}

//! Responds to a select picker selection or cancellation.
//
(:selectView)
class HomeAssistantSelectPickerDelegate extends WatchUi.PickerDelegate {
    private var mPicker as HomeAssistantSelectPicker;

    //! Constructor
    //
    public function initialize(picker as HomeAssistantSelectPicker) {
        PickerDelegate.initialize();
        mPicker = picker;
    }

    //! Handle a cancel event from the picker.
    //!
    //! @return `true` (always) if the event was handled, otherwise `false`.
    //
    public function onCancel() as Lang.Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    //! Handle a confirm event from the picker.
    //!
    //! @param values The values chosen in the Picker, where only the first element is populated
    //!               for this Picker.
    //!
    //! @return `true` (always) if the event was handled, otherwise `false`.
    //
    public function onAccept(values as Lang.Array) as Lang.Boolean {
        mPicker.onConfirm(values[0]);
        return true;
    }
}
