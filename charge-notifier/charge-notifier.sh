#! /bin/bash
#
# References:
# https://linoxide.com/remind-unplug-charging-laptop-arch-linux
# https://root.nix.dk/en/utility-scripts/battery-charge-notifier
#
# Some Bash syntax:
# https://stackoverflow.com/a/18668580
# https://stackoverflow.com/a/5431932
# https://stackoverflow.com/a/31339970
# https://stackoverflow.com/a/18829999
# https://stackoverflow.com/a/10552775
#


#
# Settings
INTERVAL=30 # Interval of the loop to repeat itself (in seconds)
SHOW=true   # Switch to show or not show pop-up
LOOP=true   # Switch to start loop


#
# Battery Levels
BAT_MAX=80
BAT_MIN=40
BAT_HIB=35


#
# Icons
#
# NOTE:
# It takes icons from GNOME's Adwaita icon pack.
# Support for other icons is not yet ready
ICO_LOC=/usr/share/icons/Adwaita/symbolic/status/
ICO_FULL=${ICO_LOC}battery-level-90-charging-symbolic.svg
ICO_LOW=${ICO_LOC}battery-caution-symbolic.svg
ICO_CRIT=${ICO_LOC}battery-level-0-symbolic.svg


#
# Charging Sounds
#
# NOTE:
# This are the locations inside vanilla Arch Linux with GNOME
# I'm unsure if the location is the same on Debian, Gentoo, Nix etc.
SND_LOC=/usr/share/sounds/freedesktop/stereo/
SND_WARN=${SND_LOC}dialog-warning.oga

### /END SETTINGS

set -eu


#
# Charge Status
isCharging() {
    STATUS=$( cat /sys/bus/acpi/drivers/battery/*/power_supply/BAT?/status )
    if [ $STATUS = "Charging" ]; then true; else false; fi
}
getPercent() {
    echo $(acpi|grep -Po "[0-9]+(?=%)")
}


#
# Battery Checks
isBatteryHigh() {
    #
    # Battery >= $BAT_MAX
    if $(isCharging); then
        if [ $(getPercent) -ge ${BAT_MAX} ]; then true; else false; fi
    else
        false
    fi
}
isBatteryLow() {
    #
    # $BAT_HIB < Battery <= $BAT_MIN
    if ! (( $(isCharging) )); then
        if [ $(getPercent) -gt ${BAT_HIB} ] && [ $(getPercent) -le ${BAT_MIN} ]; then true; else false; fi
    else
        false
    fi
}
isBatteryVeryLow() {
    #
    # Battery <= $BAT_HIB
    if ! (( $(isCharging) )); then
        if [ $(getPercent) -le ${BAT_HIB} ]; then true; else false; fi
    else
        false
    fi    
}


#
# Notifications
notify_dialog() {
    if [ $SHOW ]; then zenity --info --width=350 --title="${1}" --text="${2}"; fi    
}
notify_bubble() {
    TIME=$((INTERVAL*1000))
    if [ $SHOW ]; then notify-send -i $1 "$2" "$3"; fi
}
notify_sound() {
    if [ $SHOW ]; then pw-play --volume=100 ${SND_WARN}; fi
}
hibernate() {
    systemctl hibernate
}


#
# Service Loop
while $LOOP ; do
    #
    # Battery >= $BAT_MAX
    if $(isBatteryHigh); then
        notify_dialog "Your battery is full ($(getPercent)%)" "You might want to unplug your PC." & notify_bubble $ICO_FULL "Your battery is full" "You should unplug your device."
        notify_sound
    fi
    #
    # $BAT_HIB < Battery <= $BAT_MIN
    if $(isBatteryLow); then
        notify_dialog "Your battery is running low ($(getPercent)%)" "You might want to plug in your PC." & notify_bubble $ICO_LOW "Your battery is low" "You should plug in your device."
        notify_sound
    fi
    #
    # Battery < $BAT_HIB
    if $(isBatteryVeryLow); then
        if [ $(getPercent) -lt ${BAT_HIB} ]; then
            hibernate
        else
            notify_dialog "Your battery is critically low ($(getPercent)%)" "Your PC will hibernate soon." & notify_bubble $ICO_CRIT "Your battery is critically low" "You device will hibernate."
            notify_sound
        fi
    fi
    #
    # Repeat every $INTERVAL seconds
    sleep ${INTERVAL} 
done