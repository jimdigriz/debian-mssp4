#!/bin/sh
#
# acpi-wakeup: test

set -eu

case "$1" in
pre)
	grep -q 'XHC.*enabled' /proc/acpi/wakeup || echo XHC > /proc/acpi/wakeup
	echo enabled > /sys/bus/usb/devices/usb1/power/wakeup
	test -d /sys/bus/usb/devices/usb1/1-7 && echo enabled > /sys/bus/usb/devices/usb1/1-7/power/wakeup
	;;
post)
	# stops additional lid events coming in that on resume put the laptop back to sleep
	echo disabled > /sys/bus/usb/devices/usb1/power/wakeup
	;;
esac

exit 0
