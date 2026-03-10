# Intel RAPL / AMD powercap — make energy counters readable without root.
#
# By default, /sys/class/powercap/intel-rapl:*/energy_uj is mode 0400 root:root.
# This means tools like btop can't show CPU power draw without sudo.
#
# A small systemd oneshot runs at boot to chmod the energy_uj files to 0444.
#
# Note for Strix Halo APUs: the RAPL "package-0" counter and the amdgpu hwmon
# PPT sensor both report total SoC power (CPU + GPU + uncore). There is no
# separate CPU-only or GPU-only power counter exposed by the hardware/driver.
# btop will show similar numbers for both — that's expected, not a bug.

{ ... }:

{
    systemd.services.powercap-permissions = {
        description = "Make RAPL energy counters world-readable";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
        };
        script = ''
            for f in /sys/class/powercap/intel-rapl:*/energy_uj /sys/class/powercap/intel-rapl:*:*/energy_uj; do
                [ -f "$f" ] && chmod 0444 "$f"
            done
        '';
    };
}
