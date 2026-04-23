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
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # catppuccin = {
    #   url = "github:catppuccin/nix"; # Main branch for unstable nixpkgs compatibility
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    nvf = {
      url = "github:NotAShelf/nvf";
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

    # Declarative disk partitioning (used for nixos-anywhere onboarding)
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pinned nixpkgs for Wine 9.20 (audio/yabridge compatibility)
    # Wine 9.22+ has GUI issues: https://github.com/robbert-vdh/yabridge/issues/382
    nixpkgs-wine920.url = "github:nixos/nixpkgs/c792c60b8a97daa7efe41a6e4954497ae410e0c1";

    # AI coding agents (claude-code, etc.)
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # peon-ping: agent sound notifications
    peon-ping.url = "github:PeonPing/peon-ping";

    # WannaShare: PocketBase backend + Nuxt SSR site NixOS module
    wannashare.url = "git+https://git.victorbuch.com/Smoothless/WannaShare.git";

    # Auto-import module directories (replaces manual import lists)
    import-tree = {
      url = "github:vic/import-tree";
      flake = false;
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
                inherit (customLib) mkModule;
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
                inherit (customLib) mkModule;
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
