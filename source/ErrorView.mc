//-----------------------------------------------------------------------------------
//
// Distributed under MIT Licence
//   See https://github.com/house-of-abbey/GarminHomeAssistantWidget/blob/main/LICENSE.
//
//-----------------------------------------------------------------------------------
//
// GarminHomeAssistantWidget is a Garmin IQ widget written in Monkey C. The source code is provided at:
//            https://github.com/house-of-abbey/GarminHomeAssistantWidget.
//
// J D Abbey & P A Abbey, 28 December 2022
//
//
// Description:
//
// ErrorView provides a means to present application errors to the user. These
// should not happen of course... but they do, so best make sure errors can be
// reported.
//
// Designed so that a single ErrorView is used for all errors and hence can ensure
// that only the first call to display is honoured until the view is dismissed.
// This compensates for older devices not being able to call WatchUi.getCurrentView()
// due to not supporting API level 3.4.0.
//
// Usage:
//   1) ErrorView.show("Error message");
//   2) return ErrorView.create("Error message"); // as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>
//
//-----------------------------------------------------------------------------------

using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Communications;
using Toybox.Timer;

class ErrorView extends ScalableView {
    private static const scErrorIconMargin as Lang.Float = 7f;
    private var mText            as Lang.String          = "";
    private var mDelegate        as ErrorDelegate;
    // Vertical spacing between the top of the face and the error icon
    private var mErrorIconMargin as Lang.Number;
    private var mErrorIcon;
    private var mTextArea        as WatchUi.TextArea or Null;
    private var mAntiAlias       as Lang.Boolean         = false;

    private static var instance;
    private static var mShown as Lang.Boolean = false;

    function initialize() {
        ScalableView.initialize();
        mDelegate = new ErrorDelegate(self);
        // Convert the settings from % of screen size to pixels
        mErrorIconMargin = pixelsForScreen(scErrorIconMargin);
        mErrorIcon       = Application.loadResource(Rez.Drawables.ErrorIcon) as Graphics.BitmapResource;
        if (Graphics.Dc has :setAntiAlias) {
            mAntiAlias = true;
        }
    }

    // Load your resources here
    function onLayout(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();

        mTextArea = new WatchUi.TextArea({
            :text          => mText,
            :color         => Graphics.COLOR_WHITE,
            :font          => Graphics.FONT_XTINY,
            :justification => Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
            :locX          => 0,
            :locY          => pixelsForScreen(20.0),
            :width         => w,
            :height        => pixelsForScreen(60.0)
        });
    }

    // Update the view
    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        if (mAntiAlias) {
            dc.setAntiAlias(true);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLUE);
        dc.clear();
        dc.drawBitmap(w/2 - mErrorIcon.getWidth()/2, mErrorIconMargin, mErrorIcon);
        mTextArea.draw(dc);
    }

    function getDelegate() as ErrorDelegate {
        return mDelegate;
    }

    static function create(text as Lang.String) as Lang.Array<ErrorView or ErrorDelegate> {
        if (instance == null) {
            instance = new ErrorView();
        }
        if (!mShown) {
            instance.setText(text);
            mShown = true;
        }
        return [instance, instance.getDelegate()];
    }

    // Create or reuse an existing ErrorView, and pass on the text.
    static function show(text as Lang.String) as Void {
        if (!mShown) {
            create(text); // Ignore returned values
            WatchUi.pushView(instance, instance.getDelegate(), WatchUi.SLIDE_UP);
            // This must be last to avoid a race condition with unShow(), where the
            // ErrorView can't be dismissed.
            mShown = true;
        }
    }

    static function unShow() as Void {
        if (mShown) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            // The call to 'updateNextMenuItem()' must be on another thread so that the view is popped above.
            var myTimer = new Timer.Timer();
            // Now this feels very "closely coupled" to the application, but it is the most reliable method instead of using a timer.
            myTimer.start(getApp().method(:updateNextMenuItem), Globals.scApiResume, false);
            // This must be last to avoid a race condition with show(), where the
            // ErrorView can't be dismissed.
            mShown = false;
        }
    }

    // Internal show now we're not a static method like 'show()'.
    function setText(text as Lang.String) as Void {
        mText = text;
        if (mTextArea != null) {
            mTextArea.setText(text);
            requestUpdate();
        }
    }

}

class ErrorDelegate extends WatchUi.BehaviorDelegate {

    function initialize(view as ErrorView) {
        WatchUi.BehaviorDelegate.initialize();
    }

    function onBack() as Lang.Boolean {
        getApp().getQuitTimer().reset();
        ErrorView.unShow();
        return true;
    }

}
