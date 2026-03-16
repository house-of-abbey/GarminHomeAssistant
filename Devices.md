# Device Support & Characterisation

A page just to note a practical limit on support for some older devices.

## Application Memory Usage

On an `instinct2x` device:

| Version | Free Memory (bytes) on `instinct2x`| Free Memory (bytes) on `venu2`|
|:-------:|-----------------------------------:|------------------------------:|
|   3.5   |                             62,360 |                             - |
|   3.6   |                             65,696 |                        53,832 |

A user has reported a maximum of 26 items with Ver 3.5. This measurement has shown that each menu item requires about 1.0~1.2 kB. Using the worked example below it is possible to predict how many menu items your particular device might be able to support by using indicative figures.

## Worked Example

As a worked example, for Ver 3.6 working on an `instinct2x` device:

| Feature                              | Memory (bytes) | Cost (bytes) |
|:-------------------------------------|---------------:|-------------:|
| Declared available to application    |         98,304 |              |
| Measured available to application    |         94,112 | (4,192 less) |
| Application used                     |         65,696 |              |
| Free before fetching menu definition |         28,416 |              |
| Free after fetching menu definition  |         15,792 |       12,624 |
| Free after construction              |            936 |       14,856 |

Our test menu presently contains a mix of 28 items, consisting of nested group, toggle, tap, info and numeric items with templates. So each item requires (12,624 + 14,856) / 28 = 982 bytes.

## Glance Memory Usage

Using a `venu2` device the Glance view memory statistics are:

| Measure   | Memory (bytes)  |
|:----------|----------------:|
| Total     |          61,344 |
| Peak Used |          32,224 |
| Free      |          29,120 |

This means that for older devices listed below, with only 32 kB of Glance memory, the Glance view crashes with an "_Out Of Memory Error_". There is no opportunity in the code to intervene and no way to catch this fatal error. Nor is there any way to disable the Glance view on a device by device basis. Therefore, the only answer at present is to allow the Glance view to crash. It may display "HomeAssistant" as the Glance view text before crashing.

