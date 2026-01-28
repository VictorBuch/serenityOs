{ pkgs, lib, ... }:
{
  # Linux-specific modules
  imports = [
    ./system
    ./desktop-environments
  ];
}
