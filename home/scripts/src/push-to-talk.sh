#!/bin/bash

# Push-to-talk script for Hyprland
# Uses arecord for recording, whisper-cli for transcription, wtype for typing

AUDIO_FILE="/tmp/ptt_recording.wav"
PID_FILE="/tmp/ptt_recording.pid"
WHISPER_PID_FILE="/tmp/ptt_whisper.pid"
MODEL="$HOME/.local/share/whisper.cpp/models/ggml-base.en.bin"

start_recording() {
    # Kill any existing recording
    if [[ -f "$PID_FILE" ]]; then
        kill "$(cat "$PID_FILE")" 2>/dev/null
        rm -f "$PID_FILE"
    fi

    # Kill any existing whisper-cli process
    if [[ -f "$WHISPER_PID_FILE" ]]; then
        kill "$(cat "$WHISPER_PID_FILE")" 2>/dev/null
        rm -f "$WHISPER_PID_FILE"
    fi

    # Start recording (16kHz mono for whisper)
    arecord -f S16_LE -r 16000 -c 1 "$AUDIO_FILE" &
    echo $! > "$PID_FILE"

    notify-send -t 1500 -u low "Push-to-Talk" "Recording..." -i microphone-sensitivity-high
}

stop_and_transcribe() {
    if [[ ! -f "$PID_FILE" ]]; then
        exit 0
    fi

    # Stop recording
    kill "$(cat "$PID_FILE")" 2>/dev/null
    rm -f "$PID_FILE"

    # Wait for file to be written
    sleep 0.1

    if [[ ! -f "$AUDIO_FILE" ]]; then
        notify-send -t 2000 -u critical "Push-to-Talk" "Recording failed" -i microphone-sensitivity-muted
        exit 1
    fi

    # Transcribe with whisper (track PID so we can kill it if needed)
    WHISPER_OUTPUT="/tmp/ptt_whisper_output.txt"
    whisper-cli -m "$MODEL" -nt "$AUDIO_FILE" > "$WHISPER_OUTPUT" 2>/dev/null &
    WHISPER_PID=$!
    echo "$WHISPER_PID" > "$WHISPER_PID_FILE"
    wait "$WHISPER_PID"
    rm -f "$WHISPER_PID_FILE"
    text=$(tr -d '\n' < "$WHISPER_OUTPUT" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    rm -f "$WHISPER_OUTPUT"

    # Clean up audio file
    rm -f "$AUDIO_FILE"

    # Type the result if we got any text
    if [[ -n "$text" ]]; then
        wtype -- "$text"
        # Show truncated preview in notification
        preview="${text:0:50}"
        [[ ${#text} -gt 50 ]] && preview="${preview}..."
        notify-send -t 2000 -u normal "Push-to-Talk" "$preview" -i input-keyboard
    else
        notify-send -t 2000 -u low "Push-to-Talk" "No speech detected" -i microphone-sensitivity-low
    fi
}

case "$1" in
    start)
        start_recording
        ;;
    stop)
        stop_and_transcribe
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac
