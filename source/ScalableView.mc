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
// J D Abbey & P A Abbey, 28 December 2022
//
//
// Description:
//
// A view with added methods to scale from percentages of scrren size to pixels.
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Math;

class ScalableView extends WatchUi.View {
    private var mScreenWidth;

    function initialize() {
        View.initialize();
    }

    // Convert a fraction expressed as a percentage (%) to a number of pixels for the
    // screen's dimensions.
    //
    // Parameters:
    //  * dc - Device context
    //  * pc - Percentage (%) expressed as a number in the range 0.0..100.0
    //
    // Uses screen width rather than screen height as rectangular screens tend to have
    // height > width.
    //
    function pixelsForScreen(pc as Lang.Float) as Lang.Number {
        if (mScreenWidth == null) {
            mScreenWidth = System.getDeviceSettings().screenWidth;
        }
        return Math.round(pc * mScreenWidth) / 100;
    }
}
