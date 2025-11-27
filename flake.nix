{
  description = "Nixos config flake";

  inputs = {
    unstable-nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
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
      inputs.quickshell.follows = "quickshell"; # Use same quickshell version
    };

    stylix.url = "github:danth/stylix";

    catppuccin.url = "github:catppuccin/nix";

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

      # Import nixpkgs with overlays and config for all systems
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          inherit unstable-nixpkgs;
          config = {
            allowUnfree = true;
            allowBroken = true; # Allow broken packages (needed for Linux packages on macOS)
          };
          overlays = [ self.overlays.default ];
        };
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
      overlays.default = final: prev: {
        pam = final.callPackage ./packages/pam { };
      };

      nixosConfigurations = {
        jayne = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
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
            ./hosts/jayne/configuration.nix
            ./modules/nixos
            inputs.home-manager.nixosModules.default
            inputs.catppuccin.nixosModules.catppuccin
            inputs.sops-nix.nixosModules.sops
          ];
        };
        kaylee = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
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
            ./hosts/kaylee/configuration.nix
            ./modules/nixos
            inputs.home-manager.nixosModules.default
            inputs.catppuccin.nixosModules.catppuccin
            inputs.sops-nix.nixosModules.sops
          ];
        };
        serenity = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
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
            ./hosts/serenity/configuration.nix
            ./modules/homelab
            inputs.home-manager.nixosModules.default
            inputs.sops-nix.nixosModules.sops
          ];
        };
        shepherd = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
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
            ./hosts/shepherd/configuration.nix
            ./modules/nixos
            inputs.home-manager.nixosModules.default
            inputs.catppuccin.nixosModules.catppuccin
            inputs.sops-nix.nixosModules.sops
          ];
        };
        shepherd-arm = nixpkgs.lib.nixosSystem rec {
          system = "aarch64-linux";
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
            ./hosts/shepherd/configuration.nix
            ./modules/nixos
            inputs.home-manager.nixosModules.default
            inputs.catppuccin.nixosModules.catppuccin
            inputs.sops-nix.nixosModules.sops
          ];
        };
      };

      darwinConfigurations = {
        inara = nix-darwin.lib.darwinSystem rec {
          system = "aarch64-darwin";
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
            ./hosts/inara/configuration.nix
            ./modules/darwin
            inputs.home-manager.darwinModules.default
            # inputs.catppuccin.nixosModules.catppuccin
          ];
        };
      };
    };
}
