# Ollama — local LLM inference server with ROCm acceleration
#
# Runs Ollama as a systemd service, listening on localhost:11434.
# Uses ROCm for GPU-accelerated inference on the Strix Halo's
# integrated Radeon 8060S (gfx1151).
#
# The NixOS Ollama module bundles its own ROCm libraries — it doesn't
# need the system-wide ROCm from rocm.nix. They're independent.
#
# Usage:
#   ollama run llama3.3          — pull + run a model interactively
#   ollama pull qwen3:32b        — download a model
#   ollama list                  — show downloaded models
#   ollama ps                    — show running models + GPU layers
#
# API:
#   curl http://localhost:11434/api/tags    — list models via REST
#
# Models are stored in /var/lib/ollama/models (managed by the service).

{ config, pkgs, lib, ... }:

{
    services.ollama = {
        enable = true;

        # ROCm acceleration for the AMD iGPU.
        # nixpkgs provides separate Ollama packages per accelerator.
        # rocmOverrideGfx tells the ROCm runtime to treat the Strix Halo's
        # gfx1151 GPU as the specified target.
        package = pkgs.ollama-rocm;
        rocmOverrideGfx = "11.5.1";

        # Only listen on localhost — no remote access.
        host = "127.0.0.1";
        port = 11434;
    };
}
