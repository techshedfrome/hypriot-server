# Techshed Docker Server (on Raspberry Pi)

The plan here is to have a simple Docker host running on a Pi for internal use in Techshed sessions.

Initial service defined is an InfluxDb data store, with a Grafana dashboard for Luftdaten data sent to the influx instance.

It should be a reproducible build, with as few manual steps as possible before a usable service appears.

NOTE: the `user-data` file included in this repo contains default a Linux useranme and password that's applied to the server.  This should be changed in your copy of the `user-data` file before real-world deployment.

# Hypriot OS
## Basic manual setup:

* get the latest Hypriot SD card image from https://github.com/hypriot/image-builder-rpi/releases/
* flash an SD card with CLI (e.g. `dd` command) or https://www.balena.io/etcher or https://github.com/hypriot/flash
* Make sure newly flashed SD card is mounted 
* Modify `user-data` file on the boot sector of the SD card by:
  * un-commenting the Wifi setup lines (section starting `write_files:`and ending with `path: /etc/wpa_supplicant/wpa_supplicant.conf`)

## Extended Setup to Bring Services (using `docker-compose`)

Using the custom `user-data` in this repo, we can bring up Telegraf+Influx+Grafana services with preconfigured dashboards for System Info + Luftdaten by booting the SD card image from the below on a Raspberry Pi.

### Detail 
The aim here was to automatically configure some Docker containers and bring them up without manual intervention.

Since Hypriot uses `cloud-init` we have a mechanism for runnig custom commands on first boot.

I've prepared the shell script below to bring up our TIG (telegraf, influx, grafana) services (containing system monitoring + Luftdaten dashboards).

It includes some additonal lines to try to get a reliable initial boot (there were some problems with WiFi and Docker daemon not comming up on first boot), but the main aim is to clone down our TIG stack and bring it up using Docker-compose.

```sh
#!/bin/bash
sudo killall wpa_supplicant
sudo ifdown wlan0
sudo ifup wlan0
sleep 10

mkdir -p /home/pirate/docker
cd /home/pirate/docker
git clone https://github.com/techshedfrome/docker-telegraf-influx-grafana-stack.git

service docker restart
sleep 20

cd docker-telegraf-influx-grafana-stack
docker-compose up -d
```

This script is included as part of the custom `user-data` file (saved out as an init.sh file to enable re-running/debugging).

On first boot (assuming no WiFi or power glitches)

## A Less Manual Process (reduces need to manually edit files):

Hypriot's flash tool includes options to set the WiFi credentials on the CLI, but it's not currently implemented for the clout-init process (which uses `user-data`)

SO, I've included a wrapper for the Hypriot Flash command, which inserts the WiFi credentials in a custom `user-data` file for use with the flash tool.

Notes:
* assumes the Hypriot flash tool is already installed
* requires a custom `user-data` file to be used (this fits our use-case since we have custom scripts to run on first boot)
* custom `user-data` file must have a non-commented out wifi section already present (as per example `user-data` in this repo)

Example calling of my wrapper script to flash the SD card with custom `user-data` and WiFi creds.
```bash
sh flash-wifi.sh  \
-u 'user-data' -n 'myHostname' -s 'MySSID' -p 'MyPSK' \
-d /dev/disk2 -i hypriotos-rpi-v1.12.0.img.zip
```


---



# Notes From Initial Setup

* Had some issues with Hypriot's flash tool on Ubuntu - it reported that the SD card was readonly - not sure if that is a mount mode/permissions, but it's reported as if it's the read-only tab on the physical card, which was set to allow write.
* Other device customisation in RPi config (could be applied via `cloud-init` custom commands on first boot) - https://www.raspberrypi.org/documentation/configuration/config-txt/README.md


## Influx/Graphana docker-compose

* Could do with pre-loading these into the Hypriot image to save time on first boot.
  * get local images into Docker on boot using https://github.com/hypriot/device-init ? (device-init is deprecated though)
* Original versions found - https://github.com/nicolargo/docker-influxdb-grafana.git
* this one configures provisioning folder as volume - https://github.com/bcremer/docker-telegraf-influx-grafana-stack

## Graphana auto-config/provisioning

* Graphana dashboard for Luftdaten: https://grafana.com/grafana/dashboards/11548
 * if possible, add dropdown to enable separate sensors to be listed (mot sure whether sensorid is included in the data)
   * measurements contain `F(",node=" SENSOR_BASENAME);`

* Graphana provisioning - allows pre-config of datasources & dashboards
  * https://grafana.com/docs/grafana/latest/administration/provisioning/#datasources
  * https://grafana.com/docs/grafana/latest/administration/provisioning/#dashboards

## mDNS (e.g. `mydomain.local`)
Some routers appear to block multicast.  
In such cases, mDNS for the custom hostname won't be available.
