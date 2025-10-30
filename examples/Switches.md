[Home](../README.md) | [Switches](Switches.md) | [Actions](Actions.md) | [Templates](Templates.md) | [Numeric](Numeric.md) | [Glance](Glance.md) | [Background Service](../BackgroundService.md) | [Wi-Fi](../Wi-Fi.md) | [HTTP Headers](../HTTP_Headers.md) | [Trouble Shooting](../TroubleShooting.md) | [Version History](../HISTORY.md)

# Switches

This is the simplest form:

```json
 {
   "entity": "light.bedside_light_switch",
   "name": "Bedroom Light",
   "type": "toggle"
 },
```

And with an optional confirmation:

```json
 {
   "entity": "light.exterior",
   "name": "Exterior Lights",
   "type": "toggle",
   "tap_action": {
     "confirm": true
   }
 }
```

or an optional PIN confirmation:

```json
 {
   "entity": "light.exterior",
   "name": "Exterior Lights",
   "type": "toggle",
   "tap_action": {
     "pin": true
   }
 }
```

To support a non-standard light, switch, or automation as a toggle menu item you may like to define a custom switch. In order to facilitate custom switches at this time, you must create a template switch in HomeAssistant.

```yaml
switch:
  - platform: template
    switches:
      <switch-name>:
        friendly_name: <name>
        value_template: <value>
        turn_on:
          service: <service>
          data:
            entity_id: <entity>
            <attribute>: <value>
        turn_off:
          service: <service>
          data:
            entity_id: <entity>
            <attribute>: <value>
```

Then you can use the following in your config:

```json
{
  "entity": "switch.<switch-name>",
  "name": "<name>",
  "type": "toggle"
}
```

And you can optionally include a template to reflect some status. See [Templates](Templates.md) for details on hwo to use this JSON field.

```json
{
  "entity": "switch.<switch-name>",
  "name": "<name>",
  "type": "toggle",
  "content": "..."
}
```

## Example - Covers

```yaml
switch:
  - platform: template
    switches:
      cover:
        friendly_name: Cover
        value_template: "{{ is_state('cover.cover', 'open') }}"
        turn_on:
          service: cover.open_cover
          data:
            entity_id: cover.cover
        turn_off:
          service: cover.close_cover
          data:
            entity_id: cover.cover
```

Then you can use the following in your config:

```json
{
  "entity": "switch.cover",
  "name": "Cover",
  "type": "toggle"
}
```

## Exit On Toggle

You can choose individual items that will quit after they have completed their action.

```json
{
  "entity": "light.hall_light",
  "name": "Hall Light & Quit",
  "type": "toggle",
  "exit": true
}
```

## Disable Menu Item

If you would like to temporarily disable an item in your menu, e.g. for seasonal reasons like not needing to turn on Christmas tree lights outside the festive season, then rather than swapping menu definition files or deleting a section of the menu you can mark the item as 'disabled'. This field applies to all menu items.

```json
{
  "entity": "light.chrissmas_tree",
  "name": "Christmas Lights",
  "type": "toggle",
  "enabled": false
}
```
