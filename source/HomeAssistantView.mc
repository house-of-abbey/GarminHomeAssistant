import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;

class HomeAssistantView extends WatchUi.Menu2 {
    hidden var timer;

    function initialize() {
        timer = new Timer.Timer();

        var toggle_obj = {
            :enabled  => "On",
            :disabled => "Off"
        };

        WatchUi.Menu2.initialize({
            :title => "Entities"
        });
        addItem(
            new HomeAssistantToggleMenuItem(
                self,
                "Bedroom Light",
                toggle_obj,
                "light.philip_s_bedside_light_switch",
                false,
                null
            )
        );
        addItem(
            new HomeAssistantToggleMenuItem(
                self,
                "Lounge Lights",
                toggle_obj,
                "light.living_room_ambient_lights_all",
                false,
                null
            )
        );
        addItem(
            new HomeAssistantMenuItem(
                "Food is Ready!",
                null,
                "script.food_is_ready",
                null
            )
        );
        // addItem(
        //     new HomeAssistantMenuItem(
        //         "Test Script",
        //         null,
        //         "script.test",
        //         null
        //     )
        // );
        addItem(
            new HomeAssistantToggleMenuItem(
                self,
                "Bookcase USBs",
                toggle_obj,
                "switch.bookcase_usbs",
                false,
                null
            )
        );
        addItem(
            new HomeAssistantToggleMenuItem(
                self,
                "Corner Table USBs",
                toggle_obj,
                "switch.corner_table_usbs",
                false,
                null
            )
        );
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        timer.start(
            method(:timerUpdate),
            Globals.updateInterval * 1000,
            true
        );
        for(var i = 0; i < mItems.size(); i++) {
            if (mItems[i] instanceof HomeAssistantToggleMenuItem) {
                var toggleItem = mItems[i] as HomeAssistantToggleMenuItem;
                toggleItem.getState();
                if (Globals.debug) {
                    System.println("HomeAssistantView Note: " + toggleItem.getLabel() + " ID=" + toggleItem.getId() + " Enabled=" + toggleItem.isEnabled());
                }
            }
        }
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
        timer.stop();
    }

    function timerUpdate() as Void {
        for(var i = 0; i < mItems.size(); i++) {
            if (mItems[i] instanceof HomeAssistantToggleMenuItem) {
                var toggleItem = mItems[i] as HomeAssistantToggleMenuItem;
                toggleItem.getState();
                if (Globals.debug) {
                    System.println("HomeAssistantView Note: " + toggleItem.getLabel() + " ID=" + toggleItem.getId() + " Enabled=" + toggleItem.isEnabled());
                }
            }
        }
    }

}

class HomeAssistantViewDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        if (item instanceof HomeAssistantToggleMenuItem) {
            var haToggleItem = item as HomeAssistantToggleMenuItem;
            if (Globals.debug) {
                System.println(haToggleItem.getLabel() + " " + haToggleItem.getId() + " " + haToggleItem.isEnabled());
            }
            haToggleItem.setState(haToggleItem.isEnabled());
        } else if (item instanceof HomeAssistantMenuItem) {
            var haItem = item as HomeAssistantMenuItem;
            if (Globals.debug) {
                System.println(haItem.getLabel() + " " + haItem.getId());
            }
            haItem.execScript();
        } else {
            if (Globals.debug) {
                System.println(item.getLabel() + " " + item.getId());
            }
        }
    }

}