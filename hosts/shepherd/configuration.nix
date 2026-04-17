{
  config,
  pkgs,
  inputs,
  pkgs-stable,
  ...
}:
let
  username = "shepherd";
in
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../profiles/shepherd.nix
    inputs.home-manager.nixosModules.default
  ];

  networking.hostName = "shepherd";
  user.userName = username;

  home-manager = {
    extraSpecialArgs = {
      inherit username;
    };
    users = {
      "${username}" = import ../../home/default.nix;
    };
  };

  users.users.nixos = {
    isNormalUser = true;
    description = "default";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      neovim
      nushell
      git
      lazygit
      zoxide
      ripgrep
      fd
    ];
    shell = pkgs.nushell;
  };

  system.stateVersion = "25.05";
}
