# autolocking and plumbing into loginctl
xautolock -time 5 -locker "i3lock -n" &
xss-lock -- xautolock -locknow &

if test -f "$HOME/.xbindkeysrc"; then
	 xbindkeys -n &
fi

exec i3
