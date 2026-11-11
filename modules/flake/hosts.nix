{
  inputs,
  self,
  withSystem,
  ...
}:
let
  inherit (inputs) nixpkgs nix-darwin import-tree;
  customLib = import ../../lib { inherit (nixpkgs) lib; };

  mkHost =
    {
      name,
      class ? "nixos",
      system ? if class == "darwin" then "aarch64-darwin" else "x86_64-linux",
      hostConfig ? ../../hosts/${name}/configuration.nix,
      platformModules ? true,
      extraModules ? [ ],
    }:
    let
      darwin = class == "darwin";
      builder = if darwin then nix-darwin.lib.darwinSystem else nixpkgs.lib.nixosSystem;
      platformTree =
        if darwin then
          [ (import-tree ../darwin) ]
        else
          nixpkgs.lib.optional platformModules (import-tree ../nixos);
    in
    withSystem system (
      { pkgs, pkgs-stable, ... }:
      builder {
        inherit system pkgs;
        specialArgs = {
          inherit inputs system pkgs pkgs-stable;
          inherit (customLib) mkModule expiring;
        };
        modules = [
          (import-tree ../common)
          ../common/_defaults.nix
          (import-tree ../apps)
          hostConfig
          (if darwin then inputs.home-manager.darwinModules.default else inputs.home-manager.nixosModules.default)
          (if darwin then inputs.sops-nix.darwinModules.sops else inputs.sops-nix.nixosModules.sops)
        ]
        ++ platformTree
        ++ extraModules;
      }
    );

  hosts = [
    { name = "jayne"; }
    {
      name = "mal";
      platformModules = false;
      extraModules = [
        (import-tree ../homelab)
        ../homelab/_config.nix
        ../nixos/system/user.nix
        inputs.wannashare.nixosModules.default
        inputs.sparkyfitness.nixosModules.sparkyfitness
        inputs.tv-learn.nixosModules.tv-learn
      ];
    }
    {
      name = "wash";
      platformModules = false;
      extraModules = [
        ../homelab/_config.nix
        ../nixos/system/user.nix
        inputs.disko.nixosModules.disko
      ];
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
in
{
  flake = {
    nixosConfigurations = hostsOfClass "nixos";
    darwinConfigurations = hostsOfClass "darwin";

    checks.x86_64-linux.inara = withSystem "x86_64-linux" (
      { pkgs, ... }:
      pkgs.writeText "inara" (
        builtins.unsafeDiscardStringContext self.darwinConfigurations.inara.system.drvPath
      )
    );

    checks.x86_64-linux.shell-actions =
      self.nixosConfigurations.jayne.config.home-manager.users.jayne.home.desktop.shell.check;
  };
}
