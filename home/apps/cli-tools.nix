# CLI tools — general-purpose command line utilities.
#
# These are tools referenced by shell aliases, scripts, or keybindings
# that don't warrant their own module. Grouped here to keep home/default.nix
# clean and to make dependencies explicit.

{ config, pkgs, lib, ... }:

{
    home.packages = with pkgs; [
        # --- System monitoring ---
        fastfetch                  # System info fetch (alias: fetch)
        (btop.override { rocmSupport = true; })  # TUI process monitor with AMD GPU monitoring

        # --- Shell tools ---
        bat                        # Cat with syntax highlighting (PAGER=bat)
        zoxide                     # Smarter cd (eval "$(zoxide init bash)")
        ripgrep                    # Fast grep alternative (rg)
        fd                         # Fast find alternative
        pokemon-colorscripts       # Pokemon ASCII art (used in fetch alias)

        # --- Media ---
        mpv                        # Video/audio player
        yt-dlp                     # YouTube downloader

        # --- Documents ---
        pandoc                     # Universal document converter (markdown → PDF, etc.)
        texliveSmall               # LaTeX distribution (autotex, pandoc PDF output)

        # --- Utilities ---
        sshfs                      # Mount remote filesystems over SSH
        ripdrag                    # Drag files from terminal (rip script, yazi keymap)
        figlet                     # ASCII art text banners (autotex)
        distrobox                  # Container manager (dbox script)
        groff                      # Document formatter (autotex: blank PDF generation)
    ];

    # --- btop config ---
    # Uses TTY color theme with transparent background so terminal colors
    # show through. Braille graph symbols, proc tree view by default.
    xdg.configFile."btop/btop.conf".source = ./btop/btop.conf;
}
