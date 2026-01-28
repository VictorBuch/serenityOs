{ pkgs, lib, ... }:
{
  # Linux-specific system configurations
  imports = [
    ./amd-gpu.nix
    ./user.nix
    ./nvidia-gpu.nix
    ./networking.nix
  ];
}
