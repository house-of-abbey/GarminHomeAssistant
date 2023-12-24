# Troubleshooting Guide

With either of the following setups, there are inevitably some problems along the way. GarminHomeAssistant is careful to rely only on having working URLs. Getting them working is the user's responsibility. However, we have developed some fault finding tools.

## Nabu Casa Setup

You can purchase cloud-based access to your Home Assistant from [Nabu Casa](https://www.nabucasa.com/), and then your setup will look something like this.

![Nabu Casa Setup](images/nabu_casa_setup.png)

* Your API URL would be of the format `https://<id>.ui.nabu.casa/api`
* Your Garmin Watch Menu would be of the format Menu: `https://<id>.ui.nabu.casa/local/garmin/menu.json`

Where `<id>` is your personal Nabu Casa account ID.

## Do It Yourself Setup

Before Nabu Casa, or if you wanted to manage your own infrastructure, you might have something like the following:

![Do It Yourself Setup](images/do_it_yourself_setup.png)

Now you have to manage:

* Dynamic DNS
* Public access via router port forwarding
* Security via HTTPS and URL forwarding
* Certificates for HTTPS via say [Let's Encrypt](https://letsencrypt.org/) (Nginx web server helps here)
* Proxy allow list in `configuration.yaml` as follows:

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 127.0.0.1
    - 192.168.xx.xx  # Server IP - AMEND THIS
    - 172.30.32.0/23 # Docker IPs for NGINX
    - 172.30.33.0/24 # SSL proxy server
    - 172.16.0.0/12  #
```

## Menu Configuration URL

This URL is very simple, you should be able to read the contents returned in a standard web browser.

![Browser Address Bar URL](images/menu_url.png)

(Other browsers are available...)

The browser page should then display the JSON string you saved to the file on the web server. The point is this is a simple HTTP GET request with no bells and whistles.

The menu configuration can be hosted anywhere, it does not have to be on the Home Assistant web server. Just as long as it is reachable from your phone from which you Bluetooth connect to your watch, or you watch if it has direct Internet access.

## Home Assistant API URL

This is slightly trickier owning to the need to supply the API key. Here are three ways you can test your API URL is correctly configured. If successful, each of these should produce a JSON string output looking like:

```json
{"message":"API running."}
```

### Linux, MacOS, UNIX, Cygwin etc

Save the following as a file called `api_test.sh`, edit to include your personal values for the variables, `chmod +x api_test.sh` and then execute with `./api_test.sh`.

```shell
#!/bin/bash

API_KEY="<Your API key>"
URL="https://<Your Domain>/api"

curl -s -X GET \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  ${URL}/
```

### MS Windows

Save the following as a file called `api_test.cmd`, edit to include your personal values for the variables and then double click.

```shell
@echo off

set API_KEY=<Your API key>
set URL=https://<Your Domain>/api

curl -s -X GET ^
  -H "Authorization: Bearer %API_KEY%" ^
  -H "Content-Type: application/json" ^
  %URL%/

echo.
pause
```

![API Test MS-DOS Output](images/api_test_dos_output.png)

### On-line

There's an online way of testing the API URL too, thanks to [REQBIN](https://reqbin.com/post-online). This has less setup and it can be saved if you log into the web site.

![API Test MS-DOS Output](images/api_test_online.png)

## Top Problems

1. Failure to copy & paste keys and URLs leading to minor and hard to see errors in strings, even with protestations they are the same! (No they weren't...)
2. Accessibility of URLs, hence the above help guide.
