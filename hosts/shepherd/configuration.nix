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
  ];

  networking.hostName = "shepherd";
  user.userName = username;

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
