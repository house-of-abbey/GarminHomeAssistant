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
|--------------------------------------|---------------:|-------------:|
| Declared available to application    |         98,304 |              |
| Measured available to application    |         94,112 | (4,192 less) |
| Application used                     |         65,696 |              |
| Free before fetching menu definition |         28,416 |              |
| Free after fetching menu definition  |         15,792 |       12,624 |
| Free after construction              |            936 |       14,856 |

Our test menu presently contains a mix of 28 items, consisting of nested group, toggle, tap, info and numeric items with templates. So each item requires (12,624 + 14,856) / 28 = 982 bytes.

## Garmin Devices

The following table details all the devices as at 1 October 2025 and whether they are supported by Garmin HomeAssistant. The available application memory is also detailed so that it can be compared to an application version listed above. Of particular concern are the 'Instinct' range of devices, being the smallest we currently support. New feature requests are now being vetted against how they might affect our ability to support the 'Instinct' range of devices. At some point support may have to be withdrawn in order to allow the Garmin HomeAssistant application to grow further.

| Device                     | Supported | Application Memory  |
|----------------------------|:---------:|--------------------:|
| d2bravo                    |     N     |              65,536 |
| d2bravo_titanium           |     N     |              65,536 |
| fenix3                     |     N     |              65,536 |
| fenix3_hr                  |     N     |              65,536 |
| fr230                      |     N     |              65,536 |
| fr235                      |     N     |              65,536 |
| fr630                      |     N     |              65,536 |
| fr920xt                    |     N     |              65,536 |
| vivoactive                 |     N     |              65,536 |
| descentg1                  |     Y     |              98,304 |
| instinct2                  |     Y     |              98,304 |
| instinct2s                 |     Y     |              98,304 |
| instinct2x                 |     Y     |              98,304 |
| instinctcrossover          |     Y     |              98,304 |
| approachs60                |     N     |             131,072 |
| enduro                     |     Y     |             131,072 |
| fenix5                     |     Y     |             131,072 |
| fenix5s                    |     Y     |             131,072 |
| fenix6                     |     Y     |             131,072 |
| fenix6s                    |     Y     |             131,072 |
| fenixchronos               |     Y     |             131,072 |
| fr245                      |     Y     |             131,072 |
| fr55                       |     Y     |             131,072 |
| fr645                      |     Y     |             131,072 |
| fr735xt                    |     N     |             131,072 |
| fr935                      |     Y     |             131,072 |
| instinct3solar45mm         |     Y     |             131,072 |
| instincte40mm              |     Y     |             131,072 |
| instincte45mm              |     Y     |             131,072 |
| venusq                     |     Y     |             131,072 |
| vivoactive3                |     Y     |             131,072 |
| vivoactive3d               |     N     |             131,072 |
| vivoactive_hr              |     N     |             131,072 |
| edge_520                   |     N     |             262,144 |
| fr255                      |     Y     |             524,288 |
| fr255s                     |     Y     |             524,288 |
| approachs50                |     Y     |             786,432 |
| approachs7042mm            |     Y     |             786,432 |
| approachs7047mm            |     Y     |             786,432 |
| d2airx10                   |     Y     |             786,432 |
| d2mach1                    |     Y     |             786,432 |
| descentg2                  |     Y     |             786,432 |
| descentmk343mm             |     Y     |             786,432 |
| descentmk351mm             |     Y     |             786,432 |
| enduro3                    |     Y     |             786,432 |
| epix2                      |     Y     |             786,432 |
| epix2pro42mm               |     Y     |             786,432 |
| epix2pro47mm               |     Y     |             786,432 |
| epix2pro47mmsystem7preview |     Y     |             786,432 |
| epix2pro51mm               |     Y     |             786,432 |
| fenix7                     |     Y     |             786,432 |
| fenix7pro                  |     Y     |             786,432 |
| fenix7pronowifi            |     Y     |             786,432 |
| fenix7s                    |     Y     |             786,432 |
| fenix7spro                 |     Y     |             786,432 |
| fenix7x                    |     Y     |             786,432 |
| fenix7xpro                 |     Y     |             786,432 |
| fenix7xpronowifi           |     Y     |             786,432 |
| fenix843mm                 |     Y     |             786,432 |
| fenix847mm                 |     Y     |             786,432 |
| fenix8pro47mm              |     Y     |             786,432 |
| fenix8solar47mm            |     Y     |             786,432 |
| fenix8solar51mm            |     Y     |             786,432 |
| fenixe                     |     Y     |             786,432 |
| fr165                      |     Y     |             786,432 |
| fr165m                     |     Y     |             786,432 |
| fr255m                     |     Y     |             786,432 |
| fr255sm                    |     Y     |             786,432 |
| fr265                      |     Y     |             786,432 |
| fr265s                     |     Y     |             786,432 |
| fr57042mm                  |     Y     |             786,432 |
| fr57047mm                  |     Y     |             786,432 |
| fr955                      |     Y     |             786,432 |
| fr965                      |     Y     |             786,432 |
| fr970                      |     Y     |             786,432 |
| instinct3amoled45mm        |     Y     |             786,432 |
| instinct3amoled50mm        |     Y     |             786,432 |
| instinctcrossoveramoled    |     Y     |             786,432 |
| marq2                      |     Y     |             786,432 |
| marq2aviator               |     Y     |             786,432 |
| system8preview             |     N     |             786,432 |
| venu2                      |     Y     |             786,432 |
| venu2plus                  |     Y     |             786,432 |
| venu2s                     |     Y     |             786,432 |
| venu3                      |     Y     |             786,432 |
| venu3s                     |     Y     |             786,432 |
| venu441mm                  |     Y     |             786,432 |
| venu445mm                  |     Y     |             786,432 |
| venusq2                    |     Y     |             786,432 |
| venusq2m                   |     Y     |             786,432 |
| venux1                     |     Y     |             786,432 |
| vivoactive5                |     Y     |             786,432 |
| vivoactive6                |     Y     |             786,432 |
| approachs62                |     N     |           1,048,576 |
| d2air                      |     Y     |           1,048,576 |
| edge1030                   |     Y     |           1,048,576 |
| edge1030bontrager          |     Y     |           1,048,576 |
| edge1030plus               |     Y     |           1,048,576 |
| edge1040                   |     Y     |           1,048,576 |
| edge1050                   |     Y     |           1,048,576 |
| edge520plus                |     Y     |           1,048,576 |
| edge530                    |     Y     |           1,048,576 |
| edge540                    |     Y     |           1,048,576 |
| edge550                    |     Y     |           1,048,576 |
| edge820                    |     Y     |           1,048,576 |
| edge830                    |     Y     |           1,048,576 |
| edge840                    |     Y     |           1,048,576 |
| edge850                    |     Y     |           1,048,576 |
| edgeexplore                |     Y     |           1,048,576 |
| edgeexplore2               |     Y     |           1,048,576 |
| edgemtb                    |     Y     |           1,048,576 |
| edge_1000                  |     N     |           1,048,576 |
| epix                       |     N     |           1,048,576 |
| fr645m                     |     Y     |           1,048,576 |
| legacyherocaptainmarvel    |     Y     |           1,048,576 |
| legacyherofirstavenger     |     Y     |           1,048,576 |
| legacysagadarthvader       |     Y     |           1,048,576 |
| legacysagarey              |     Y     |           1,048,576 |
| venu                       |     Y     |           1,048,576 |
| venud                      |     Y     |           1,048,576 |
| venusqm                    |     Y     |           1,048,576 |
| vivoactive3m               |     Y     |           1,048,576 |
| vivoactive3mlte            |     Y     |           1,048,576 |
| vivoactive4                |     Y     |           1,048,576 |
| vivoactive4s               |     Y     |           1,048,576 |
| d2charlie                  |     N     |           1,310,720 |
| d2delta                    |     Y     |           1,310,720 |
| d2deltapx                  |     Y     |           1,310,720 |
| d2deltas                   |     Y     |           1,310,720 |
| descentmk1                 |     N     |           1,310,720 |
| descentmk2                 |     Y     |           1,310,720 |
| descentmk2s                |     Y     |           1,310,720 |
| fenix5plus                 |     Y     |           1,310,720 |
| fenix5splus                |     Y     |           1,310,720 |
| fenix5x                    |     Y     |           1,310,720 |
| fenix5xplus                |     Y     |           1,310,720 |
| fenix6pro                  |     Y     |           1,310,720 |
| fenix6spro                 |     Y     |           1,310,720 |
| fenix6xpro                 |     Y     |           1,310,720 |
| fr245m                     |     Y     |           1,310,720 |
| fr745                      |     Y     |           1,310,720 |
| fr945                      |     Y     |           1,310,720 |
| fr945lte                   |     Y     |           1,310,720 |
| marqadventurer             |     Y     |           1,310,720 |
| marqathlete                |     Y     |           1,310,720 |
| marqaviator                |     Y     |           1,310,720 |
| marqcaptain                |     Y     |           1,310,720 |
| marqcommander              |     Y     |           1,310,720 |
| marqdriver                 |     Y     |           1,310,720 |
| marqexpedition             |     Y     |           1,310,720 |
| marqgolfer                 |     Y     |           1,310,720 |
| gpsmap66                   |     Y     |           2,359,296 |
| gpsmap67                   |     Y     |           2,359,296 |
| gpsmap86                   |     N     |           2,359,296 |
| gpsmaph1                   |     Y     |           2,359,296 |
| montana7xx                 |     Y     |           2,359,296 |
| oregon7xx                  |     N     |           2,359,296 |
| rino7xx                    |     N     |           2,359,296 |
