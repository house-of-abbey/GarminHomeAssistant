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
    static const scDebug                  = false;
    // There's a danger this time is device sensitive.
    static const scMenuItemUpdateInterval =  100; // ms, 100 ms seems okay for Venu2
    static const scAlertTimeout           = 2000; // ms
    static const scTapTimeout             = 1000; // ms
}
