# Battery Reporting

# TODO: app settings config and screen shots for getting the device id

The watch will send HTTP requests to HomeAssistant every 5 minutes in a background service. The events produced by the HTTP requests can be listened for with a template entity. In this case we have two (battery level and is charging).

```yaml
  - trigger:
      - platform: "event"
        event_type: "garmin.battery_level"
        event_data:
          device_id: "<device-id>"
    sensor:
      - name: "<device-name> Battery Level"
        unique_id: "<uid-0>"
        device_class: "battery"
        unit_of_measurement: "%"
        state_class: "measurement"
        state: "{{ trigger.event['data']['level'] }}"
        icon: mdi:battery{% if trigger.event['data']['is_charging'] %}-charging{% endif %}{% if 0 < (trigger.event['data']['level'] | float / 10 ) | round(0) * 10 < 100 %}-{{ (trigger.event['data']['level'] | float / 10 ) | round(0) * 10 }}{% else %}{% if (trigger.event['data']['level'] | float / 10 ) | round(0) * 10 == 0 %}-outline{% else %}{% if trigger.event['data']['is_charging'] %}-100{% endif %}{% endif %}{% endif %}
        attributes:
          device_id: "<device-id>"
  - trigger:
      - platform: "event"
        event_type: "garmin.battery_level"
        event_data:
          device_id: "<device-id>"
    binary_sensor:
      - name: "<device-name> is Charging"
        unique_id: "<uid-1>"
        device_class: "battery_charging"
        state: "{{ trigger.event['data']['is_charging'] }}"
        attributes:
          device_id: "<device-id>"
```

1. Copy this yaml to your `configuration.yaml`.
2. Swap `<device-name>` for the name of your device (This can be anything and is purely for the UI). Swap `<uid-0>` and `<uid-1>` for two different unique identifiers (in the Studio Code Server these can be generated from the right click menu).
3. Open the [event dashboard](https://my.home-assistant.io/redirect/developer_events/) and start listening for `garmin.battery_level` events and when your recieve one copy the device id and replace `<device-id>` with it (to speed up this process you can close and reopen the GarminHomeAssistant app).
4. Restart HomeAssistant or reload the yaml [here](https://my.home-assistant.io/redirect/server_controls/).
