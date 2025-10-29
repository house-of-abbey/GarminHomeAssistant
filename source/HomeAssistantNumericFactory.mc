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

using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;

//! Factory that controls which numbers can be picked
class HomeAssistantNumericFactory extends WatchUi.PickerFactory {
    // define default values in case not contained in data
    private var mStart        as Lang.Float  = 0.0;
    private var mStop         as Lang.Float  = 100.0;
    private var mStep         as Lang.Float  = 1.0;
    private var mFormatString as Lang.String = "%d";

    //! Class Constructor
    //
    public function initialize(picker as Lang.Dictionary) {
        PickerFactory.initialize();

        // Get values from data
        var val = picker["min"];
        if (val != null) {
            mStart = val.toString().toFloat();
        }
        val = picker["max"];
        if (val != null) {
            mStop = val.toString().toFloat();
        } 
        val = picker["step"];
        if (val != null) {
            mStep = val.toString().toFloat();
        } 
        if (mStep > 0.0) {
            var s = mStep;
            var dp = 0;
            while (s < 1.0) {
                s *= 10;
                dp++;
                // Assigned inside the loop and in each iteration to avoid clobbering the default '%d'.
                mFormatString = "%." + dp.toString() + "f";
            }
        } else {
            // The JSON menu definition defined a step size of 0, revert to the default.
            mStep = 1.0;
        }
    }

    //! Generate a Drawable instance for an item
    //!
    //! @param index The item index
    //! @param selected true if the current item is selected, false otherwise
    //! @return Drawable for the item
    //
    public function getDrawable(
        index    as Lang.Number,
        selected as Lang.Boolean
    ) as WatchUi.Drawable? {
        var value = getValue(index);
        var text = "No item";
        if (value instanceof Lang.Float) {
            text = value.format(mFormatString);
        }
        return new WatchUi.Text({
            :text  => text,
            :color => Graphics.COLOR_WHITE,
            :locX  => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY  => WatchUi.LAYOUT_VALIGN_CENTER
        });
    }

    //! Get the value of the item at the given index
    //!
    //! @param index Index of the item to get the value of
    //! @return Value of the item
    //
    public function getValue(index as Lang.Number) as Lang.Object? {
        return mStart + (index * mStep);
    }

    //! Get the number of picker items
    //!
    //! @return Number of items
    //
    public function getSize() as Lang.Number {
        return ((mStop - mStart) / mStep).toNumber() + 1;
    }
}
