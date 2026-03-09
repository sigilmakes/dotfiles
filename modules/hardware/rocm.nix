# ROCm — AMD GPU compute stack for ML/AI workloads
#
# This module wires in the nix-strix-halo flake which provides:
#   - Pre-built ROCm 7 (TheRock nightlies) for gfx1151
#   - llama.cpp compiled with ROCm + rocWMMA for fast flash attention
#
# The ROCm stack coexists with Vulkan — they use different userspace libs
# but share the same amdgpu kernel driver. Vulkan is for games and lightweight
# compute; ROCm is for PyTorch, llama.cpp (fast pp), ComfyUI, etc.
#
# Usage:
#   llamacpp-rocm-gfx1151-rocwmma  — llama.cpp with ROCm + rocWMMA (fastest pp)
#   llamacpp-rocm-gfx1151          — llama.cpp with ROCm (no rocWMMA)
#
# For best LLM performance:
#   ROCBLAS_USE_HIPBLASLT=1 llamacpp-rocm-gfx1151-rocwmma \
#     --mmap 0 --ngl 99 -m model.gguf
#
# Reference: https://strixhalo.wiki/AI/llamacpp-with-ROCm

{ config, pkgs, lib, inputs, ... }:

{
    # Apply the nix-strix-halo overlay so its packages are available
    nixpkgs.overlays = [ inputs.nix-strix-halo.overlays.default ];

    # Install the ROCm-accelerated llama.cpp builds
    environment.systemPackages = [
        # llama.cpp with ROCm + rocWMMA — fastest for Strix Halo
        # rocWMMA gives ~2x prefill speed vs Vulkan
        pkgs.llamacpp-rocm.gfx1151-rocwmma

        # Plain ROCm build as fallback
        pkgs.llamacpp-rocm.gfx1151

        # ROCm SMI — GPU monitoring library + CLI.
        # btop dynamically loads librocm_smi64.so for AMD GPU stats.
        pkgs.rocmPackages.rocm-smi
    ];

    # btop hardcodes /opt/rocm/lib/librocm_smi64.so for AMD GPU monitoring.
    # Create the expected path as a symlink to the nix store.
    systemd.tmpfiles.rules = [
        "L+ /opt/rocm/lib - - - - ${pkgs.rocmPackages.rocm-smi}/lib"
    ];
}
