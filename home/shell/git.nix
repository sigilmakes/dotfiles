# Git + GitHub CLI configuration.
#
# Home Manager's programs.git module generates ~/.gitconfig declaratively.
# This means git config is reproducible across machines — no manual
# `git config --global` needed.
#
# PER-USER: user.name and user.email are set from the `userConfig` attrset
# passed down from flake.nix via home/default.nix. This way each user on
# the system gets their own identity without duplicating the rest of the
# git config. See home/default.nix for the curried function signature.
#
# Git LFS is enabled for large file support (wallpapers in this repo use it).
#
# GitHub CLI (gh) is installed with SSH protocol configured. Auth tokens
# are NOT managed here — run `gh auth login` after first boot.

{ config, pkgs, lib, ... }:

{
    # --- Git ---
    programs.git = {
        enable = true;

        # Per-user identity + config — pulled from userConfig in home/default.nix
        settings = {
            user = {
                name = config.home.git.userName;
                email = config.home.git.userEmail;
            };

            init.defaultBranch = "main";

            # Git LFS — required for repos with large tracked files
            filter.lfs = {
                clean = "git-lfs clean -- %f";
                smudge = "git-lfs smudge -- %f";
                process = "git-lfs filter-process";
                required = true;
            };

            # Aliases
            alias = {
                tree = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' --all";
            };
        };

        # Git LFS package
        lfs.enable = true;
    };

    # --- GitHub CLI ---
    programs.gh = {
        enable = true;

        settings = {
            git_protocol = "ssh";
            prompt = "enabled";

            aliases = {
                co = "pr checkout";
            };
        };
    };
}
