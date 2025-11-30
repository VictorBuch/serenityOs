{
  description = "Nixos config flake";

  inputs = {
    unstable-nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "unstable-nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    quickshell = {
      url = "github:outfoxxed/quickshell";
      inputs.nixpkgs.follows = "unstable-nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "unstable-nixpkgs";
    };

    stylix.url = "github:danth/stylix";

    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "unstable-nixpkgs";
    };

    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "unstable-nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "unstable-nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "unstable-nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      unstable-nixpkgs,
      nix-darwin,
      ...
    }@inputs:
    let
      # Custom library functions
      customLib = import ./lib { inherit (nixpkgs) lib; };

      # Import the overlay with inputs
      overlayWithInputs = import ./overlays { inherit inputs; };

      # Import nixpkgs with overlays and config for all systems
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            allowBroken = true; # Allow broken packages (needed for Linux packages on macOS)
          };
          overlays = [ overlayWithInputs ];
        };

      # Host definitions with their specific configurations
      nixosHosts = [
        {
          name = "jayne";
          # system defaults to x86_64-linux
          extraModules = [
            ./modules/nixos
            inputs.catppuccin.nixosModules.catppuccin
          ];
        }
        {
          name = "kaylee";
          # system defaults to x86_64-linux
          extraModules = [
            ./modules/nixos
            inputs.catppuccin.nixosModules.catppuccin
          ];
        }
        {
          name = "serenity";
          # system defaults to x86_64-linux
          # Serenity is a homelab server with different modules
          extraModules = [
            ./modules/homelab
          ];
        }
        {
          name = "shepherd";
          # system defaults to x86_64-linux
          extraModules = [
            ./modules/nixos
            inputs.catppuccin.nixosModules.catppuccin
          ];
        }
        {
          name = "shepherd-arm";
          system = "aarch64-linux"; # Override default system
          hostConfig = "./hosts/shepherd/configuration.nix"; # Uses shepherd's config
          extraModules = [
            ./modules/nixos
            inputs.catppuccin.nixosModules.catppuccin
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
              pkgs = pkgsFor system; # Now has unstable available via pkgs.unstable
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
          value = nixpkgs.lib.nixosSystem (
            let
              system = host.system or "x86_64-linux"; # Default to x86_64-linux
            in
            {
              inherit system;
              pkgs = pkgsFor system;
              specialArgs = {
                inherit inputs system;
                inherit (customLib)
                  mkApp
                  mkCategory
                  mkHomeModule
                  mkHomeCategory
                  ;
                isLinux = true;
              };
              modules = [
                # Host-specific configuration
                (host.hostConfig or ./hosts/${host.name}/configuration.nix)
                # Standard modules for all NixOS hosts
                inputs.home-manager.nixosModules.default
                inputs.sops-nix.nixosModules.sops
                { home-manager.useGlobalPkgs = true; }
              ]
              ++ (host.extraModules or [ ]);
            }
          );
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
              pkgs = pkgsFor system; # Use universal pkgsFor with overlay
              specialArgs = {
                inherit inputs system;
                inherit (customLib)
                  mkApp
                  mkCategory
                  mkHomeModule
                  mkHomeCategory
                  ;
                isLinux = false;
              };
              modules = [
                # Host-specific configuration
                (host.hostConfig or ./hosts/${host.name}/configuration.nix)
                # Standard modules for all Darwin hosts
                ./modules/darwin
                inputs.home-manager.darwinModules.default
                { home-manager.useGlobalPkgs = true; }
              ]
              ++ (host.extraModules or [ ]);
            }
          );
        }) darwinHosts
      );
    };
}
