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

using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Timer;
using Toybox.Attention;
using Toybox.Time;

//! Pin digit used for number 0..9
//
class PinDigit extends WatchUi.Selectable {

    private var mDigit as Lang.Number;

    //! Class Constructor
    //!
    //! @param digit The digit this instance of the class represents and to display.
    //! @param stepX Horizontal spacing.
    //! @param stepY Vertical spacing.
    //
    function initialize(digit as Lang.Number, stepX as Lang.Number, stepY as Lang.Number) {
        var marginX = stepX * 0.05; // 5% margin on all sides
        var marginY = stepY * 0.05; 
        var x = (digit == 0) ? stepX : stepX * ((digit+2) % 3); // layout '0' in 2nd col, others ltr in 3 columns
        x += marginX + HomeAssistantPinConfirmationView.MARGIN_X;
        var y = (digit == 0) ? stepY * 4 : (digit <= 3) ? stepY : (digit <=6) ? stepY * 2 : stepY * 3; // layout '0' in bottom row (5), others top to bottom in 3 rows (2-4) (row 1 is reserved for masked pin)
        y += marginY;
        var width  = stepX - (marginX * 2);
        var height = stepY - (marginY * 2);

        var button = new PinDigitButton({
            :width  => width,
            :height => height,
            :label  => digit
        });

        var buttonTouched = new PinDigitButton({
            :width   => width,
            :height  => height,
            :label   => digit,
            :touched => true
        });

        // initialize selectable
        Selectable.initialize({
            :stateDefault     => button,
            :stateHighlighted => buttonTouched,
            :locX             => x,
            :locY             => y,
            :width            => width,
            :height           => height
        });

        mDigit = digit;
    }

    //! Return the digit 0..9 represented by this button
    //
    function getDigit() as Lang.Number {
        return mDigit;
    }

    //! Customised drawing of a PIN digit's button.
    //
    class PinDigitButton extends WatchUi.Drawable {
        private var mText    as Lang.Number;
        private var mTouched as Lang.Boolean = false;

        //! Class Constructor
        //!
        //! @param options See `Drawable.initialize()`, but with `:label` and `:touched` added.<br>
        //!   &lbrace;<br>
        //!   &emsp; :label   as Lang.Number,  // The digit 0..9 to display<br>
        //!   &emsp; :touched as Lang.Boolean, // Should the digit be filled to indicate it has been pressed?<br>
        //!   &emsp; + those required by `Drawable.initialize()`<br>
        //!   &rbrace;
        //
        function initialize(options) {
            Drawable.initialize(options);
            mText    = options.get(:label);
            mTouched = options.get(:touched);
        }

        //! Draw the PIN digit button.
        //!
        //! @param dc Device context
        //
        function draw(dc as Graphics.Dc) {
            if (mTouched) {
                dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_ORANGE);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
            }
            dc.fillCircle(locX + width / 2, locY + height / 2, height / 2); // circle fill
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_LT_GRAY);
            dc.setPenWidth(3);
            dc.drawCircle(locX + width / 2, locY + height / 2, height / 2); // circle outline
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(locX+width / 2, locY+height / 2, Graphics.FONT_TINY, mText, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER); // center text in circle
        }

    }

}


//! Pin Confirmation dialog and logic.
//
class HomeAssistantPinConfirmationView extends WatchUi.View {

    //! Margin on left & right side of screen (overall prettier and works better on round displays)
    static const MARGIN_X = 20;
    //! Indicates how many digits have been entered so far.
    var mPinMask as Lang.String = "";

    //! Class Constructor
    //
    function initialize() {
        View.initialize();
    }

    //! Construct the view.
    //!
    //! @param dc Device context
    //
    function onLayout(dc as Graphics.Dc) as Void {
        var stepX = (dc.getWidth() - MARGIN_X * 2) / 3;   // three columns
        var stepY = dc.getHeight() / 5;                   // five rows (first row for masked pin entry)
        var digits = [];
        for (var i=0; i<=9; i++) {
            digits.add(new PinDigit(i, stepX, stepY));
        }
        // draw digits
        setLayout(digits);
    }

