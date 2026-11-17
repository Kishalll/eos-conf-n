#!/bin/bash
FULLSCREEN=$(hyprctl activewindow -j | jq -r '.fullscreen')

if [ "$FULLSCREEN" = "1" ]; then
    hyprctl --batch "dispatch cyclenext ; dispatch fullscreen 1"
else
    hyprctl dispatch cyclenext
fi
