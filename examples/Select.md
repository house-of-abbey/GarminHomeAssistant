# Selects

Here is an example of how to make a light effect selector:

```json
{
  "type": "group",
  "name": "Example",
  "title": "Light Effect",
  "content": "{{ state_attr('light.moon', 'effect') }}",
  "items": [
    {
      "type": "tap",
      "name": "None",
      "entity": "light.example",
      "tap_action": {
        "service": "light.turn_on",
        "data": {
          "effect": "None"
        }
      }
    },
    {
      "type": "tap",
      "name": "Rainbow",
      "entity": "light.example",
      "tap_action": {
        "service": "light.turn_on",
        "data": {
          "effect": "Rainbow"
        }
      }
    },
    {
      "type": "tap",
      "name": "Glimmer",
      "entity": "light.example",
      "tap_action": {
        "service": "light.turn_on",
        "data": {
          "effect": "Glimmer"
        }
      }
    },
    {
      "type": "tap",
      "name": "Twinkle",
      "entity": "light.example",
      "tap_action": {
        "service": "light.turn_on",
        "data": {
          "effect": "Twinkle"
        }
      }
    }
  ]
}
```

The same pattern works for any selector (`input_select.*`, `select.*`, `climate.*` mode).
