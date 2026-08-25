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

    quickshell = {
      url = "github:outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mangowm = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Wallpaper selector + its daemon. Owns picking; noctalia applies and themes.
    skwd-wall = {
      url = "github:liixini/skwd-wall";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.quickshell.inputs.nixpkgs.follows = "nixpkgs";
      inputs.skwd-daemon.inputs.nixpkgs.follows = "nixpkgs";
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

    # catppuccin = {
    #   url = "github:catppuccin/nix"; # Main branch for unstable nixpkgs compatibility
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nixCats-style neovim wrapper (lua config stays native, nix provides binaries/plugins)
    nix-wrapper-modules = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Lazy-loader + helpers. Auto-picked up by pluginsFromPrefix "plugins-".
    plugins-lze = {
      url = "github:BirdeeHub/lze";
      flake = false;
    };
    plugins-lzextras = {
      url = "github:BirdeeHub/lzextras";
      flake = false;
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

    # Herdr: mouse-first terminal multiplexer (tmux/zellij alternative).
    #
    # Pinned. ffc4e26 (2026-08-18) broke keyboard input to TUI applications
    # running inside herdr -- ghostty on its own is unaffected, so it is herdr's
    # terminal layer, not the emulator. 29 commits land between this rev and
    # that one, several touching terminal input; "fix(perf): eliminate
    # redundant terminal wake work" (#2962) is the most likely culprit.
    # Unpin once that is confirmed fixed upstream.
    herdr = {
      url = "github:ogulcancelik/herdr/51b7064ef0a02642393bab1d2eea0f4dbd8414d2";
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

    # Doom Emacs built declaratively (no straight.el, no `doom sync`).
    # Don't `follows` nixpkgs: the module uses its own pinned emacs-overlay,
    # and upstream warns against updating its inputs. follows="" just avoids
    # downloading a second nixpkgs (the module reads pkgs from our config).
    nix-doom-emacs-unstraightened = {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      inputs.nixpkgs.follows = "";
    };

    # peon-ping: agent sound notifications
    peon-ping.url = "github:PeonPing/peon-ping";

    # WannaShare: PocketBase backend + Nuxt SSR site NixOS module
    wannashare.url = "git+https://git.victorbuch.com/Smoothless/WannaShare.git";

    # tv-learn: immersion language-learning media app (learn.victorbuch.com)
    tv-learn = {
      url = "git+https://git.victorbuch.com/VictorBuch/tv-learn";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nocturne: plain-text notes + tasks + agenda (Tauri desktop app).
    nocturne = {
      url = "git+https://git.victorbuch.com/VictorBuch/Nocturne";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hermes Agent (self-hosted personal AI agent) — ships its own nixosModule.
    # Deliberately NOT following our nixpkgs: the package is built with uv2nix
    # against its own pinned nixpkgs, and overriding it breaks the sealed venv
    # (and any upstream binary cache hits).
    hermes-agent.url = "github:NousResearch/hermes-agent";

    # Auto-import module directories (replaces manual import lists)
    import-tree = {
      url = "github:vic/import-tree";
      flake = false;
    };

    # Obsidian community-plugin release assets (see
    # modules/apps/productivity/obsidian.nix). Pinned to each plugin's *latest*
    # GitHub release via the stable `releases/latest/download/<asset>` URLs, so
    # `nix flake update` bumps every plugin — the hashes live in flake.lock, not
    # in the module. `type = "file"` keeps each asset a raw file (no unpacking);
    # `flake = false` because they're plain assets, not flakes.
    obsidian-tasks-main = { type = "file"; flake = false; url = "https://github.com/obsidian-tasks-group/obsidian-tasks/releases/latest/download/main.js"; };
    obsidian-tasks-manifest = { type = "file"; flake = false; url = "https://github.com/obsidian-tasks-group/obsidian-tasks/releases/latest/download/manifest.json"; };
    obsidian-tasks-styles = { type = "file"; flake = false; url = "https://github.com/obsidian-tasks-group/obsidian-tasks/releases/latest/download/styles.css"; };

    obsidian-task-genius-main = { type = "file"; flake = false; url = "https://github.com/taskgenius/taskgenius-plugin/releases/latest/download/main.js"; };
    obsidian-task-genius-manifest = { type = "file"; flake = false; url = "https://github.com/taskgenius/taskgenius-plugin/releases/latest/download/manifest.json"; };
    obsidian-task-genius-styles = { type = "file"; flake = false; url = "https://github.com/taskgenius/taskgenius-plugin/releases/latest/download/styles.css"; };

    obsidian-omnisearch-main = { type = "file"; flake = false; url = "https://github.com/scambier/obsidian-omnisearch/releases/latest/download/main.js"; };
    obsidian-omnisearch-manifest = { type = "file"; flake = false; url = "https://github.com/scambier/obsidian-omnisearch/releases/latest/download/manifest.json"; };
    obsidian-omnisearch-styles = { type = "file"; flake = false; url = "https://github.com/scambier/obsidian-omnisearch/releases/latest/download/styles.css"; };

    obsidian-templater-main = { type = "file"; flake = false; url = "https://github.com/SilentVoid13/Templater/releases/latest/download/main.js"; };
    obsidian-templater-manifest = { type = "file"; flake = false; url = "https://github.com/SilentVoid13/Templater/releases/latest/download/manifest.json"; };
    obsidian-templater-styles = { type = "file"; flake = false; url = "https://github.com/SilentVoid13/Templater/releases/latest/download/styles.css"; };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      nix-darwin,
      ...
    }@inputs:
    let
      # Custom library functions
      customLib = import ./lib { inherit (nixpkgs) lib; };

      # Auto-import module directories (replaces manual import lists)
      import-tree = import inputs.import-tree;

      # Import the overlay with inputs
      overlayWithInputs = import ./overlays { inherit inputs; };

      # Primary pkgs - unstable for all hosts (dev tools, latest packages)
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            allowBroken = true; # Allow broken packages (needed for Linux packages on macOS)
            android_sdk.accept_license = true;
          };
          overlays = [ overlayWithInputs ];
        };

      # Stable pkgs - escape hatch for packages that need stability (audio/wine)
      # Instantiated once here, passed via specialArgs - avoids "1000 instances of nixpkgs" problem
      stablePkgsFor =
        system:
        import nixpkgs-stable {
          inherit system;
          config = {
            allowUnfree = true;
            allowBroken = true;
          };
        };

      # Host definitions with their specific configurations
      # All hosts now use unstable nixpkgs as base, with pkgs-stable available as escape hatch
      nixosHosts = [
        {
          name = "jayne";
          extraModules = [ (import-tree ./modules/nixos) ];
        }
        {
          name = "kaylee";
          extraModules = [ (import-tree ./modules/nixos) ];
        }
        {
          name = "mal";
          # Homelab server: uses homelab modules instead of desktop modules
          extraModules = [
            (import-tree ./modules/homelab)
            ./modules/homelab/_config.nix
            ./modules/nixos/system/user.nix
            inputs.wannashare.nixosModules.default
            inputs.hermes-agent.nixosModules.default
            inputs.tv-learn.nixosModules.tv-learn
          ];
        }
        {
          name = "wash";
          # Public VPS running Pangolin: no desktop, no homelab modules
          extraModules = [
            ./modules/nixos/system/user.nix
            inputs.disko.nixosModules.disko
          ];
        }
        {
          name = "shepherd";
          extraModules = [
            (import-tree ./modules/nixos)
            inputs.disko.nixosModules.disko
          ];
        }
        {
          name = "shepherd-arm";
          system = "aarch64-linux";
          hostConfig = ./hosts/shepherd/configuration.nix;
          extraModules = [
            (import-tree ./modules/nixos)
            inputs.disko.nixosModules.disko
          ];
        }
      ];

      darwinHosts = [
        {
          name = "inara";
          system = "aarch64-darwin";
        }
      ];

      # Export custom packages for all systems
      packages = builtins.listToAttrs (
        map
          (system: {
            name = system;
            value = import ./packages {
              pkgs = pkgsFor system;
            };
          })
          [
            "x86_64-linux"
            "aarch64-linux"
            "x86_64-darwin"
            "aarch64-darwin"
          ]
      );

    in
    {
      # Export packages
      inherit packages;

      # Export overlay
      overlays.default = overlayWithInputs;

      nixosConfigurations = builtins.listToAttrs (
        map (host: {
          inherit (host) name;
          value =
            let
              system = host.system or "x86_64-linux"; # Default to x86_64-linux
            in
            nixpkgs.lib.nixosSystem {
              inherit system;
              pkgs = pkgsFor system;
              specialArgs = {
                inherit inputs system;
                inherit (customLib) mkModule expiring;
                pkgs = pkgsFor system;
                pkgs-stable = stablePkgsFor system;
              };
              modules = [
                # Common modules (auto-discovered)
                (import-tree ./modules/common)
                ./modules/common/_defaults.nix
                # App modules (auto-discovered)
                (import-tree ./modules/apps)
                ./modules/apps/_categories.nix
                # Host-specific configuration
                (host.hostConfig or ./hosts/${host.name}/configuration.nix)
                # Standard modules for all NixOS hosts
                inputs.home-manager.nixosModules.default
                inputs.sops-nix.nixosModules.sops
                { home-manager.useGlobalPkgs = true; }
              ]
              ++ (host.extraModules or [ ]);
            };
        }) nixosHosts
      );

      darwinConfigurations = builtins.listToAttrs (
        map (host: {
          inherit (host) name;
          value = nix-darwin.lib.darwinSystem (
            let
              system = host.system; # Darwin hosts must specify system
            in
            {
              inherit system;
              pkgs = pkgsFor system;
              specialArgs = {
                inherit inputs system;
                inherit (customLib) mkModule expiring;
                pkgs = pkgsFor system;
                pkgs-stable = stablePkgsFor system;
              };
              modules = [
                # Common modules (auto-discovered)
                (import-tree ./modules/common)
                ./modules/common/_defaults.nix
                # App modules (auto-discovered)
                (import-tree ./modules/apps)
                ./modules/apps/_categories.nix
                # Host-specific configuration
                (host.hostConfig or ./hosts/${host.name}/configuration.nix)
                # Darwin-specific modules
                (import-tree ./modules/darwin)
                inputs.home-manager.darwinModules.default
                inputs.sops-nix.darwinModules.sops
                { home-manager.useGlobalPkgs = true; }
              ]
              ++ (host.extraModules or [ ]);
            }
          );
        }) darwinHosts
      );
    };
}
