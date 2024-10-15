import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Attention;

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

    function initialize(callback as Method(state as Lang.Boolean) as Void, state as Lang.Boolean, pin as String) {
        BehaviorDelegate.initialize();
        mPin = pin.toCharArray();
        mCurrentIndex = 0;
        mConfirmMethod = callback;
        mState         = state;
        resetTimer();
    }

    function onSelectable(event as SelectableEvent) as Boolean {
        var instance = event.getInstance();
        if (instance instanceof PinDigit && event.getPreviousState() == :stateSelected) {
            var currentDigit = getTranscodedCurrentDigit();
            if (currentDigit != null && currentDigit == instance.getDigit()) { 
                // System.println("Pin digit " + (mCurrentIndex+1) + " matches");
                if (mCurrentIndex == mPin.size()-1) {
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
                // TODO: add maxFailures counter & protection
                error();
            }
        }
        return true;
    }

    function getTranscodedCurrentDigit() as Number {
        var currentDigit = mPin[mCurrentIndex].toString().toNumber(); // this is ugly, but apparently the only way for char<->number comparisons
        // TODO: Transcode digit using a pin mask for additional security
        return currentDigit;
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