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

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! Factory that controls which numbers can be picked
class HomeAssistantNumericFactory extends WatchUi.PickerFactory {
    // define default values in case not contained in data
    private var mStart as Lang.Float = 0.0;
    private var mStop as Lang.Float = 100.0;
    private var mStep as Lang.Float = 1.0;
    private var mFormatString as Lang.String = "%.2f";

    //! Class Constructor
    //!
    public function initialize(data as Lang.Dictionary) {
        PickerFactory.initialize();

        // Get values from data

        var val = data.get("min");
        if (val != null) {
            mStart = val.toString().toFloat();
        }
        val = data.get("max");
        if (val != null) {
            mStop = val.toString().toFloat();
        } 
        val = data.get("step");
        if (val != null) {
            mStep = val.toString().toFloat();
        } 
       val = data.get("display_format");
        if (val != null) {
            mFormatString = val.toString();
        } 

    }

    //! Get the index of a number item
    //! @param value The number to get the index of
    //! @return The index of the number
    public function getIndex(value as Float) as Number {
        return ((value / mStep) - mStart).toNumber();
    }

    //! Generate a Drawable instance for an item
    //! @param index The item index
    //! @param selected true if the current item is selected, false otherwise
    //! @return Drawable for the item
    public function getDrawable(index as Number, selected as Boolean) as Drawable? {
        var value = getValue(index);
        var text = "No item";
        if (value instanceof Lang.Float) {
            text = value.format(mFormatString);
        }
        return new WatchUi.Text({:text=>text, :color=>Graphics.COLOR_WHITE, 
            :locX=>WatchUi.LAYOUT_HALIGN_CENTER, :locY=>WatchUi.LAYOUT_VALIGN_CENTER});
    }

    //! Get the value of the item at the given index
    //! @param index Index of the item to get the value of
    //! @return Value of the item
    public function getValue(index as Number) as Object? {
        return mStart + (index * mStep);
    }

    //! Get the number of picker items
    //! @return Number of items
    public function getSize() as Number {
        return ((mStop - mStart) / mStep).toNumber() + 1;
    }

}
