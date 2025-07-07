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
// P A Abbey & J D Abbey & Someone0nEarth & moesterheld, 31 October 2023
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;

//! Home Assistant centralised constants.
//
(:glance)
class Globals {
    //! Alert is a toast at the top of the watch screen, it stays present until tapped
    //! or this timeout has expired.
    static const scAlertTimeout          = 2000; // ms

    //! Time to let the existing HTTP responses get serviced after a
    //! `Communications.NETWORK_RESPONSE_OUT_OF_MEMORY` response code.
    static const scApiBackoff            = 2000; // ms

    //! Needs to be long enough to enable a "double ESC" to quit the application from
    //! an ErrorView.
    static const scApiResume             = 200;  // ms

    //! Warn the user after fetching the menu if their watch is low on memory before the device crashes.
    static const scLowMem                = 0.90; // percent as a fraction.

    //! Constant for PIN confirmation dialog.<br>
    //! Maximum number of failed PIN confirmation attempts allowed in `scPinMaxFailureMinutes`.
    static const scPinMaxFailures        = 5;

    //! Constant for PIN confirmation dialog.<br>
    //! Period in minutes during which no more than `scPinMaxFailures` PIN attempts are tolerated.
    static const scPinMaxFailureMinutes  = 2;

    //! Constant for PIN confirmation dialog.<br>
    //! Lock out time in minutes after a failed PIN entry.
    static const scPinLockTimeMinutes    = 10;
}
