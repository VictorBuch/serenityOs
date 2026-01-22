{ pkgs, lib, ... }:
{
  # Darwin-specific modules
  imports = [
    ./homebrew.nix
  ];

  # Enable homebrew by default for darwin systems
  darwin.homebrew.enable = lib.mkDefault true;
}
