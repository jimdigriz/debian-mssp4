#!/bin/sh
#
# acpi-wakeup: test

set -eu

case "$1" in
pre)
	# if the cover is plugged in, wake on any cover events,
	# otherwise make the user use the power button instead
	if test -d /sys/bus/usb/devices/usb1/1-7; then
		grep -q 'XHC.*enabled' /proc/acpi/wakeup || echo XHC > /proc/acpi/wakeup
		echo enabled > /sys/bus/usb/devices/usb1/power/wakeup
		echo enabled > /sys/bus/usb/devices/usb1/1-7/power/wakeup
	else
		grep -q 'XHC.*enabled' /proc/acpi/wakeup && echo XHC > /proc/acpi/wakeup
	fi
	;;
post)
	# stops additional lid events coming in that on resume put the laptop back to sleep
	echo disabled > /sys/bus/usb/devices/usb1/power/wakeup
	;;
esac

exit 0
