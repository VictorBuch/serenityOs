{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    stable-nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

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
      stable-nixpkgs,
      nix-darwin,
      ...
    }@inputs:
    let
      # Custom library functions
      customLib = import ./lib { lib = nixpkgs.lib; };

      # Import nixpkgs with config for Darwin
      darwinPkgs =
        system:
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            allowBroken = true; # Allow broken packages (needed for Linux packages on macOS)
          };
        };
    in
    {
      nixosConfigurations = {
        jayne = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs system;
            inherit (customLib) mkApp mkCategory mkHomeModule mkHomeCategory;
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
          specialArgs = {
            inherit inputs system;
            inherit (customLib) mkApp mkCategory mkHomeModule mkHomeCategory;
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
          specialArgs = {
            inherit inputs system;
            inherit (customLib) mkApp mkCategory mkHomeModule mkHomeCategory;
            isLinux = true;
          };
          modules = [
            ./hosts/serenity/configuration.nix
            ./modules/homelab
            inputs.sops-nix.nixosModules.sops
          ];
        };
        shepherd = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs system;
            inherit (customLib) mkApp mkCategory mkHomeModule mkHomeCategory;
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
          specialArgs = {
            inherit inputs system;
            inherit (customLib) mkApp mkCategory mkHomeModule mkHomeCategory;
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
          pkgs = darwinPkgs "aarch64-darwin"; # Use configured pkgs with allowBroken
          specialArgs = {
            inherit inputs system;
            inherit (customLib) mkApp mkCategory mkHomeModule mkHomeCategory;
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

      # Development shells for different project types
      devShells.x86_64-linux = {
        vue-nuxt = import ./devshells/vue-nuxt {
          inherit nixpkgs;
          system = "x86_64-linux";
        };
        nodejs = import ./devshells/nodejs {
          inherit nixpkgs;
          system = "x86_64-linux";
        };
        flutter = import ./devshells/flutter {
          inherit nixpkgs;
          system = "x86_64-linux";
        };
        flutter-appwrite = import ./devshells/flutter-appwrite {
          inherit nixpkgs;
          system = "x86_64-linux";
        };
        docker = import ./devshells/docker {
          inherit nixpkgs;
          system = "x86_64-linux";
        };
      };
    };
}
