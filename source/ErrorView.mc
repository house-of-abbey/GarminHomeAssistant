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
// J D Abbey & P A Abbey, 28 December 2022
//
//
// Description:
//
// ErrorView provides a means to present application errors to the user. These
// should not happen of course... but they do, so best make sure errors can be
// reported.
//
//-----------------------------------------------------------------------------------

using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Communications;

class ErrorView extends ScalableView {
    hidden const settings as Lang.Dictionary = {
        :errorIconMargin => 7f
    };
    // Vertical spacing between the top of the face and the error icon
    hidden var errorIconMargin;
    hidden var text as Lang.String;
    hidden var errorIcon;
    hidden var textArea;

    function initialize(text as Lang.String) {
        ScalableView.initialize();
        self.text = text;
        // Convert the settings from % of screen size to pixels
        errorIconMargin = pixelsForScreen(settings.get(:errorIconMargin) as Lang.Float);
    }

    // Load your resources here
    function onLayout(dc as Graphics.Dc) as Void {
        errorIcon = Application.loadResource(Rez.Drawables.ErrorIcon) as Graphics.BitmapResource;

        var w = dc.getWidth();
        var h = dc.getHeight();

        textArea = new WatchUi.TextArea({
            :text          => text,
            :color         => Graphics.COLOR_WHITE,
            :font          => Graphics.FONT_XTINY,
            :justification => Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
            :locX          => 0,
            :locY          => 83,
            :width         => w,
            :height        => h - 166
        });
    }

    // Update the view
    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var hw = w/2;
        var bg = 0x3B444C;
        if(dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
        dc.setColor(Graphics.COLOR_WHITE, bg);
        dc.clear();
        dc.drawBitmap(hw - errorIcon.getWidth()/2, errorIconMargin, errorIcon);
        textArea.draw(dc);
    }

}

class ErrorDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        WatchUi.BehaviorDelegate.initialize();
    }
    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}