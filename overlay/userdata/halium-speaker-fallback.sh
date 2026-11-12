#!/bin/sh

restore_speaker() {
    default_sink=$(LC_ALL=C pactl info | sed -n 's/^Default Sink: //p')
    case "$default_sink" in
        sink.primary-out|sink.fast)
            pactl list short sinks | awk '$2 == "sink.speaker" {found=1} END {exit !found}' || return
            pactl set-default-sink sink.speaker || return
            ;;
        sink.speaker) ;;
        *) return ;;
    esac

    sinks=$(pactl list short sinks | awk '$2 == "sink.primary-out" || $2 == "sink.fast" {print $1}')
    for sink in $sinks; do
        for stream in $(pactl list short sink-inputs | awk -v id="$sink" '$2 == id {print $1}'); do
            pactl move-sink-input "$stream" sink.speaker
        done
    done
}

restore_speaker
LC_ALL=C pactl subscribe | while IFS= read -r event; do
    case "$event" in
        *" on server "*|*" on sink "*|*"Event 'new' on sink-input "*)
            restore_speaker
            ;;
    esac
done
