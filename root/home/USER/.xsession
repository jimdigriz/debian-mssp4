# autolocking and plumbing into loginctl
xautolock -time 5 -locker "i3lock -n" &
xss-lock -- xautolock -locknow &

exec i3
