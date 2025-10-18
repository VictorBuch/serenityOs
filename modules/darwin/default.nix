{ pkgs, lib, ... }:
{

  imports = [
    ../common.nix
    ./homebrew.nix
  ];

  # Enable homebrew by default for darwin systems
  darwin.homebrew.enable = lib.mkDefault true;
}
