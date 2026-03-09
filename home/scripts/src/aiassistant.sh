#!/usr/bin/env bash

# AI Assistant Launcher
# Opens a new kitty terminal window with AI assistant
# Supports image display via gwenview workaround

# Show help message
show_help() {
    cat << EOF
Usage: $(basename "$0") <AI_ASSISTANT_COMMAND> [OPTIONS]

Launch AI assistant in a new kitty terminal window.

ARGUMENTS:
    AI_ASSISTANT_COMMAND    Command to launch AI assistant (e.g., claude, aichat)

OPTIONS:
    -h, --help          Show this help message and exit
    -d, --directory DIR Set working directory (default: \$HOME)
    -f, --float         Launch in floating window (80% size, centered)

EXAMPLES:
    $(basename "$0") claude                    # Launch Claude Code in home directory
    $(basename "$0") claude -d ~/projects      # Launch in ~/projects
    $(basename "$0") claude --float            # Launch in floating window
    $(basename "$0") aichat                    # Launch aichat

NOTES:
    - Window class: ai-assistant
    - Images can be viewed using gwenview as a workaround
    - AI assistant is configured in userprefs.conf (\$aiassistant variable)

EOF
    exit 0
}

# Parse command line arguments
WINDOW_MODE="normal"
AI_ASSISTANT=""

# First argument should be the AI assistant command
if [[ $# -gt 0 && "$1" != -* ]]; then
    AI_ASSISTANT="$1"
    shift
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -d|--directory)
            WORKING_DIR="$2"
            shift 2
            ;;
        -f|--float)
            WINDOW_MODE="float"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Terminal configuration
TERM="kitty"
TERM_CLASS="ai-assistant"
TERM_TITLE="AI Assistant"

# Working directory (default to HOME if not set)
WORKING_DIR="${WORKING_DIR:-$HOME}"

# Check if AI assistant command was provided
if [[ -z "$AI_ASSISTANT" ]]; then
    # Create error message script
    ERROR_SCRIPT=$(mktemp)
    cat > "$ERROR_SCRIPT" << 'EOF'
#!/usr/bin/env bash
echo "=========================================="
echo "ERROR: No AI assistant specified"
echo "=========================================="
echo ""
echo "If using through the hyprland keybinding, please set the $aiassistant variable in:"
echo "  ~/.config/hypr/hyprland.conf"
echo ""
echo "Example:"
echo "  \$aiassistant = claude"
echo ""
echo -e "\033[31mPress Enter to close...\033[0m"
read
EOF
    chmod +x "$ERROR_SCRIPT"

    case "$WINDOW_MODE" in
        float)
            hyprctl dispatch exec "[float on; size monitor_w*0.6 size monitor_h*0.6; center on] $TERM --class $TERM_CLASS --title \"$TERM_TITLE - Error\" -e bash -c '$ERROR_SCRIPT; rm $ERROR_SCRIPT'"
            ;;
        normal|*)
            $TERM \
                --class "$TERM_CLASS" \
                --title "$TERM_TITLE - Error" \
                -e bash -c "$ERROR_SCRIPT; rm $ERROR_SCRIPT"
            ;;
    esac
    exit 1
fi

# Check if AI assistant is installed
if ! command -v "$AI_ASSISTANT" &> /dev/null; then
    notify-send "AI Assistant" "$AI_ASSISTANT not found. Please install it first." -u critical
    echo "Error: $AI_ASSISTANT command not found"
    exit 1
fi

# Update title with assistant name
TERM_TITLE="$AI_ASSISTANT"

# Launch AI assistant in new kitty terminal
# The kitty terminal natively supports the kitty graphics protocol
# Images can be viewed using gwenview as a workaround

case "$WINDOW_MODE" in
    float)
        hyprctl dispatch exec "[float on; size monitor_w*0.6 size monitor_h*0.6; center on] $TERM --class $TERM_CLASS --title \"$TERM_TITLE\" --directory \"$WORKING_DIR\" -e $AI_ASSISTANT"
        ;;
    normal|*)
        cd "$WORKING_DIR" && \
        $TERM \
            --class "$TERM_CLASS" \
            --title "$TERM_TITLE" \
            --directory "$WORKING_DIR" \
            -e "$AI_ASSISTANT"
        ;;
esac
