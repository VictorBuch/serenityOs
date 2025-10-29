#!/usr/bin/env bash
# Volume control script for Waybar
# Supports both PulseAudio and WirePlumber via wpctl

DEVICE="$1"  # "output" or "input"
ACTION="$2"  # "mute", "raise", "lower"

case "$DEVICE" in
    output)
        SINK="@DEFAULT_AUDIO_SINK@"
        ;;
    input)
        SINK="@DEFAULT_AUDIO_SOURCE@"
        ;;
    *)
        echo "Usage: $0 {output|input} {mute|raise|lower}"
        exit 1
        ;;
esac

case "$ACTION" in
    mute)
        wpctl set-mute "$SINK" toggle
        ;;
    raise)
        wpctl set-volume "$SINK" 5%+
        ;;
    lower)
        wpctl set-volume "$SINK" 5%-
        ;;
    *)
        echo "Usage: $0 {output|input} {mute|raise|lower}"
        exit 1
        ;;
esac
