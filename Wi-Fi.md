[Home](README.md) | [Switches](examples/Switches.md) | [Actions](examples/Actions.md) | [Templates](examples/Templates.md) | [Glance](examples/Glance.md) | [Background Service](BackgroundService.md) | [Wi-Fi](Wi-Fi.md) | [Trouble Shooting](TroubleShooting.md) | [Version History](HISTORY.md)

# Wi-Fi & LTE

Many watches now include the ability to synchronise data over Wi-Fi or event LTE in addition to Bluetooth. This gives users of this application the expectation that they should be able to operate Home Assistant devices from their watch without Bluetooth and hence their phone (that they left out of contact distance). The whole point of Bluetooth after all is that it is [low power](https://en.wikipedia.org/wiki/Bluetooth#Uses). Using Wi-Fi and LTE are power hungry and therefore not something that can be left on continuously in a small device. The watch function that uses Wi-Fi & LTE is the ability to 'synchronise', e.g. activity data (FIT files) and application updates. This function then has a limited period of time for which radio is active. Neither Wi-Fi nor LTE are "always on" like Bluetooth.

With version 3.0 onwards the application now includes the ability to temporarily turn on Wi-Fi or LTE in order to perform a task on the watch. To do this, the "synchronise" function of the Connect IQ SDK has been cleverly hijacked. This appears to be a highly sought after solution from several users as **it allows the watch to operate when out of range of the associated phone**.

## Limits of Use

1. An API request issued over Wi-Fi requires the watch to open up an IP connection to your Wi-Fi access point. This means setting up a secure channel with WPA and being allocated an IP address. Establishing the communication channel takes a short while. _You will see that this adds a noticeable delay to usability._

2. **The Wi-Fi/LTE functionality can only be used when the menu is already cached.** _The watch will not perform an HTTPS GET request to retrieve the JSON menu file_. Therefore, to enable the Wifi/LTE functionality in the application settings, you must enable caching first.

3. The menu item statuses will not be set correctly. Instead you will be warned about the lack of connectivity by a 'toast', i.e. message partially occupying the top of the screen temporarily. Fetching the menu item statuses, including rendered templates, requires its own API call, hence this not performed.

4. Do not forget you need to be within range of your watch's configured Wi-Fi access point to take advantage of this functionality. LTE is obviously longer range.

## Video

This video using will hopefully make it obvious how slow it is to use the Wi-Fi option and illustrate the cautionary notes above.

<video width="100%" controls style="max-width:250px">
  <source src="./images/wi-fi.mp4" type="video/mp4">
</video>

## Credits

With thanks to [@vincentezw](https://github.com/vincentezw) for contributing this solution.