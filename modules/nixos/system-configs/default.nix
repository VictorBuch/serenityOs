{ pkgs, lib, ... }:
{

  imports = [
    ./amd-gpu.nix
    ./user.nix
    ./nvidia-gpu.nix
    ./networking
    ./maintenance
  ];
}
