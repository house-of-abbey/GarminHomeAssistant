[Home](README.md) | [Switches](examples/Switches.md) | [Actions](examples/Actions.md) | [Templates](examples/Templates.md) | [Numeric](examples/Numeric.md) | [Select](examples/Select.md) | [Glance](examples/Glance.md) | [Background Service](BackgroundService.md) | [Wi-Fi](Wi-Fi.md) | [HTTP Headers](HTTP_Headers.md) | [Trouble Shooting](TroubleShooting.md) | [Version History](HISTORY.md)

# Wi-Fi & LTE

Many watches now include the ability to synchronise data over Wi-Fi or event LTE in addition to Bluetooth. This gives users of this application the expectation that they should be able to operate HomeAssistant devices from their watch without Bluetooth and hence their phone (that they left out of contact distance). The whole point of Bluetooth after all is that it is [low power](https://en.wikipedia.org/wiki/Bluetooth#Uses). Using Wi-Fi and LTE are power hungry and therefore not something that can be left on continuously in a small device. The watch function that uses Wi-Fi & LTE is the ability to 'synchronise', e.g. activity data (FIT files) and application updates. This function then has a limited period of time for which radio is active. Neither Wi-Fi nor LTE are "always on" like Bluetooth.

With version 3.0 onwards the application now includes the ability to temporarily turn on Wi-Fi or LTE in order to perform a task on the watch. To do this, the "synchronise" function of the Connect IQ SDK has been cleverly hijacked. This appears to be a highly sought after solution from several users as **it allows the watch to operate when out of range of the associated phone**.

## Limits of Use

1. An API request issued over Wi-Fi requires the watch to open up an IP connection to your Wi-Fi access point. This means setting up a secure channel with WPA and being allocated an IP address. Establishing the communication channel takes a short while. _You will see that this adds a noticeable delay to usability._

2. **The Wi-Fi/LTE functionality can only be used when the menu is already cached.** _The watch will not perform an HTTPS GET request to retrieve the JSON menu file_. Therefore, to enable the Wifi/LTE functionality in the application settings, you must enable caching first.

3. The menu item statuses will not be set correctly. Instead you will be warned about the lack of connectivity by a 'toast', i.e. message partially occupying the top of the screen temporarily. Fetching the menu item statuses, including rendered templates, requires its own API call, hence this not performed.

4. Remember that you need to be within range of your watch's configured Wi-Fi access point to utilize this functionality. If supported by your device, LTE offers a longer range, but network charges may apply.

5. **Transport Layer Security (TLS) settings.** The following insights have been submitted by App users. The authors cannot verify the details in anyway as we don't have the same infrastructure, but we are very grateful these users took the time to share their solutions for others to benefit from.

   Ali Alaei ([@aalaei](https://github.com/aalaei)), [resolved a Cloudflare TLS issue](https://github.com/house-of-abbey/GarminHomeAssistant/pull/266) as follows:

   <div style="margin:30px;padding:20px;background-color:lightgrey;border:1px solid black;border-radius: 10px;">

   On some Garmin devices, the HTTPS handshake is performed using **TLS 1.2**. If your server or proxy enforces a higher minimum (e.g., TLS 1.3), you will encounter an SSL handshake error with the message:

   ```text
   HTTP request returned error code = 0
   ```

   This limitation only affects **Wi-Fi/LTE connections**. When connected over **Bluetooth**, the watch routes requests through the paired phone, which handles the TLS handshake and supports newer TLS versions (such as 1.3) without issue.

   To fix this, lower the minimum TLS setting to allow TLS 1.2. For example, if you are using **Cloudflare Tunneling**, go to:
   `SSL/TLS → Edge Certificates → Minimum TLS Version`
   and set it to **at most TLS 1.2**. _Reducing below TLS 1.2 is not recommended due to security risks._
   </div>

   Another user, [@xhemart](https://github.com/xhemart), [reports some research](https://github.com/house-of-abbey/GarminHomeAssistant/issues/292#issuecomment-5360598790) to further diagnose this issue:

   <div style="margin:30px;padding:20px;background-color:lightgrey;border:1px solid black;border-radius: 10px;">

   I ran a direct test against my own Nabu Casa endpoint with openssl s_client, forcing specific cipher suites, and it turns out **TLS version was never the actual constraint**. My server accepts TLS 1.2 just fine (confirmed with `ECDHE-RSA-AES128-GCM-SHA256`). What it does _not_ accept is any cipher suite using plain RSA key exchange (no forward secrecy) — regardless of whether the bulk cipher is a modern AEAD one or an old CBC/SHA1 one:

   Test                                  | Forced Configuration              | Result
   :-------------------------------------|:----------------------------------|:-----------------------------------
   Default negotiation                   | —                                 | ✅ TLS 1.3, TLS_AES_256_GCM_SHA384
   TLS 1.2, RSA key exchange, CBC/SHA1   | e.g. `AES128-SHA`                 | ❌ Handshake failure
   TLS 1.2, RSA key exchange, GCM (AEAD) | e.g. `AES256-GCM-SHA384`          | ❌ Handshake failure
   TLS 1.2, ECDHE, CBC/SHA1              | e.g. `ECDHE-RSA-AES128-SHA`       | ❌ Handshake failure
   TLS 1.2, ECDHE, GCM (AEAD)            | e.g. `ECDHE-RSA-AES128-GCM-SHA256`| ✅ works

   So the actual server-side requirement is **forward secrecy (ECDHE)** — it rejects any RSA-key-exchange `ClientHello` outright, independent of TLS version or bulk cipher.

   This lines up with a bug Garmin itself has acknowledged for the Epix (Gen 2) / Fenix 7: [TLS Certificate issue with Fenix 7 and Epix (Gen 2)](https://forums.garmin.com/developer/connect-iq/i/bug-reports/tls-certificate-issue-with-fenix-7-and-epix-gen-2). Per that thread, when these watches negotiate TLS directly over Wi-Fi (i.e. without the phone relaying via Bluetooth), they only offer legacy RSA-key-exchange cipher suites with no forward secrecy — exactly the class of suite my server rejects. Over Bluetooth the phone performs the TLS handshake instead, which explains why it always works there. Garmin marked that report "Complete," but the thread has follow-up comments disputing that, and no new cipher suites appear to have shown up on affected devices since.
   </div>

   So, it's a Garmin device side limitation (in some models) of the Connect IQ TLS stack when negotiating directly over Wi-Fi, that might be fixed by amending the TLS settings on the server if you are fortunate. Some Garmin devices only speak cipher suites without forward secrecy, which most modern TLS termination (Nabu Casa, Cloudflare, current nginx/Apache defaults, etc.) rejects by design for good security reasons. There's no app-side workaround available; it would need a firmware fix from Garmin. By "some models" we mean it is confirmed on Epix (Gen 2); likely related on Fenix 7 Pro and Forerunner 265; possibly related on Forerunner 970 (unconfirmed).

   For anyone on the same models looking for a local-network route, of the options in the [README, only #2](https://github.com/house-of-abbey/GarminHomeAssistant#no-https) (local DNS override to `garmincdn.com` serving plain HTTP) sidesteps the cipher-suite issue entirely, since it avoids TLS altogether. You will still need to verify whether these watches actually honour a local DHCP-provided DNS server for that override, or alternatively hard code public resolvers.

## Video

This video using will hopefully make it obvious how slow it is to use the Wi-Fi option and illustrate the cautionary notes above.

https://github.com/user-attachments/assets/269981e9-12dc-44f2-a28f-b8e844b2b2f8

### Please Note

We emphasize that the Wi-Fi/LTE functionality should be viewed as a 'last resort' method for executing tasks when your phone is not available. It is not recommended as a continuous mode of operation.

## Credits

With thanks to Vincent, [@vincentezw](https://github.com/vincentezw) for contributing this solution, and to Ali Alaei, [@aalaei](https://github.com/aalaei), and [@xhemart](https://github.com/xhemart) for the finer details on TLS and resolving issue [292](https://github.com/house-of-abbey/GarminHomeAssistant/issues/292).
