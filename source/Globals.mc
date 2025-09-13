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
    static const scAlertTimeoutMs       = 2000; // ms

    //! Time to let the existing HTTP responses get serviced after a
    //! `Communications.NETWORK_RESPONSE_OUT_OF_MEMORY` response code.
    static const scApiBackoffMs         = 2000; // ms

    //! Needs to be long enough to enable a "double ESC" to quit the application from
    //! an ErrorView.
    static const scApiResumeMs          = 200;  // ms

    //! Threshold of memory usage (guessed) to consider a device unable to automatically check
    //! for a more recent menu due to insufficient memory.
    static const scLowMem               = 0.85;  // Fraction of total memory used.

    //! Constant for PIN confirmation dialog.<br>
    //! Maximum number of failed PIN confirmation attempts allowed in `scPinMaxFailureMinutes`.
    static const scPinMaxFailures       = 5;

    //! Constant for PIN confirmation dialog.<br>
    //! Period in minutes during which no more than `scPinMaxFailures` PIN attempts are tolerated.
    static const scPinMaxFailureMinutes = 2;

    //! Constant for PIN confirmation dialog.<br>
    //! Lock out time in minutes after a failed PIN entry.
    static const scPinLockTimeMinutes   = 10;

    //! After running a task by Wi-Fi/LTE synchronisation the periodic updates need to resume. This
    //! is the delay between synchronisation completion and resumption of updates.
    static const wifiPollResumeDelayMs  = 2000; // ms

    //! After running a task by Wi-Fi/LTE synchronisation the if the menu item requests to quit the
    //! application, this is the delay to wait after synchronisation completion before quitting.
    //! Failure to wait causes the transfer to indicate a failure.
    static const wifiQuitDelayMs        = 5000; // ms
}
