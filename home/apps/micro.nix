# Micro text editor configuration.
#
# Home Manager doesn't have a dedicated programs.micro module, so we use
# home.file to place config files directly into ~/.config/micro/.
#
# Micro reads two main config files:
#   - settings.json: editor behavior (tab size, wrapping, colorscheme, etc.)
#   - bindings.json: custom keybindings
#
# PLUGINS:
# Micro manages its own plugins at ~/.config/micro/plug/. We install them
# via an activation script on first rebuild — after that, micro handles
# updates itself. Current plugins:
#   - aspell: spellcheck integration
#   - filemanager: tree sidebar (F1)
#   - fzf: fuzzy file finder (Ctrl-p)
#   - manipulator: text manipulation (case, quotes, etc.)
#   - mdfried: markdown preview (Alt-m)
#
# COLORSCHEME:
# Uses "simple-custom" — a tweak of the built-in "simple" theme that tones
# down TODO/FIXME highlighting. The colorscheme file is placed alongside.

{ config, pkgs, lib, ... }:

{
    home.packages = with pkgs; [
        micro   # the text editor itself
        fzf     # fuzzy finder — needed by the micro fzf plugin (Ctrl-p)
        aspell  # spellchecker — needed by the micro aspell plugin
        aspellDicts.en  # English dictionary for aspell
    ];

    # --- Custom colorscheme ---
    # "simple-custom" extends the built-in "simple" theme.
    # Micro looks for colorschemes in ~/.config/micro/colorschemes/.
    home.file.".config/micro/colorschemes/simple-custom.micro".source = ./micro/colorschemes/simple-custom.micro;

    # --- Custom syntax highlighting ---
    # WGSL (WebGPU Shading Language) — not included in micro's defaults.
    home.file.".config/micro/syntax/wgsl.yaml".source = ./micro/syntax/wgsl.yaml;

    # --- Plugins ---
    # These are Willow's homebrew/customised micro plugins, placed directly.
    # Not from the micro plugin channel — managed as part of this config.
    #   - aspell: spellcheck integration
    #   - filemanager: tree sidebar (F1)
    #   - fzf: fuzzy file finder (Ctrl-p)
    #   - manipulator: text manipulation (case, quotes, etc.)
    #   - mdfried: markdown preview in terminal (Alt-m)
    home.file.".config/micro/plug" = {
        source = ./micro/plug;
        recursive = true;
    };

    # --- Settings ---
    # home.file."path".text creates a file at ~/path with the given content.
    # The ".config/micro/settings.json" path is relative to $HOME.
    home.file.".config/micro/settings.json".text = builtins.toJSON {

        # --- Per-filetype overrides ---
        # Keys starting with "*." apply only to files matching that glob.
        # These disable spellcheck for common text formats (too noisy).
        "*.md" = { "aspell.check" = "on"; };
        "*.tex" = { "aspell.check" = "off"; };
        "*.txt" = { "aspell.check" = "off"; };

        # --- Global settings ---

        # Spellcheck off globally (the per-filetype overrides above are
        # redundant but kept for clarity / if the global is ever toggled on).
        "aspell.check" = "off";

        # Use the terminal's clipboard instead of xclip/xsel.
        # Works better with kitty's clipboard handling.
        clipboard = "terminal";

        # Color scheme. "simple-custom" is our tweak of the built-in "simple"
        # theme — tones down TODO/FIXME highlighting to use comment color.
        # The colorscheme file is at ~/.config/micro/colorschemes/simple-custom.micro
        colorscheme = "simple-custom";
        savecursor = true;     # Remember cursor position between sessions
        saveundo = true;       # Persist undo history across sessions

        # Auto-add trailing newline on save (POSIX convention, avoids git warnings).
        eofnewline = true;

        # Highlight search matches as you type.
        hlsearch = true;

        # Highlight tabs mixed with spaces (catches inconsistent indentation).
        hltaberrors = true;

        # Show line numbers relative to the cursor (useful for vim-style jumps).
        relativeruler = true;

        # Keep this many lines visible above/below cursor when scrolling.
        scrollmargin = 5;

        # Wrap long lines visually (no horizontal scrolling).
        softwrap = true;

        # Tab key moves between indentation levels instead of inserting a tab.
        tabmovement = true;

        # Insert spaces when pressing Tab (not a literal tab character).
        tabstospaces = true;

        # Hard-wrap text at the edge of the view when typing.
        wordwrap = true;
    };

    # --- Keybindings ---
    # Custom keybindings override micro's defaults.
    # Format: "key-combo": "action" (or "" to unbind).
    home.file.".config/micro/bindings.json".text = builtins.toJSON {

        # Toggle line/block comments (two bindings for the same action).
        "Alt-/" = "lua:comment.comment";
        "CtrlUnderscore" = "lua:comment.comment";   # Ctrl+/ on most terminals

        # Quick access to common commands.
        "Ctrl-j" = "command-edit:jump ";       # Jump to line number
        "Ctrl-r" = "command-edit:replace ";    # Find and replace
        "Ctrl-u" = "command:vsplit";           # Vertical split
        "Alt-m" = "command:mdfried";            # Markdown preview (mdfried plugin)
        "Ctrl-p" = "command:fzf";              # Fuzzy file finder (fzf plugin)
        "F1" = "command:tree";                 # File tree sidebar
        "F5" = "ToggleMacro";                 # Start/stop recording a macro
        "F9" = "PlayMacro";                   # Replay recorded macro

        # Unbind Alt+bracket keys (conflict with terminal escape sequences).
        "Alt-[" = "";
        "Alt-]" = "";
        "Alt-{" = "";
        "Alt-}" = "";

        # Navigate by paragraph (jump between blank-line-separated blocks).
        "CtrlUp" = "ParagraphPrevious";
        "CtrlDown" = "ParagraphNext";
        "CtrlShiftUp" = "SelectToParagraphPrevious";
        "CtrlShiftDown" = "SelectToParagraphNext";
    };
}
