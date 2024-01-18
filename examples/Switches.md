# Switches

In order to facilitate custom switches at this time, you must create a template switch in HomeAssistant.

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

## Example (covers)

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

```json
{
  "entity": "switch.cover",
  "name": "Cover",
  "type": "toggle"
}
```
