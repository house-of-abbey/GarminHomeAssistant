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

    function initialize(digit as Number, halfX as Number, halfY as Number) {
        var margin = 40;
        var x = (digit % 2 == 1) ? 0 + margin : halfX + margin; // place even numbers in right half, odd in left half
        var y = (digit < 3) ? 0 + margin : halfY + margin; // place 1&2 on top half, 3&4 on bottom half
        var width = halfX - 2 * margin;
        var height = halfY - 2 * margin;

        // build text area
        var textArea = new WatchUi.TextArea({
            :text=>digit.format("%d"),
            :color=>Graphics.COLOR_WHITE,
            :font=>[Graphics.FONT_NUMBER_THAI_HOT, Graphics.FONT_NUMBER_HOT, Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_NUMBER_MILD],
            :width=>width,
            :height=>height,
            :justification=>Graphics.TEXT_JUSTIFY_CENTER
        });

        // initialize selectable
        Selectable.initialize({
            :stateDefault=>textArea,
            :locX =>x,
            :locY=>y,
            :width=>width,
            :height=>height
        });

        mDigit = digit;

    }

    function getDigit() as Number {
        return mDigit;
    }

}

class HomeAssistantPinConfirmationView extends WatchUi.View {
        
    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        var halfX = dc.getWidth()/2;
        var halfY = dc.getHeight()/2;
        // draw digits
        setLayout([
            new PinDigit(1, halfX, halfY),
            new PinDigit(2, halfX, halfY),
            new PinDigit(3, halfX, halfY),
            new PinDigit(4, halfX, halfY)
        ]);
    }

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);
        // draw cross
        var halfX = dc.getWidth()/2;
        var halfY = dc.getHeight()/2;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawRectangle(halfX, dc.getHeight() * 0.1, 2, dc.getHeight() * 0.8);
        dc.drawRectangle(dc.getWidth() * 0.1, halfY, dc.getWidth() * 0.8, 2);
    }

}


class HomeAssistantPinConfirmationDelegate extends WatchUi.BehaviorDelegate {

    private var mPin           as Array<Char>;
    private var mCurrentIndex  as Number;
    private var mConfirmMethod as Method(state as Lang.Boolean) as Void;
    private var mTimer         as Timer.Timer or Null;
    private var mState         as Lang.Boolean;
    private var mFailures      as PinFailures;

    function initialize(callback as Method(state as Lang.Boolean) as Void, state as Lang.Boolean, pin as String) {
        BehaviorDelegate.initialize();
        mFailures      = new PinFailures();
        if (mFailures.isLocked()) {
            WatchUi.showToast("PIN input locked for " + mFailures.getLockedUntilSeconds() + " seconds", {});
        }
        mPin           = pin.toCharArray();
        mCurrentIndex  = 0;
        mConfirmMethod = callback;
        mState         = state;
        resetTimer();
    }

    function onSelectable(event as SelectableEvent) as Boolean {
        if (mFailures.isLocked()) {
            goBack();
        }
        var instance = event.getInstance();
        if (instance instanceof PinDigit && event.getPreviousState() == :stateSelected) {
            if (Attention has :vibrate && Settings.getVibrate()) {
                Attention.vibrate([new Attention.VibeProfile(25, 25)]);
            }
            var currentDigit = mPin[mCurrentIndex].toString().toNumber(); // this is ugly, but apparently the only way for char<->number conversions
            if (currentDigit != null && currentDigit == instance.getDigit()) { 
                // System.println("Pin digit " + (mCurrentIndex+1) + " matches");
                if (mCurrentIndex == mPin.size()-1) {
                    mFailures.reset();
                    getApp().getQuitTimer().reset();
                    if (mTimer != null) {
                        mTimer.stop();
                    }
                    mConfirmMethod.invoke(mState);
                    WatchUi.popView(WatchUi.SLIDE_RIGHT);
                } else {
                    mCurrentIndex++;
                    resetTimer();
                }
            } else {
                // System.println("Pin digit " + (mCurrentIndex+1) + " doesn't match");
                error();
            }
        }
        return true;
    }

    function resetTimer() {
        var timeout = Settings.getConfirmTimeout(); // ms
        if (timeout > 0) {
            if (mTimer != null) {
                mTimer.stop();
            } else {
                mTimer = new Timer.Timer();
            }
            mTimer.start(method(:goBack), timeout, true);
        }
    }

    function goBack() as Void {
        if (mTimer != null) {
            mTimer.stop();
        }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function error() as Void {
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
        goBack();
    }

}

class PinFailures {

    const MAX_FAILURES         as Number = 5;              // maximum number of failed pin confirmation attemps allwed in ...
    const MAX_FAILURE_MINUTES  as Number = 2;              // ... this number of minutes before pin confirmation is locked for ...
    const LOCK_TIME_MINUTES    as Number = 10;             // ... this number of minutes
    
    const STORAGE_KEY_FAILURES as String = "pin_failures";
    const STORAGE_KEY_LOCKED   as String = "pin_locked";
    
    private var mFailures    as Array<Number>;
    private var mLockedUntil as Number or Null;

    function initialize() {
        // System.println("Initializing PIN failures from storage");
        var failures = Application.Storage.getValue(PinFailures.STORAGE_KEY_FAILURES);
        mFailures = (failures == null) ? [] : failures;
        mLockedUntil = Application.Storage.getValue(PinFailures.STORAGE_KEY_LOCKED);
    }

    function addFailure() {
        mFailures.add(Time.now().value());
        // System.println(mFailures.size() + " PIN confirmation failures recorded");
        if (mFailures.size() >= MAX_FAILURES) {
            // System.println("Too many failures detected");
            var oldestFailureOutdate = new Time.Moment(mFailures[0]).add(new Time.Duration(MAX_FAILURE_MINUTES * 60));
            // System.println("Oldest failure: " + oldestFailureOutdate.value() + " Now:" + Time.now().value());
            if (new Time.Moment(Time.now().value()).greaterThan(oldestFailureOutdate)) {
                // System.println("Pruning oldest outdated failure");
                mFailures = mFailures.slice(1, null);
            } else {
                mFailures = [];
                mLockedUntil = Time.now().add(new Time.Duration(LOCK_TIME_MINUTES * Gregorian.SECONDS_PER_MINUTE)).value();
                Application.Storage.setValue(STORAGE_KEY_LOCKED, mLockedUntil);
                // System.println("Locked until " + mLockedUntil);
            }
        }
        Application.Storage.setValue(STORAGE_KEY_FAILURES, mFailures);
    }

    function reset() {
        // System.println("Resetting failures");
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