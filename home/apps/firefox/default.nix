# Firefox web browser with Sidebery tree-style tabs.
#
# Home Manager's programs.firefox.profiles creates a profile with a
# deterministic name ("default" → directory "default") rather than
# Firefox's random "xxxxxxxx.default-release" naming. This lets us
# deploy userChrome.css declaratively.
#
# Extensions are NOT managed here — they sync via Firefox Account.
# Only the userChrome.css (which Firefox Sync doesn't handle) and
# the about:config pref to enable it are declared.
#
# On first login:
#   1. Sign into Firefox Account (syncs extensions, bookmarks, etc.)
#   2. Sidebery will sync from your account
#   3. userChrome.css is already in place — just works

{ config, pkgs, lib, ... }:

{
    programs.firefox = {
        enable = true;

        # Create a managed profile with our userChrome.css.
        # The profile directory will be ~/.mozilla/firefox/default
        # (deterministic, not random).
        profiles.default = {
            # Make this the default profile Firefox opens with
            isDefault = true;

            # Enable userChrome.css loading (off by default since FF 69)
            settings = {
                "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            };

            # Deploy the userChrome.css for Sidebery tree-style tabs.
            # Hides the native tab bar and titlebar since Sidebery
            # handles all tab management in the sidebar.
            userChrome = builtins.readFile ./userChrome.css;
        };
    };
}