This problem has been explored via a [Github issue](https://github.com/house-of-abbey/GarminHomeAssistant/issues/347). This is now listed as a [known issue](./README.md#known-issues).

## Garmin Devices

The following table details all the devices as at March 2026 and whether they are supported by Garmin HomeAssistant. The available application and glance memory is also detailed so that it can be compared to an application version listed above. Of particular concern are the 'Instinct' range of devices, being the smallest we currently support. New feature requests are now being vetted against how they might affect our ability to support the 'Instinct' range of devices. At some point support may have to be withdrawn in order to allow the Garmin HomeAssistant application to grow further.

| Device                     | Supported | Application Memory | Glance Memory  |
|:---------------------------|:---------:|-------------------:|---------------:|
| approachs50                |     Y     |           786,432  |        65,536  |
| approachs60                |     N     |           131,072  |                |
| approachs62                |     N     |         1,048,576  |                |
| approachs7042mm            |     Y     |           786,432  |        65,536  |
| approachs7047mm            |     Y     |           786,432  |        65,536  |
| d2air                      |     Y     |         1,048,576  |                |
| d2airx10                   |     Y     |           786,432  |        65,536  |
| d2bravo                    |     N     |            65,536  |                |
| d2bravo_titanium           |     N     |            65,536  |                |
| d2charlie                  |     N     |         1,310,720  |                |
| d2delta                    |     Y     |         1,310,720  |                |
| d2deltapx                  |     Y     |         1,310,720  |                |
| d2deltas                   |     Y     |         1,310,720  |                |
| d2mach1                    |     Y     |           786,432  |        65,536  |
| d2mach2                    |     Y     |           786,432  |        65,536  |
| descentg1                  |     Y     |            98,304  |        32,768  |
| descentg2                  |     Y     |           786,432  |        65,536  |
| descentmk1                 |     N     |         1,310,720  |                |
| descentmk2                 |     Y     |         1,310,720  |        32,768  |
| descentmk2s                |     Y     |         1,310,720  |        32,768  |
| descentmk343mm             |     Y     |           786,432  |        65,536  |
| descentmk351mm             |     Y     |           786,432  |        65,536  |
| edge1030                   |     Y     |         1,048,576  |                |
| edge1030bontrager          |     Y     |         1,048,576  |                |
| edge1030plus               |     Y     |         1,048,576  |                |
| edge1040                   |     Y     |         1,048,576  |        65,536  |
| edge1050                   |     Y     |         1,048,576  |        65,536  |
| edge130                    |     N     |                    |                |
| edge130plus                |     N     |                    |                |
| edge520plus                |     Y     |         1,048,576  |                |
| edge530                    |     Y     |         1,048,576  |                |
| edge540                    |     Y     |         1,048,576  |        65,536  |
| edge550                    |     Y     |         1,048,576  |        65,536  |
| edge820                    |     Y     |         1,048,576  |                |
| edge830                    |     Y     |         1,048,576  |                |
| edge840                    |     Y     |         1,048,576  |        65,536  |
| edge850                    |     Y     |         1,048,576  |        65,536  |
| edgeexplore                |     Y     |         1,048,576  |                |
| edgeexplore2               |     Y     |         1,048,576  |        65,536  |
| edgemtb                    |     Y     |         1,048,576  |        65,536  |
| edge_1000                  |     N     |         1,048,576  |                |
| edge_520                   |     N     |           262,144  |                |
| enduro                     |     Y     |           131,072  |        32,768  |
| enduro3                    |     Y     |           786,432  |        65,536  |
| epix                       |     N     |         1,048,576  |                |
| epix2                      |     Y     |           786,432  |        65,536  |
| epix2pro42mm               |     Y     |           786,432  |        65,536  |
| epix2pro47mm               |     Y     |           786,432  |        65,536  |
| epix2pro47mmsystem7preview |     Y     |           786,432  |        65,536  |
| epix2pro51mm               |     Y     |           786,432  |        65,536  |
| etrextouch                 |     Y     |         2,359,296  |                |
| fenix3                     |     N     |            65,536  |                |
| fenix3_hr                  |     N     |            65,536  |                |
| fenix5                     |     Y     |           131,072  |                |
| fenix5plus                 |     Y     |         1,310,720  |                |
| fenix5s                    |     Y     |           131,072  |                |
| fenix5splus                |     Y     |         1,310,720  |                |
| fenix5x                    |     Y     |         1,310,720  |                |
| fenix5xplus                |     Y     |         1,310,720  |                |
| fenix6                     |     Y     |           131,072  |        32,768  |
| fenix6pro                  |     Y     |         1,310,720  |        32,768  |
| fenix6s                    |     Y     |           131,072  |        32,768  |
| fenix6spro                 |     Y     |         1,310,720  |        32,768  |
| fenix6xpro                 |     Y     |         1,310,720  |        32,768  |
| fenix7                     |     Y     |           786,432  |        65,536  |
| fenix7pro                  |     Y     |           786,432  |        65,536  |
| fenix7pronowifi            |     Y     |           786,432  |        65,536  |
| fenix7s                    |     Y     |           786,432  |        65,536  |
| fenix7spro                 |     Y     |           786,432  |        65,536  |
| fenix7x                    |     Y     |           786,432  |        65,536  |
| fenix7xpro                 |     Y     |           786,432  |        65,536  |
| fenix7xpronowifi           |     Y     |           786,432  |        65,536  |
| fenix843mm                 |     Y     |           786,432  |        65,536  |
| fenix847mm                 |     Y     |           786,432  |        65,536  |
| fenix8pro47mm              |     Y     |           786,432  |        65,536  |
| fenix8solar47mm            |     Y     |           786,432  |        65,536  |
| fenix8solar51mm            |     Y     |           786,432  |        65,536  |
| fenixchronos               |     Y     |           131,072  |                |
| fenixe                     |     Y     |           786,432  |        65,536  |
| fr165                      |     Y     |           786,432  |        65,536  |
| fr165m                     |     Y     |           786,432  |        65,536  |
| fr230                      |     N     |            65,536  |                |
| fr235                      |     N     |            65,536  |                |
| fr245                      |     Y     |           131,072  |        32,768  |
| fr245m                     |     Y     |         1,310,720  |        32,768  |
| fr255                      |     Y     |           524,288  |        65,536  |
| fr255m                     |     Y     |           786,432  |        65,536  |
| fr255s                     |     Y     |           524,288  |        65,536  |
| fr255sm                    |     Y     |           786,432  |        65,536  |
| fr265                      |     Y     |           786,432  |        65,536  |
| fr265s                     |     Y     |           786,432  |        65,536  |
| fr45                       |     N     |                    |                |
| fr55                       |     Y     |           131,072  |        32,768  |
| fr57042mm                  |     Y     |           786,432  |        65,536  |
| fr57047mm                  |     Y     |           786,432  |        65,536  |
| fr630                      |     N     |            65,536  |                |
| fr645                      |     Y     |           131,072  |                |
| fr645m                     |     Y     |         1,048,576  |                |
| fr735xt                    |     N     |           131,072  |                |
| fr745                      |     Y     |         1,310,720  |        32,768  |
| fr920xt                    |     N     |            65,536  |                |
| fr935                      |     Y     |           131,072  |                |
| fr945                      |     Y     |         1,310,720  |        32,768  |
| fr945lte                   |     Y     |         1,310,720  |        32,768  |
| fr955                      |     Y     |           786,432  |        65,536  |
| fr965                      |     Y     |           786,432  |        65,536  |
| fr970                      |     Y     |           786,432  |        65,536  |
| garminswim2                |     N     |                    |                |
| gpsmap66                   |     Y     |         2,359,296  |                |
| gpsmap67                   |     Y     |         2,359,296  |                |
| gpsmap86                   |     N     |         2,359,296  |                |
| gpsmaph1                   |     Y     |         2,359,296  |                |
| instinct2                  |     Y     |            98,304  |        32,768  |
| instinct2s                 |     Y     |            98,304  |        32,768  |
| instinct2x                 |     Y     |            98,304  |        32,768  |
| instinct3amoled45mm        |     Y     |           786,432  |        65,536  |
| instinct3amoled50mm        |     Y     |           786,432  |        65,536  |
| instinct3solar45mm         |     Y     |           131,072  |        32,768  |
| instinctcrossover          |     Y     |            98,304  |        32,768  |
| instinctcrossoveramoled    |     Y     |           786,432  |        65,536  |
| instincte40mm              |     Y     |           131,072  |        32,768  |
| instincte45mm              |     Y     |           131,072  |        32,768  |
| legacyherocaptainmarvel    |     Y     |         1,048,576  |                |
| legacyherofirstavenger     |     Y     |         1,048,576  |                |
| legacysagadarthvader       |     Y     |         1,048,576  |                |
| legacysagarey              |     Y     |         1,048,576  |                |
| marq2                      |     Y     |           786,432  |        65,536  |
| marq2aviator               |     Y     |           786,432  |        65,536  |
| marqadventurer             |     Y     |         1,310,720  |        32,768  |
| marqathlete                |     Y     |         1,310,720  |        32,768  |
| marqaviator                |     Y     |         1,310,720  |        32,768  |
| marqcaptain                |     Y     |         1,310,720  |        32,768  |
| marqcommander              |     Y     |         1,310,720  |        32,768  |
| marqdriver                 |     Y     |         1,310,720  |        32,768  |
| marqexpedition             |     Y     |         1,310,720  |        32,768  |
| marqgolfer                 |     Y     |         1,310,720  |        32,768  |
| montana7xx                 |     Y     |         2,359,296  |                |
| oregon7xx                  |     N     |         2,359,296  |                |
| rino7xx                    |     N     |         2,359,296  |                |
| system8preview             |     N     |           786,432  |        65,536  |
| venu                       |     Y     |         1,048,576  |                |
| venu2                      |     Y     |           786,432  |        65,536  |
| venu2plus                  |     Y     |           786,432  |        65,536  |
| venu2s                     |     Y     |           786,432  |        65,536  |
| venu3                      |     Y     |           786,432  |        65,536  |
| venu3s                     |     Y     |           786,432  |        65,536  |
| venu441mm                  |     Y     |           786,432  |        65,536  |
| venu445mm                  |     Y     |           786,432  |        65,536  |
| venud                      |     Y     |         1,048,576  |                |
| venusq                     |     Y     |           131,072  |                |
| venusq2                    |     Y     |           786,432  |        65,536  |
| venusq2m                   |     Y     |           786,432  |        65,536  |
| venusqm                    |     Y     |         1,048,576  |                |
| venux1                     |     Y     |           786,432  |        65,536  |
| vivoactive                 |     N     |            65,536  |                |
| vivoactive3                |     Y     |           131,072  |                |
| vivoactive3d               |     N     |           131,072  |                |
| vivoactive3m               |     Y     |         1,048,576  |                |
| vivoactive3mlte            |     Y     |         1,048,576  |                |
| vivoactive4                |     Y     |         1,048,576  |                |
| vivoactive4s               |     Y     |         1,048,576  |                |
| vivoactive5                |     Y     |           786,432  |        65,536  |
| vivoactive6                |     Y     |           786,432  |        65,536  |
| vivoactive_hr              |     N     |           131,072  |                |
| vivolife                   |     N     |                    |                |