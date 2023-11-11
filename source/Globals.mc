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
// P A Abbey & J D Abbey, 31 October 2023
//
//
// Description:
//
// Home Assistant centralised constants.
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;

class Globals {
    // Enable printing of messages to the debug console (don't make this a Property
    // as the messages can't be read from a watch!)
    static const debug          = false;
    static const updateInterval = 10;    // seconds
    static const alertTimeout   = 2000; // ms
    static const tapTimeout     = 1000; // ms
}
