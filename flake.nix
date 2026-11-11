{
  description = "Nixos config flake";

  inputs = {
    # Primary nixpkgs - unstable for all hosts (dev tools, latest packages)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Stable nixpkgs - escape hatch for packages that need stability (audio/wine)
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; # Matches our unstable base - no more version mismatch
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin"; # Master branch tracks unstable
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    silentSDDM = {
      url = "github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia-templates = {
      url = "github:noctalia-dev/community-templates";
      flake = false;
    };

    mangowm = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Wallpaper packs, merged into the pool by home/wallpaper-pool.nix.
    wallpapers-nord = {
      url = "github:ChrisTitusTech/nord-background";
      flake = false;
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    herdr = {
      url = "github:ogulcancelik/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative disk partitioning (used for nixos-anywhere onboarding)
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pinned nixpkgs for Wine 9.20 (audio/yabridge compatibility)
    # Wine 9.22+ has GUI issues: https://github.com/robbert-vdh/yabridge/issues/382
    nixpkgs-wine920.url = "github:nixos/nixpkgs/c792c60b8a97daa7efe41a6e4954497ae410e0c1";

    # Pinned nixpkgs for DaVinci Resolve Studio 21.0.3 (see overlays/default.nix).
    # The byte patches there target one exact build, so this input must be bumped
    # deliberately (and the patches re-verified), never by `nix flake update`.
    # 21.0.4 already breaks the invert-einval-guard patch.
    nixpkgs-resolve.url = "github:nixos/nixpkgs/0954f7ee2f6bb3dc7d4e3d0d8bcb8fd4bde4cfc5";

    # Realtime audio tuning (threadirqs, IRQ priorities, rlimits).
    # Used by modules/nixos/system/audio-performance.nix WITHOUT its realtime kernel --
    # the stock kernel plus threadirqs is enough for REAPER at a 128-frame quantum.
    musnix = {
      url = "github:musnix/musnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # AI coding agents (claude-code, etc.)
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # WannaShare: PocketBase backend + Nuxt SSR site NixOS module
    wannashare.url = "git+https://git.victorbuch.com/Smoothless/WannaShare.git";

    sparkyfitness = {
      url = "github:CodeWithCJ/SparkyFitness";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # tv-learn: immersion language-learning media app (learn.victorbuch.com)
    tv-learn = {
      url = "git+https://git.victorbuch.com/VictorBuch/tv-learn";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # edit360: Insta360 360° reframing editor (local checkout, no remote yet)
    edit360 = {
      url = "git+file:///home/jayne/Documents/github/edit-360?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # Auto-import module directories (replaces manual import lists)
    import-tree.url = "github:denful/import-tree";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      inputs.import-tree [
        ./modules/flake
        ./modules/apps
        ./modules/nixos
      ]
    );
}
