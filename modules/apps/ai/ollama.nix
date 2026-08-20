args@{ config, pkgs, lib, mkModule, ... }:

let
  # Pick the acceleration backend from the GPU the host already declares.
  # amd-gpu lives in modules/nixos/, so it's absent on mal (homelab modules) and Darwin.
  hasAmdGpu = config.amd-gpu.enable or false;

  ollamaPkg =
    if pkgs.stdenv.hostPlatform.isDarwin then pkgs.ollama
    else if hasAmdGpu then pkgs.ollama-rocm
    else pkgs.ollama;
in

mkModule {
  name = "ollama";
  category = "ai";
  description = "Local llm";

  linuxPackages = { ... }: [ ollamaPkg ];
  darwinPackages = { ... }: [ ollamaPkg ];

  linuxExtraConfig = {
    services.ollama = {
      enable = lib.mkDefault true;
      package = lib.mkDefault ollamaPkg;

      # qwen3:14b (~9.3GB at Q4_K_M) is the default because adversarial review is a
      # reasoning task, not a completion task -- thinking mode beats a FIM-tuned coder.
      # On a 16GB card it leaves ~5GB for KV cache, so long diffs fit without spilling.
      # Alternatives: "gpt-oss:20b" (~13GB, MoE, 128k ctx, more capable but tight on VRAM)
      #               "qwen3-coder:30b" (~18GB Q4, partial CPU offload, 3B active params)
      loadModels = lib.mkDefault [ "qwen3:14b" ];

      environmentVariables = {
        OLLAMA_FLASH_ATTENTION = "1";
        OLLAMA_KV_CACHE_TYPE = "q8_0"; # halves KV cache VRAM
        OLLAMA_CONTEXT_LENGTH = "32768";
        OLLAMA_KEEP_ALIVE = "10m"; # release VRAM when idle instead of squatting on it
      };
    };
  };
} args
