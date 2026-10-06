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

    nixvim = {
      url = "github:nix-community/nixvim";
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

    # peon-ping: agent sound notifications
    peon-ping.url = "github:PeonPing/peon-ping";

    # WannaShare: PocketBase backend + Nuxt SSR site NixOS module
    wannashare.url = "git+https://git.victorbuch.com/Smoothless/WannaShare.git";

    # tv-learn: immersion language-learning media app (learn.victorbuch.com)
    tv-learn = {
      url = "git+https://git.victorbuch.com/VictorBuch/tv-learn";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # edit360: Insta360 360° reframing editor (local checkout, no remote yet)
    edit360 = {
      url = "git+file:///home/jayne/Documents/github/edit-360";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
    obsidian-tasks-main = {
      type = "file";
      flake = false;
      url = "https://github.com/obsidian-tasks-group/obsidian-tasks/releases/latest/download/main.js";
    };
    obsidian-tasks-manifest = {
      type = "file";
      flake = false;
      url = "https://github.com/obsidian-tasks-group/obsidian-tasks/releases/latest/download/manifest.json";
    };
    obsidian-tasks-styles = {
      type = "file";
      flake = false;
      url = "https://github.com/obsidian-tasks-group/obsidian-tasks/releases/latest/download/styles.css";
    };

    obsidian-task-genius-main = {
      type = "file";
      flake = false;
      url = "https://github.com/taskgenius/taskgenius-plugin/releases/latest/download/main.js";
    };
    obsidian-task-genius-manifest = {
      type = "file";
      flake = false;
      url = "https://github.com/taskgenius/taskgenius-plugin/releases/latest/download/manifest.json";
    };
    obsidian-task-genius-styles = {
      type = "file";
      flake = false;
      url = "https://github.com/taskgenius/taskgenius-plugin/releases/latest/download/styles.css";
    };

    obsidian-omnisearch-main = {
      type = "file";
      flake = false;
      url = "https://github.com/scambier/obsidian-omnisearch/releases/latest/download/main.js";
    };
    obsidian-omnisearch-manifest = {
      type = "file";
      flake = false;
      url = "https://github.com/scambier/obsidian-omnisearch/releases/latest/download/manifest.json";
    };
    obsidian-omnisearch-styles = {
      type = "file";
      flake = false;
      url = "https://github.com/scambier/obsidian-omnisearch/releases/latest/download/styles.css";
    };

    obsidian-templater-main = {
      type = "file";
      flake = false;
      url = "https://github.com/SilentVoid13/Templater/releases/latest/download/main.js";
    };
    obsidian-templater-manifest = {
      type = "file";
      flake = false;
      url = "https://github.com/SilentVoid13/Templater/releases/latest/download/manifest.json";
    };
    obsidian-templater-styles = {
      type = "file";
      flake = false;
      url = "https://github.com/SilentVoid13/Templater/releases/latest/download/styles.css";
    };
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

      # One builder for every host. `class` picks the platform: the system
      # builder, the module tree, and the home-manager and sops variants.
      mkHost =
        {
          name,
          class ? "nixos",
          system ? if class == "darwin" then "aarch64-darwin" else "x86_64-linux",
          hostConfig ? ./hosts/${name}/configuration.nix,
          # Servers set this false and name the modules they want instead.
          platformModules ? true,
          extraModules ? [ ],
        }:
        let
          darwin = class == "darwin";
          builder = if darwin then nix-darwin.lib.darwinSystem else nixpkgs.lib.nixosSystem;
          platformTree =
            if darwin then
              [ (import-tree ./modules/darwin) ]
            else
              nixpkgs.lib.optional platformModules (import-tree ./modules/nixos);
        in
        builder {
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
            hostConfig
            (
              if darwin then
                inputs.home-manager.darwinModules.default
              else
                inputs.home-manager.nixosModules.default
            )
            (if darwin then inputs.sops-nix.darwinModules.sops else inputs.sops-nix.nixosModules.sops)
          ]
          ++ platformTree
          ++ extraModules;
        };

      # Host definitions. Unstable nixpkgs is the base everywhere, with
      # pkgs-stable as the escape hatch.
      hosts = [
        { name = "jayne"; }
        { name = "kaylee"; }
        {
          name = "mal";
          # Homelab server: homelab modules instead of the desktop tree.
          platformModules = false;
          extraModules = [
            (import-tree ./modules/homelab)
            ./modules/homelab/_config.nix
            ./modules/nixos/system/user.nix
            inputs.wannashare.nixosModules.default
            inputs.tv-learn.nixosModules.tv-learn
          ];
        }
        {
          name = "wash";
          # Public VPS running Pangolin: homelab facts only, no desktop tree.
          platformModules = false;
          extraModules = [
            ./modules/homelab/_config.nix
            ./modules/nixos/system/user.nix
            inputs.disko.nixosModules.disko
          ];
        }
        {
          name = "shepherd";
          extraModules = [ inputs.disko.nixosModules.disko ];
        }
        {
          name = "shepherd-arm";
          system = "aarch64-linux";
          hostConfig = ./hosts/shepherd/configuration.nix;
          extraModules = [ inputs.disko.nixosModules.disko ];
        }
        {
          name = "inara";
          class = "darwin";
        }
      ];

      hostsOfClass =
        class:
        builtins.listToAttrs (
          map (host: {
            inherit (host) name;
            value = mkHost host;
          }) (builtins.filter (host: (host.class or "nixos") == class) hosts)
        );

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

      # Evaluating mal's system forces its assertions, among them the Service
      # Record and Port Reservation invariants (modules/homelab/records.nix).
      # Only the eval runs; the system itself is not built.
      checks.x86_64-linux.mal-records = (pkgsFor "x86_64-linux").writeText "mal-records" (
        builtins.unsafeDiscardStringContext self.nixosConfigurations.mal.config.system.build.toplevel.drvPath
      );

      checks.x86_64-linux.shell-actions =
        self.nixosConfigurations.jayne.config.home-manager.users.jayne.home.desktop.shell.check;

      nixosConfigurations = hostsOfClass "nixos";
      darwinConfigurations = hostsOfClass "darwin";
    };
}