    //! Update the view.
    //!
    //! @param dc Device context
    //
    function onUpdate(dc as Graphics.Dc) as Void {
        View.onUpdate(dc);
        if (mPinMask.length() != 0) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.drawText(dc.getWidth()/2, dc.getHeight()/10, Graphics.FONT_SYSTEM_SMALL, mPinMask, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    //! Update the PIN mask displayed.
    //!
    //! @param length Number of `*` characters to use for the mask string.
    //
    function updatePinMask(length as Lang.Number) {
        mPinMask = "";
        for (var i=0; i<length; i++) {
            mPinMask += "*";
        }
        requestUpdate();
    }

}


//! Delegate for the HomeAssistantPinConfirmationView.
//
class HomeAssistantPinConfirmationDelegate extends WatchUi.BehaviorDelegate {

    private var mPin           as Lang.String;
    private var mEnteredPin    as Lang.String;
    private var mConfirmMethod as Method(state as Lang.Boolean) as Void;
    private var mTimer         as Timer.Timer or Null;
    private var mState         as Lang.Boolean;
    private var mFailures      as PinFailures;
    private var mView          as HomeAssistantPinConfirmationView;

    //! Class Constructor
    //!
    //! @param callback Method to call on confirmation.
    //! @param state    Current state of a toggle button.
    //! @param pin      PIN to be matched.
    //! @param view     PIN confirmation view.
    //
    function initialize(
        callback as Method(state as Lang.Boolean) as Void,
        state    as Lang.Boolean,
        pin      as Lang.String,
        view     as HomeAssistantPinConfirmationView
    ) {
        BehaviorDelegate.initialize();
        mFailures      = new PinFailures();
        if (mFailures.isLocked()) {
            var msg = WatchUi.loadResource($.Rez.Strings.PinInputLocked) + " " +
                      mFailures.getLockedUntilSeconds() + " " + 
                      WatchUi.loadResource($.Rez.Strings.Seconds);
            WatchUi.showToast(msg, {});
        }
        mPin           = pin;
        mEnteredPin    = "";
        mConfirmMethod = callback;
        mState         = state;
        mView          = view;
        resetTimer();
    }

    //! Add another entered digit to the "PIN so far". When it is long enough verify the PIN is correct and the
    //! invoke the supplied call back function.
    //!
    //! @param event The digit pressed by the user tapping the screen.
    //
    function onSelectable(event as WatchUi.SelectableEvent) as Lang.Boolean {
        if (mFailures.isLocked()) {
            goBack();
        }
        var instance = event.getInstance();
        if (instance instanceof PinDigit && event.getPreviousState() == :stateSelected) {
            mEnteredPin += instance.getDigit();
            createUserFeedback();
            // System.println("HomeAssistantPinConfirmationDelegate onSelectable() mEnteredPin = " + mEnteredPin);
            if (mEnteredPin.length() == mPin.length()) {
                if (mEnteredPin.equals(mPin)) {
                    mFailures.reset();
                    getApp().getQuitTimer().reset();
                    if (mTimer != null) {
                        mTimer.stop();
                    }
                    WatchUi.popView(WatchUi.SLIDE_RIGHT);
                    mConfirmMethod.invoke(mState);
                } else {
                    error();
                }
            } else {
                resetTimer();
            }
        }
        return true;
    }

    //! Hepatic feedback.
    //
    function createUserFeedback() {
        if (Attention has :vibrate && Settings.getVibrate()) {
            Attention.vibrate([new Attention.VibeProfile(25, 25)]);
        }
        mView.updatePinMask(mEnteredPin.length());
    }

    //! A timer is used to clear the PIN entry view if digits are not pressed. So each time a digit is pressed the
    //! timer is reset.
    //
    function resetTimer() {
        var timeout = Settings.getConfirmTimeout(); // ms
        if (timeout > 0) {
            if (mTimer != null) {
                mTimer.stop();
            } else {
                mTimer = new Timer.Timer();
            }
            mTimer.start(method(:goBack), timeout, false);
        }
    }

    //! Cancel PIN entry.
    //
    function goBack() as Void {
        if (mTimer != null) {
            mTimer.stop();
        }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    //! Hepatic feedback for a wrong PIN and cancel entry.
    //
    function error() as Void {
        // System.println("HomeAssistantPinConfirmationDelegate error() Wrong PIN entered");
        mFailures.addFailure();
        if (Attention has :vibrate && Settings.getVibrate()) {
            Attention.vibrate([
                new Attention.VibeProfile(100, 100),
                new Attention.VibeProfile(  0, 200),                
                new Attention.VibeProfile( 75, 100),
                new Attention.VibeProfile(  0, 200),
                new Attention.VibeProfile( 50, 100),
                new Attention.VibeProfile(  0, 200),
                new Attention.VibeProfile( 25, 100)
            ]);
        }
        if (WatchUi has :showToast) {
            showToast($.Rez.Strings.WrongPin, null);
        }
        goBack();
    }

}


//! Manage PIN entry failures to try and prevent brute force exhaustion by inserting delays in retries.
//
class PinFailures {
   
    const STORAGE_KEY_FAILURES as Lang.String = "pin_failures";
    const STORAGE_KEY_LOCKED   as Lang.String = "pin_locked";
    
    private var mFailures    as Lang.Array<Lang.Number>;
    private var mLockedUntil as Lang.Number or Null;

    //! Class Constructor
    //
    function initialize() {
        // System.println("PinFailures initialize() Initializing PIN failures from storage");
        var failures = Application.Storage.getValue(PinFailures.STORAGE_KEY_FAILURES);
        mFailures = (failures == null) ? [] : failures;
        mLockedUntil = Application.Storage.getValue(PinFailures.STORAGE_KEY_LOCKED);
    }

    //! Record a PIN entry failure. If too many have occurred lock the application.
    //
    function addFailure() {
        mFailures.add(Time.now().value());
        // System.println("PinFailures addFailure() " + mFailures.size() + " PIN confirmation failures recorded");
        if (mFailures.size() >= Globals.scPinMaxFailures) {
            // System.println("PinFailures addFailure() Too many failures detected");
            var oldestFailureOutdate = new Time.Moment(mFailures[0]).add(new Time.Duration(Globals.scPinMaxFailureMinutes * 60));
            // System.println("PinFailures addFailure() Oldest failure: " + oldestFailureOutdate.value() + " Now:" + Time.now().value());
            if (new Time.Moment(Time.now().value()).greaterThan(oldestFailureOutdate)) {
                // System.println("PinFailures addFailure() Pruning oldest outdated failure");
                mFailures = mFailures.slice(1, null);
            } else {
                mFailures = [];
                mLockedUntil = Time.now().add(new Time.Duration(Globals.scPinLockTimeMinutes * Time.Gregorian.SECONDS_PER_MINUTE)).value();
                Application.Storage.setValue(STORAGE_KEY_LOCKED, mLockedUntil);
                // System.println("PinFailures addFailure() Locked until " + mLockedUntil);
            }
        }
        Application.Storage.setValue(STORAGE_KEY_FAILURES, mFailures);
    }

    //! Clear the record of previous PIN entry failures, e.g. because the correct PIN has now been entered
    //! within tolerance.
    //
    function reset() {
        // System.println("PinFailures reset() Resetting failures");
        mFailures = [];
        mLockedUntil = null;
        Application.Storage.deleteValue(STORAGE_KEY_FAILURES);
        Application.Storage.deleteValue(STORAGE_KEY_LOCKED);
    }

    //! Retrieve the remaining time the application must be locked out for.
    //
    function getLockedUntilSeconds() as Lang.Number {
        return new Time.Moment(mLockedUntil).subtract(Time.now()).value();
    }

    //! Is the application currently locked out? If the application is no longer locked out, then clear the
    //! stored values used to determine this state.
    //!
    //! @return Boolean indicating if the application is currently locked out.
    //
    function isLocked() as Lang.Boolean {
        if (mLockedUntil == null) {
            return false;            
        }
        var isLocked = new Time.Moment(Time.now().value()).lessThan(new Time.Moment(mLockedUntil));
        if (!isLocked) {
            mLockedUntil = null;
            Application.Storage.deleteValue(STORAGE_KEY_LOCKED);
        }
        return isLocked;
    }

}