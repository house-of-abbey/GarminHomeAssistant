[Home](../README.md) | [Switches](Switches.md) | [Actions](Actions.md) | Templates | [Background Service](../BackgroundService.md) | [Trouble Shooting](../TroubleShooting.md) | [Version History](../HISTORY.md)

# Templates

In order to provide the most functionality possible the content of the menu item comes from a user-defined template (i.e. you generate your own text). This allows you to do some pretty cool things. It also makes the configuration a bit more complicated. This page will help you understand how to use templates.

- In this file anything between `<` and `>` is a placeholder. Replace it with the appropriate value.
- [Jinja2](https://palletsprojects.com/p/jinja/) syntax is used by Home Assistant [Templates](https://www.home-assistant.io/docs/configuration/templating/). Templates are used to dynamically insert values into the content. The syntax includes:
  - `{%` ... `%}` for Statements
  - `{{` ... `}}` for Expressions to print to the template output
  - `{#` ... `#}` for Comments not included in the template output

## States

In this example we get the battery level of the device and add the percent sign. *Very simple*

```json
{
  "entity": "sensor.<device>_battery_level",
  "name": "Phone",
  "type": "template",
  "content": "{{ states('sensor.<device>_battery_level') }}%"
}
```

### Examples

The first two keep to the simple proposal above. The last combines them into a single menu item. Now you can start to see the utility of this menu item, composing your own formatted text.

```json
{
  "entity": "sensor.hallway_temperature",
  "name": "Hall Temp",
  "type": "template",
  "content": "{{ states('sensor.hallway_temperature') }}°C"
},
{
  "entity": "sensor.hallway_humidity",
  "name": "Hall Humidity",
  "type": "template",
  "content": "{{ states('sensor.hallway_humidity') }}%"
},
{
  "entity": "sensor.hallway_temperature",
  "name": "Hallway",
  "type": "template",
  "content": "{{ states('sensor.hallway_temperature') }}°C {{ states('sensor.hallway_humidity') }}%"
}
```

In order to keep the formatting of floating point numbers under control, you might also like to include a format string as follows. `states()` seems to return a `string` that needs converting to a `float` before the `format()` call can manage the conversion to the required number fo decimal places.

```json
{
  "name": "Hallway",
  "type": "template",
  "content": "T:{{ '%.1f' | format(states('sensor.hallway_temperature') | float) }}°C, H:{{ '%.1f' | format(states('sensor.hallway_humidity') | float) }}%"
},
```

## Conditionals

Anything between `{%` and `%}` is a directive (`if`, `else`, `elif`, `endif`, etc.). Conditionals are used to dynamically change the content based on the state of the entity.

In this example we get the battery level of the device and add the percent sign. If the device is charging we add a plus sign.

```json
{
  "entity": "sensor.<device>_battery_level",
  "name": "Phone",
  "type": "template",
  "content": "{{ states('sensor.<device>_battery_level') }}%{% if is_state('binary_sensor.<device>_is_charging', 'on') %}+{% endif %}"
}
```

Here we also use the else clause as well to give proper text instead of just `on` or `off`.

```json
{
  "entity": "binary_sensor.garage_doors",
  "name": "Garage Doors",
  "type": "template",
  "content": "{% if is_state('binary_sensor.<door-0>', 'on') %}Open{% else %}Closed{% endif %} {% if is_state('binary_sensor.<door-1>', 'on') %}Open{% else %}Closed{% endif %}"
}
```

## Advanced

Here we generate a bar graph of the battery level. We use the following steps to do this:

- Convert the state to a number.
- Divide by 100 to get a fraction.
- Multiply by the width to get the number of `#`s.
- Multiply by the `#` char to make a string.
- Subtract the width from the number of `#`s to get the number of `_`s.
- Multiply by the `_` char to make a string.

```json
{
  "entity": "sensor.<device>_battery_level",
  "name": "Phone",
  "type": "template",
  "content": "{{ states('sensor.<device>_battery_level') }}%{% if is_state('binary_sensor.<device>_is_charging', 'on') %}+{% endif %} {{ '#' * (((states('sensor.<device>_battery_level') | int) / 100 * <width>) | int) }}{{ '_' * (<width> - (((states('sensor.<device>_battery_level') | int) / 100 * <width>) | int)) }}"
}
```

An example of a dimmer light with 4 brightness settings 0..3. Here our light worked on a percentage, so that had to be converted to the range 0..3.

```json
{
  "$schema": "./schema.json",
  "title": "Home",
  "items": [
    {
      "entity": "light.green_house",
      "name": "LEDs",
      "type": "template",
      "content": "{% if not (is_state('light.green_house', 'off') or is_state('light.green_house', 'unavailable')) %}{{ (((state_attr('light.green_house', 'brightness') | float) / 255 * 100) | round(0)) | int }}%{% else %}Off{% endif %}"
    },
    {
      "entity": "light.green_house",
      "name": "LEDs 0",
      "type": "template",
      "content": "{% if not (is_state('light.green_house', 'off') or is_state('light.green_house', 'unavailable')) %}{{ (((state_attr('light.green_house', 'brightness') | float) / 255 * 100) | round(0)) | int }}%{% else %}Off{% endif %}",
      "tap_action": {
        "service": "light.turn_on",
        "data": {
          "brightness_pct": 12
        }
      }
    },
    {
      "entity": "light.green_house",
      "name": "LEDs 1",
      "type": "tap",
      "tap_action": {
        "service": "light.turn_on",
        "data": {
          "brightness_pct": 37
        }
      }
    },
    {
      "entity": "light.green_house",
      "name": "LEDs 2",
      "type": "template",
      "content": "{% if not (is_state('light.green_house', 'off') or is_state('light.green_house', 'unavailable')) %}{{ (((state_attr('light.green_house', 'brightness') | float) / 255 * 100) | round(0)) | int }}%{% else %}Off{% endif %}",
      "tap_action": {
        "service": "light.turn_on",
        "data": {
          "brightness_pct": 62
        }
      }
    },
    {
      "entity": "light.green_house",
      "name": "LEDs 3",
      "type": "template",
      "content": "{% if not (is_state('light.green_house', 'off') or is_state('light.green_house', 'unavailable')) %}{{ (((state_attr('light.green_house', 'brightness') | float) / 255 * 100) | round(0))| int }}%{% else %}Off{% endif %}",
      "tap_action": {
        "service": "light.turn_on",
        "data": {
          "brightness_pct": 87
        }
      }
    }
  ]
}
```

## Warnings

Just remember, **you have the ability to crash the application by creating an excessive menu definition**. Templates can require significant definition for highly customised text. Don't be silly.
