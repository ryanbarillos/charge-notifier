#! /bin/bash
#
# Script to notify when battery is outside levels - time to plug charger.
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.#
#
# Source: https://linoxide.com/remind-unplug-charging-laptop-arch-linux
# Source: https://root.nix.dk/en/utility-scripts/battery-charge-notifier
#
# @linux-aarhus - root.nix.dk
#
# 2021-11-27
# 2021-11-28 revised - checks not updating
#                    - fix variable check on all levels
# 2023-03-14         - added sound option

# SETTINGS
INTERVAL=30 # Interval of the loop to repeat itself (in seconds)
SHOW=true   # Switch to show or not show pop-up
LOOP=true   # Switch to start loop

# ICONS
ICO_LOC=/usr/share/icons/Adwaita/symbolic/status/
ICO_FULL=${ICO_LOC}battery-level-90-charging-symbolic.svg
ICO_LOW=${ICO_LOC}battery-caution-symbolic.svg
ICO_CRIT=${ICO_LOC}battery-level-0-symbolic.svg

# Battery Levels
BAT_MAX=80
BAT_MIN=40
BAT_HIB=35





# Charging Sounds
SND_LOC=/usr/share/sounds/freedesktop/stereo/
SND_WARN=${SND_LOC}dialog-warning.oga

### /END SETTINGS

set -eu

# dependency check
if ! [[ "$(which notify-send)" =~ (notify-send) ]]; then
    echo "Please install libnotify to use this script.\n"
    echo "   sudo pacman -S libnotify"
    exit 1
fi
if ! [[ "$(which acpi)" =~ (acpi) ]]; then
    echo "Please install acpi to use this script.\n"
    echo "   sudo pacman -S acpi"
    exit 1
fi
if ! [[ "$(which zenity)" =~ (zenity) ]]; then
    echo "Please install zenity to use this script.\n"
    echo "   sudo pacman -S zenity"
    exit 1
fi

# Charge Status
get_plugged_state() {
    echo $(cat /sys/bus/acpi/drivers/battery/*/power_supply/BAT?/status)
}
get_bat_percent() {
    echo $(acpi|grep -Po "[0-9]+(?=%)")
}

# Notifications
notify_dialog() {
    # if [ $SHOW = true ]; then zenity --info --width=350 --timeout=$INTERVAL --title="${1}" --text="${2}"; fi    
    if [ $SHOW = true ]; then zenity --info --width=350 --title="${1}" --text="${2}"; fi    
}
notify_bubble() {
    TIME=$((INTERVAL*1000))
    # if [ $SHOW = true ]; then notify-send -t $TIME  -i $1 "$2" "$3"; fi
    if [ $SHOW = true ]; then notify-send -i $1 "$2" "$3"; fi
}
notify_sound() {
    if [ $SHOW = true ]; then pw-play --volume=100 ${SND_WARN}; fi
}
hibernate() {
    systemctl hibernate
}

# primary loop
while true ; do
    # Battery is full
    if [ $(get_bat_percent) -ge ${BAT_MAX} ]; then
        if [[ $(get_plugged_state) = "Charging" ]]; then 
            notify_dialog "Your battery is full ($(get_bat_percent)%)" "You might want to unplug your PC." & notify_bubble $ICO_FULL "Your battery is full" "You should unplug your device."
            notify_sound
            SHOW=false
        fi
    fi
    # Battery is low
    if [ $(get_bat_percent) -gt ${BAT_HIB} ] && [ $(get_bat_percent) -le ${BAT_MIN} ]; then
        if [[ $(get_plugged_state) = "Discharging" ]]; then
            SHOW=true
            notify_dialog "Your battery is running low ($(get_bat_percent)%)" "You might want to plug in your PC." & notify_bubble $ICO_LOW "Your battery is low" "You should plug in your device."
            notify_sound
        else
            SHOW=false
        fi
    fi
    # Battery is critically now
    if [ $(get_bat_percent) -le ${BAT_HIB} ]; then
        if [[ $(get_plugged_state) = "Discharging" ]]; then
            if [ $(get_bat_percent) -lt ${BAT_HIB} ]; then
                hibernate
            else
                SHOW=true
                notify_dialog "Your battery is critically low ($(get_bat_percent)%)" "Your PC will hibernate soon." & notify_bubble $ICO_CRIT "Your battery is critically low" "You device will hibernate."
                notify_sound
            fi
        else
            SHOW=false
        fi
    fi

    # Repeat every $INTERVAL seconds
    sleep ${INTERVAL} 
done