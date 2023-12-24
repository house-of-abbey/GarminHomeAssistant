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
// P A Abbey & J D Abbey & Someone0nEarth, 20 December 2023
//
//
// Description:
//
// A tedious diversion intended to make it possible to have the same source code for
// both a widget and an application. This file provides a single constant to
// determine which, and then the source file is conditionally included by the each
// .jungle file.
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;

class WidgetApp {
    static const isWidget = true;
}
