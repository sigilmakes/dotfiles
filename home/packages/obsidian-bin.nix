# Obsidian — official binary with bundled Electron.
#
# The nixpkgs `obsidian` package rewraps the app with system Electron,
# which renames the process from "obsidian" to "electron". This breaks
# Obsidian's built-in CLI feature, which checks that argv[0] == "obsidian".
#
# This package uses the upstream binary directly, patched with
# autoPatchelfHook so it finds NixOS libraries.

{ lib, stdenv, obsidian, autoPatchelfHook, makeWrapper, wrapGAppsHook3,
  alsa-lib, at-spi2-atk, cairo, cups, dbus, expat, gdk-pixbuf, glib,
  gtk3, libdrm, libX11, libXcomposite, libXdamage, libXext, libXfixes,
  libXrandr, libxcb, libxkbcommon, mesa, nspr, nss, pango,
  systemd, xdg-utils, copyDesktopItems, makeDesktopItem }:

let
    desktopItem = makeDesktopItem {
        name = "obsidian";
        desktopName = "Obsidian";
        comment = "Knowledge base";
        icon = "obsidian";
        exec = "obsidian %u";
        categories = [ "Office" ];
        mimeTypes = [ "x-scheme-handler/obsidian" ];
    };
in
stdenv.mkDerivation {
    pname = "obsidian-bin";
    inherit (obsidian) src version;

    nativeBuildInputs = [
        autoPatchelfHook
        makeWrapper
        wrapGAppsHook3
        copyDesktopItems
    ];

    buildInputs = [
        alsa-lib
        at-spi2-atk
        cairo
        cups
        dbus
        expat
        gdk-pixbuf
        glib
        gtk3
        libdrm
        libX11
        libXcomposite
        libXdamage
        libXext
        libXfixes
        libXrandr
        libxcb
        libxkbcommon
        mesa
        nspr
        nss
        pango
    ];

    runtimeDependencies = [
        systemd
    ];

    desktopItems = [ desktopItem ];

    dontBuild = true;
    dontConfigure = true;
    dontWrapGApps = true;

    installPhase = ''
        runHook preInstall

        mkdir -p $out/opt/obsidian $out/bin

        cp -r * $out/opt/obsidian/

        # Wrap with Wayland flags and gapps env
        makeWrapper $out/opt/obsidian/obsidian $out/bin/obsidian \
            "''${gappsWrapperArgs[@]}" \
            --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform=wayland --enable-wayland-ime=true --wayland-text-input-version=3}}" \
            --prefix PATH : ${lib.makeBinPath [ xdg-utils ]}

        # Install icon from the bundled resources
        for size in 16 32 48 64 128 256 512; do
            icon_dir=$out/share/icons/hicolor/''${size}x''${size}/apps
            mkdir -p $icon_dir
            if [ -f $out/opt/obsidian/resources/obsidian.png ]; then
                cp $out/opt/obsidian/resources/obsidian.png $icon_dir/obsidian.png
            fi
        done

        runHook postInstall
    '';

    meta = {
        description = "Powerful knowledge base that works on top of a local folder of plain text Markdown files";
        homepage = "https://obsidian.md";
        license = lib.licenses.unfree;
        mainProgram = "obsidian";
        platforms = [ "x86_64-linux" ];
    };
}
