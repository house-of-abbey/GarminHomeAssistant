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
// J D Abbey & P A Abbey, 28 December 2022
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Math;

//! A view that provides a common method 'pixelsForScreen' to make Views easier to layout on different
//! sized watch screens.
//
class ScalableView extends WatchUi.View {
    //! Retain the local screen width for efficiency
    private var mScreenWidth;

    //! Class Constructor
    //
    function initialize() {
        View.initialize();
        mScreenWidth = System.getDeviceSettings().screenWidth;
    }

    //! Convert a fraction expressed as a percentage (%) to a number of pixels for the
    //! screen's dimensions.
    //!
    //! Uses screen width rather than screen height as rectangular screens tend to have
    //! height > width.
    //!
    //! @param pc Percentage (%) expressed as a number in the range 0.0..100.0
    //!
    //! @return Number of pixels for the screen's dimensions for a fraction expressed as a percentage (%).
    //!
    function pixelsForScreen(pc as Lang.Float) as Lang.Number {
        return Math.round(pc * mScreenWidth) / 100;
    }
}
