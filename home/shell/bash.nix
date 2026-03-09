# Bash shell configuration.
#
# Home Manager's programs.bash module generates ~/.bashrc for us.
# We split config into:
#   - shellAliases: simple command shortcuts (HM writes these as `alias x='...'`)
#   - sessionVariables: environment variables (exported at shell start)
#   - initExtra: arbitrary bash that runs on every interactive shell start
#   - profileExtra: runs once at login (like .bash_profile)
#
# NOTE: Some things (zoxide, fzf, yazi wrapper) are raw bash and go in
# initExtra since HM doesn't have structured options for them.

{ config, pkgs, lib, ... }:

{
    programs.bash = {
        enable = true;

        # --- Aliases ---
        # HM turns each key-value pair into `alias key='value'` in .bashrc.
        # Easier to maintain than a raw alias block.
        shellAliases = {
            # Core utils
            ls = "ls --color=auto --hyperlink=auto -h --group-directories-first";
            grep = "grep --color=auto";
            mc = "micro";
            py = "python";
            pypy = "pypy3";
            ipy = "ipython";
            fman = "compgen -c | fzf | xargs man";  # fuzzy-find a man page
            fetch = ''fastfetch --data "$(pokemon-colorscripts -r)"'';
            pika = "pokemon-colorscripts";

            # Weather
            weather = "curl wttr.in/~Lancaster+UK";

            # Kitty terminal tools (these only work inside kitty)
            kssh = "kitten ssh";       # SSH with kitty terminfo propagation
            icat = "kitten icat";      # Display images in terminal
            ktrans = "kitten transfer"; # File transfer between kitty instances

            # --- NixOS rebuild shortcuts ---
            # These invoke nixos-rebuild with the gaia-nix flake.
            #   rebuild      → switch: build + activate immediately
            #   rebuild-test → test: activate without adding to boot menu
            #   rebuild-boot → boot: add to boot menu, activate on next reboot
            rebuild = "sudo nixos-rebuild switch --flake ~/Projects/gaia-nix#gaia";
            rebuild-test = "sudo nixos-rebuild test --flake ~/Projects/gaia-nix#gaia";
            rebuild-boot = "sudo nixos-rebuild boot --flake ~/Projects/gaia-nix#gaia";

            # Claude Code
            yolo = "claude --dangerously-skip-permissions";
        };

        # --- Extra bashrc content ---
        # This is raw bash appended to the end of .bashrc.
        # Used for things that don't fit HM's structured options:
        # shell integrations, functions, completions, etc.
        initExtra = ''
            # --- Interactive-only guard ---
            # If this shell isn't interactive (e.g. scp, rsync), bail early.
            # HM already adds this, but the guard is cheap insurance.
            [[ $- != *i* ]] && return

            # --- SSH agent ---
            # gnome-keyring provides the SSH agent (see keyring.nix).
            # SSH_AUTH_SOCK is set via home.sessionVariables there.
            # Keys are added silently on each shell start — ssh-add is a
            # no-op if the key is already loaded.
            [ -f ~/.ssh/keys/id_main ] && ssh-add ~/.ssh/keys/id_main &> /dev/null
            [ -f ~/.ssh/keys/id_gitlab ] && ssh-add ~/.ssh/keys/id_gitlab &> /dev/null
            [ -f ~/.ssh/keys/id_bitbucket ] && ssh-add ~/.ssh/keys/id_bitbucket &> /dev/null
            [ -f ~/.ssh/keys/id_github ] && ssh-add ~/.ssh/keys/id_github &> /dev/null

            # --- Shell integrations ---
            # zoxide: smarter cd that learns your most-used directories.
            #   Use `z foo` instead of `cd ~/some/long/path/to/foo`.
            eval "$(zoxide init bash)"

            # fzf: fuzzy finder keybindings (Ctrl-R for history, Ctrl-T for files).
            eval "$(fzf --bash)"

            # --- Prompt ---
            # Simple colored prompt: [user@host directory]$
            # \e[1;33m = bold yellow, \e[m = reset
            PS1='\e[1;33m[\u@\h \W]\$ \e[m'

            # --- Autocomplete for aliases ---
            # `mc` is our alias for micro — this gives it filename completion.
            complete -F _comp_complete_minimal mc

            # --- Helper functions ---

            # dpn: open Dolphin file manager in background, detached from terminal.
            # Without disown, closing the terminal would kill Dolphin.
            function dpn {
                dolphin "$@" &> /dev/null & disown
            }

            # ok: same pattern for Okular PDF viewer.
            function ok {
                okular "$@" &> /dev/null & disown
            }

            # y: yazi file manager with directory-changing on exit.
            # When you quit yazi, your terminal cd's to wherever you navigated.
            # Without this wrapper, yazi runs in a subprocess and your shell
            # stays in the original directory.
            function y() {
                local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
                yazi "$@" --cwd-file="$tmp"
                if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
                    builtin cd -- "$cwd"
                fi
                rm -f -- "$tmp"
            }
        '';
    };

    # --- Environment variables ---
    # HM exports these in the shell session. They're set separately from
    # shellAliases because they're `export VAR=value`, not aliases.
    home.sessionVariables = {
        EDITOR = "micro";
        VISUAL = "micro";
        TERM = "xterm-kitty";       # Tells programs we're in kitty (for color/feature support)
        LANG = "en_GB.UTF-8";
        LC_ALL = "en_GB.UTF-8";
        PAGER = "bat";               # Use bat for paging (syntax-highlighted less)
        MANPAGER = "sh -c 'col -bx | bat -p -lman'";  # Syntax-highlighted man pages
        MANROFFOPT = "-c";
        DBX_CONTAINER_HOME_PREFIX = "$HOME/Distrobox";  # Distrobox container home directory
    };

    # --- PATH additions ---
    # HM prepends these to $PATH. Order matters — earlier entries win.
    home.sessionPath = [
        "$HOME/.local/bin"               # User-installed scripts and binaries
        "$HOME/.cargo/bin"               # Rust toolchain binaries
    ];
}
