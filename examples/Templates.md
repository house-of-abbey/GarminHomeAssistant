# Templates

In order to provide the most functionality possible the content of the card is a user-defined template (i.e. you generate your own text). This allows you to do some pretty cool things. It also makes the config a bit more complicated. This page will help you understand how to use templates.

In this file anything between `<` and `>` is a placeholder. Replace it with the appropriate value.

Anything between `{{` and `}}` is a template. Templates are used to dynamically insert values into the content. For more info see [the docs](https://www.home-assistant.io/docs/configuration/templating/).

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
