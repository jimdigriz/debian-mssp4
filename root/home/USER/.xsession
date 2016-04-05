# autolocking and plumbing into loginctl
xautolock -time 5 -locker "i3lock -n" &
xss-lock -- xautolock -locknow &

test -f "$HOME/.xbindkeysrc" && xbindkeys -n &

exec i3
