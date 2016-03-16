#!/bin/sh
#
# mwifiex_pcie: handle the flakey wifi

set -eu

case "$1" in
pre)
	ifdown --force mlan0 || true
	modprobe -r mwifiex_pcie
	;;
post)
	modprobe mwifiex_pcie
	;;
esac

exit 0
