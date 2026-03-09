# AMD GPU configuration — Strix Halo (Radeon 8060S, RDNA 3.5, gfx1151)
#
# The Strix Halo APU shares system memory between CPU and GPU (unified memory).
# With 128GB LPDDR5X-8000 on a 256-bit bus, it has ~256GB/s bandwidth and can
# allocate up to ~120GB as VRAM for LLM inference or GPU compute.
#
# Driver stack:
#   - Mesa RADV: Vulkan driver (default, reliable, good performance)
#   - radeonsi: OpenGL driver (via Mesa)
#   - VA-API: hardware video decode/encode
#
# AMDVLK has been removed from nixpkgs (deprecated by AMD in favor of RADV).
# RADV is the sole Vulkan driver now and works well for both gaming and compute.
#
# ROCm (for ML/AI compute) is handled separately via the nix-strix-halo flake
# input — it provides pre-built TheRock ROCm nightlies for gfx1151.
#
# Reference: https://strixhalo.wiki/AI/AI_Capabilities_Overview

{ config, pkgs, lib, ... }:

{
    # Load the amdgpu kernel driver early in boot.
    # This ensures the GPU is initialised before the display manager starts.
    boot.initrd.kernelModules = [ "amdgpu" ];

    # --- Kernel parameters for Strix Halo ---
    boot.kernelParams = [
        # Disable IOMMU for ~6% faster memory reads. Only safe if you're NOT
        # using GPU passthrough (VFIO). For a desktop gaming/AI machine this
        # is a free performance win.
        "amd_iommu=off"
    ];

    # --- GTT memory limits ---
    # Strix Halo's GPU uses GTT (Graphics Translation Table) to dynamically
    # allocate system memory as VRAM. By default this is limited — we raise
    # it to 120GB so large LLM models can be fully GPU-resident.
    #
    # pages_limit: max 4KB pages for GPU memory (31457280 * 4KB = 120GB)
    # gttsize: legacy param, set to match for compat with older software
    boot.extraModprobeConfig = ''
        # GTT: allow GPU to use up to 120GB of system memory
        options ttm pages_limit=31457280
        # Legacy compat (deprecated but some tools still read it)
        options amdgpu gttsize=122800
    '';

    # --- Graphics stack ---
    hardware.graphics = {
        enable = true;

        extraPackages = with pkgs; [
            # Mesa — OpenGL (radeonsi) + Vulkan (RADV) drivers
            mesa

            # Vulkan userspace
            vulkan-loader   # ICD loader — routes Vulkan calls to the right driver
            vulkan-tools    # vulkaninfo diagnostic

            # VA-API — hardware video decode/encode (Firefox, mpv, OBS)
            libva
            libva-utils     # vainfo diagnostic
        ];
    };

    # Tell VA-API to use the radeonsi backend
    environment.variables = {
        LIBVA_DRIVER_NAME = "radeonsi";
    };

    # --- Diagnostic commands ---
    # After rebuilding, verify everything works:
    #
    #   vulkaninfo --summary          — should show RADV
    #   vainfo                        — should show radeonsi with codec support
    #   glxinfo | grep OpenGL         — should show AMD / radeonsi
    #   cat /sys/class/drm/card*/device/mem_info_gtt_total  — GTT limit
}
