# reverse scrolling
TOUCHPAD_ID=$(xinput list | sed -n '/Microsoft Surface Type Cover UNKNOWN.*slave *pointer/ { s/.*id=\([0-9]*\).*/\1/ p; q; }')
xinput set-button-map $TOUCHPAD_ID $(xinput get-button-map $TOUCHPAD_ID | sed 's/ 4 5 / 5 4 /')

# autolocking and plumbing into loginctl
xautolock -time 5 -locker "i3lock -n" &
xss-lock -- xautolock -locknow &

exec i3
