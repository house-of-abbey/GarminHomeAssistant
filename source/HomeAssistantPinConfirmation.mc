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
// P A Abbey & J D Abbey & Someone0nEarth, 31 October 2023
//
//
// Description:
//
// Pin Confirmation dialog and logic.
//
//-----------------------------------------------------------------------------------

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Attention;
import Toybox.Time;

class PinDigit extends WatchUi.Selectable {

    private var mDigit as Number;

    function initialize(digit as Number, stepX as Number, stepY as Number) {
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

    function getDigit() as Number {
        return mDigit;
    }

    class PinDigitButton extends WatchUi.Drawable {
        private var mText    as Number;
        private var mTouched as Boolean = false;

        function initialize(options) {
            Drawable.initialize(options);
            mText    = options.get(:label);
            mTouched = options.get(:touched);
        }

        function draw(dc) {
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

class HomeAssistantPinConfirmationView extends WatchUi.View {

    static const MARGIN_X = 20; // margin on left & right side of screen (overall prettier and works better on round displays)

    var mPinMask as String = "";
        
    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        var stepX = (dc.getWidth() - MARGIN_X * 2) / 3;   // three columns
        var stepY = dc.getHeight() / 5;                   // five rows (first row for masked pin entry)
        var digits = [];
        for (var i=0; i<=9; i++) {
            digits.add(new PinDigit(i, stepX, stepY));
        }
        // draw digits
        setLayout(digits);
    }

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);
        if (mPinMask.length() != 0) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.drawText(dc.getWidth()/2, dc.getHeight()/10, Graphics.FONT_SYSTEM_SMALL, mPinMask, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    function updatePinMask(length as Number) {
        mPinMask = "";
        for (var i=0; i<length; i++) {
            mPinMask += "*";
        }
        requestUpdate();
    }

}


class HomeAssistantPinConfirmationDelegate extends WatchUi.BehaviorDelegate {

    private var mPin           as String;
    private var mEnteredPin    as String;
    private var mConfirmMethod as Method(state as Lang.Boolean) as Void;
    private var mTimer         as Timer.Timer or Null;
    private var mState         as Lang.Boolean;
    private var mFailures      as PinFailures;
    private var mView          as HomeAssistantPinConfirmationView;

    function initialize(callback as Method(state as Lang.Boolean) as Void, state as Lang.Boolean, pin as String, view as HomeAssistantPinConfirmationView) {
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

    function onSelectable(event as SelectableEvent) as Boolean {
        if (mFailures.isLocked()) {
            goBack();
        }
        var instance = event.getInstance();
        if (instance instanceof PinDigit && event.getPreviousState() == :stateSelected) {
            mEnteredPin += instance.getDigit();
            createUserFeedback();
            // System.println("HomeAssitantPinConfirmationDelegate onSelectable() mEnteredPin = " + mEnteredPin);
            if (mEnteredPin.length() == mPin.length()) {
                if (mEnteredPin.equals(mPin)) {
                    mFailures.reset();
                    getApp().getQuitTimer().reset();
                    if (mTimer != null) {
                        mTimer.stop();
                    }
                    mConfirmMethod.invoke(mState);
                    WatchUi.popView(WatchUi.SLIDE_RIGHT);
                } else {
                    error();
                }
            } else {
                resetTimer();
            }
        }
        return true;
    }

    function createUserFeedback() {
        if (Attention has :vibrate && Settings.getVibrate()) {
            Attention.vibrate([new Attention.VibeProfile(25, 25)]);
        }
        mView.updatePinMask(mEnteredPin.length());
    }

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

    function goBack() as Void {
        if (mTimer != null) {
            mTimer.stop();
        }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function error() as Void {
        // System.println("HomeAssistantPinConfirmationDelegate error() Wrong PIN entered");
        mFailures.addFailure();
        if (Attention has :vibrate && Settings.getVibrate()) {
            Attention.vibrate([
                new Attention.VibeProfile(100, 100),
                new Attention.VibeProfile(0, 200),                
                new Attention.VibeProfile(75, 100),
                new Attention.VibeProfile(0, 200),
                new Attention.VibeProfile(50, 100),
                new Attention.VibeProfile(0, 200),
                new Attention.VibeProfile(25, 100)
            ]);
        }
        if (WatchUi has :showToast) {
            showToast($.Rez.Strings.WrongPin, null);
        }
        goBack();
    }

}

class PinFailures {
   
    const STORAGE_KEY_FAILURES as String = "pin_failures";
    const STORAGE_KEY_LOCKED   as String = "pin_locked";
    
    private var mFailures    as Array<Number>;
    private var mLockedUntil as Number or Null;

    function initialize() {
        // System.println("PinFailures initialize() Initializing PIN failures from storage");
        var failures = Application.Storage.getValue(PinFailures.STORAGE_KEY_FAILURES);
        mFailures = (failures == null) ? [] : failures;
        mLockedUntil = Application.Storage.getValue(PinFailures.STORAGE_KEY_LOCKED);
    }

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
                mLockedUntil = Time.now().add(new Time.Duration(Globals.scPinLockTimeMinutes * Gregorian.SECONDS_PER_MINUTE)).value();
                Application.Storage.setValue(STORAGE_KEY_LOCKED, mLockedUntil);
                // System.println("PinFailures addFailure() Locked until " + mLockedUntil);
            }
        }
        Application.Storage.setValue(STORAGE_KEY_FAILURES, mFailures);
    }

    function reset() {
        // System.println("PinFailures reset() Resetting failures");
        mFailures = [];
        mLockedUntil = null;
        Application.Storage.deleteValue(STORAGE_KEY_FAILURES);
        Application.Storage.deleteValue(STORAGE_KEY_LOCKED);
    }

    function getLockedUntilSeconds() as Number {
        return new Time.Moment(mLockedUntil).subtract(Time.now()).value();
    }

    function isLocked() as Boolean {
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