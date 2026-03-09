# qt6ct-kde overlay — patches qt6ct to read KDE color scheme (.colors) files
# and write to kdeglobals. This makes KDE apps (Dolphin, etc.) respect qt6ct
# colour schemes set by caelestia.
#
# Based on: https://aur.archlinux.org/packages/qt6ct-kde

final: prev: {
    qt6ct-kde = prev.kdePackages.qt6ct.overrideAttrs (old: {
        pname = "qt6ct-kde";

        buildInputs = (old.buildInputs or []) ++ (with prev.kdePackages; [
            kconfig
            kcolorscheme
            kiconthemes
            qqc2-desktop-style
        ]);

        patches = (old.patches or []) ++ [
            ./qt6ct-kde-shenanigans.patch
        ];
    });
}
