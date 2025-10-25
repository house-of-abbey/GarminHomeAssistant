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
//------------------------------------------------------------

using Toybox.Application;
using Toybox.Lang;
using Toybox.Graphics;
using Toybox.System;
using Toybox.WatchUi;

//! Picker that allows the user to choose a float value
class HomeAssistantNumericPicker extends WatchUi.Picker {

    private var mFactory as HomeAssistantNumericFactory;
    private var mItem as HomeAssistantNumericMenuItem;

    //! Constructor
    public function initialize(factory as HomeAssistantNumericFactory, haItem as HomeAssistantNumericMenuItem) {

        mFactory = factory;


        var pickerOptions = {:pattern=>[mFactory]};
        mItem=haItem;


        var data = mItem.getData();

        var min = 0.0;
        var val = data.get("min");
        if (val != null) {
            min = val.toString().toFloat();
        } 
        var step = 1.0;
        val = data.get("step");
        if (val != null) {
            step = val.toString().toFloat();
        } 
        val = haItem.getValue();
        if (val != null) {
            val = val.toString().toFloat();
        } else {
            // catch missing state to avoid crash
            val = min;
        }
        var index = ((val -min) / step).toNumber();

        pickerOptions[:defaults]  =[index];

        var title = new WatchUi.Text({:text=>haItem.getLabel(), :locX=>WatchUi.LAYOUT_HALIGN_CENTER,
                :locY=>WatchUi.LAYOUT_VALIGN_BOTTOM});
        pickerOptions[:title] = title;


        Picker.initialize(pickerOptions);

    }


    //! Get whether the user is done picking
    //! @param value Value user selected
    //! @return true if user is done, false otherwise
    public function onConfirm(value as Lang.String) as Void {
        mItem.setValue(value);
        mItem.callService();
    }

    
}

//! Responds to a numeric  picker selection or cancellation
class HomeAssistantNumericPickerDelegate extends WatchUi.PickerDelegate {
    private var mPicker as HomeAssistantNumericPicker;

    //! Constructor
    public function initialize(picker as HomeAssistantNumericPicker) {
        PickerDelegate.initialize();
        mPicker = picker;
    }

    //! Handle a cancel event from the picker
    //! @return true if handled, false otherwise
    public function onCancel() as Lang.Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    //! Handle a confirm event from the picker
    //! @param values The values chosen in the picker
    //! @return true if handled, false otherwise
    public function onAccept(values as Lang.Array) as Lang.Boolean {
        var chosenValue = values[0].toString();
        mPicker.onConfirm(chosenValue);
        return true;
    }
}
