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
//-----------------------------------------------------------------------------------

using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;

//! Factory that controls which string options can be picked.
(:selectView)
class HomeAssistantSelectFactory extends WatchUi.PickerFactory {
    private var mLabels as Lang.Array<Lang.String>;
    private var mValues as Lang.Array<Lang.String>;

    //! Class Constructor
    //
    public function initialize(
        labels as Lang.Array<Lang.String>,
        values as Lang.Array<Lang.String>
    ) {
        PickerFactory.initialize();
        mLabels = labels;
        mValues = values;
    }

    //! Generate a Drawable instance for an item.
    //
    public function getDrawable(
        index    as Lang.Number,
        selected as Lang.Boolean
    ) as WatchUi.Drawable? {
        var text = "No item";
        if (index >= 0 && index < mLabels.size()) {
            text = mLabels[index];
        }
        return new WatchUi.Text({
            :text  => text,
            :color => Graphics.COLOR_WHITE,
            :locX  => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY  => WatchUi.LAYOUT_VALIGN_CENTER
        });
    }

    //! Get the value of the item at the given index.
    //
    public function getValue(index as Lang.Number) as Lang.Object? {
        if (index >= 0 && index < mValues.size()) {
            return mValues[index];
        }
        return null;
    }

    //! Get the number of picker items.
    //
    public function getSize() as Lang.Number {
        return mLabels.size();
    }
}
