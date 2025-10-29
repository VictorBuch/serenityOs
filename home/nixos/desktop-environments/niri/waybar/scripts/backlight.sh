#!/usr/bin/env bash
# Backlight control script for Waybar

ACTION="$1"  # "up" or "down"

case "$ACTION" in
    up)
        brightnessctl set 5%+
        ;;
    down)
        brightnessctl set 5%-
        ;;
    *)
        echo "Usage: $0 {up|down}"
        exit 1
        ;;
esac
