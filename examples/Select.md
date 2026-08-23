[Home](../README.md) | [Switches](Switches.md) | [Actions](Actions.md) | [Templates](Templates.md) | [Numeric](Numeric.md) | [Select](Select.md) | [Glance](Glance.md) | [Background Service](../BackgroundService.md) | [Wi-Fi](../Wi-Fi.md) | [HTTP Headers](../HTTP_Headers.md) | [Trouble Shooting](../TroubleShooting.md) | [Version History](../HISTORY.md)

# Select

Provides an option picker in order to select from a list of options. Supports both Home Assistant `select` and `input_select` entities, or manually configured options.

## Select Entity

The simplest form uses a `select` entity. The available options are automatically fetched from the entity's `options` attribute, and the current selection is displayed as a sub-label.

```json
{
  "name": "Wash Cycle",
  "type": "select",
  "entity": "select.washing_machine_cycle"
}
```

The action defaults to `select.select_option` and the data attribute defaults to `option`, so no `tap_action` is needed for the basic case.

## Input Select Entity

Works identically for `input_select` entities. The action automatically defaults to `input_select.select_option`.

```json
{
  "name": "Theme",
  "type": "select",
  "entity": "input_select.theme"
}
```

## Content Template

Like other menu items, you can use a `content` template to customise the sub-label display.

```json
{
  "name": "HVAC Mode",
  "content": "Currently: {{ states('select.hvac_mode') }}",
  "type": "select",
  "entity": "select.hvac_mode"
}
```

## Manual Options

When the entity does not provide an `options` attribute, or when you want to override the available choices, specify them in the `tap_action`. Each option can be a `value`/`label` pair (the label is shown on the watch, the value is sent to the service), or a plain string used as both.

```json
{
  "name": "Scene",
  "type": "select",
  "entity": "input_select.scene",
  "tap_action": {
    "options": [
      { "value": "movie", "label": "Movie Night" },
      { "value": "dinner", "label": "Dinner" },
      { "value": "bright", "label": "Bright" }
    ]
  }
}
```

Plain strings are also accepted:

```json
{
  "name": "Scene",
  "type": "select",
  "entity": "input_select.scene",
  "tap_action": {
    "options": ["Movie Night", "Dinner", "Bright"]
  }
}
```

## Custom Action

You can override the action, data attribute, and provide additional data. This allows using the select picker with any entity domain.

```json
{
  "name": "Fan Speed",
  "type": "select",
  "entity": "fan.living_room",
  "tap_action": {
    "action": "fan.set_preset_mode",
    "data_attribute": "preset_mode",
    "options": [
      { "value": "auto", "label": "Auto" },
      { "value": "low", "label": "Low" },
      { "value": "medium", "label": "Medium" },
      { "value": "high", "label": "High" }
    ]
  }
}
```

## Tap Action Fields

The `tap_action` object for a `select` item supports the following fields.

Field            | Purpose                                                                     | Default                   |
-----------------|-----------------------------------------------------------------------------|---------------------------|
`action`         | The Home Assistant action to call.                                          | `select.select_option` or `input_select.select_option` based on entity domain. |
`data`           | Fixed parameters merged into the action call.                               | `{}`                      |
`data_attribute` | Key name in the action data for the selected option value.                  | `option`                  |
`options`        | Array of options. Object `{"value","label"}` or plain string. If omitted, fetched from the entity's `options` attribute. | Entity attribute |
`confirm`        | Confirmation before execution. Boolean or custom message string.            | `false`                   |
`pin`            | PIN confirmation before execution. Requires touch screen.                   | `false`                   |
`exit`           | Exit the application after selection.                                       | `false`                   |

## Confirmation

Like other actionable items, you can require confirmation or a PIN before the action is executed.

```json
{
  "name": "Alarm Mode",
  "type": "select",
  "entity": "select.alarm_mode",
  "tap_action": {
    "confirm": "Change alarm mode?",
    "options": ["Home", "Away", "Night", "Off"]
  }
}
```
