#! /bin/bash
_pkg="charge-notifier"

#
# Sudo privilege checker
if [[ $EUID != 0 ]]; then
	echo -e "\nERROR\nMust be run as root (i.e: 'sudo $0')\n"
	exit 1
fi

#
# Install Service
if [ "$(ps h -o comm 1)" = "systemd" ]; then
    cp /usr/local/share/$_pkg/$_pkg.service /etc/systemd/system/;
fi