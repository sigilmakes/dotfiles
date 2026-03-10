#!/usr/bin/env bash

# Toggle night mode by sending SIGUSR1 to the nightmode daemon.
# The daemon handles the actual hyprsunset IPC and notifications.

PID_FILE="$XDG_RUNTIME_DIR/nightmode.pid"

if [[ -f "$PID_FILE" ]]; then
    pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
        kill -USR1 "$pid"
        exit 0
    fi
fi

notify-send -a "nightmode" "Night Mode" "Daemon not running"
