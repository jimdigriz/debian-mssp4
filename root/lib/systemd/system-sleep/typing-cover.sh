#!/bin/sh
#
# typing-cover: let the typing cover wake us up, done here to prevent double event leading to wakeup

set -eu

case "$1" in
pre)
	echo enabled > /sys/bus/usb/devices/usb1/power/wakeup
	[ ! -d /sys/bus/usb/devices/usb1/1-7 ] || echo enabled > /sys/bus/usb/devices/usb1/1-7/power/wakeup
	;;
post)
	echo disabled > /sys/bus/usb/devices/usb1/power/wakeup
	[ ! -d /sys/bus/usb/devices/usb1/1-7 ] || echo disabled > /sys/bus/usb/devices/usb1/1-7/power/wakeup
	;;
esac

exit 0
