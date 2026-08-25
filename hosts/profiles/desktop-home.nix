# Shared configuration for Linux desktop machines (jayne, kaylee)
# Enables common app categories for desktops.
# HM config is now injected by unified modules via home-manager.sharedModules.
{ inputs, ... }:
{
  # Flake HM modules still need to be imported here
  # (they define HM options used by our modules).
  #
  # noctalia is NOT in this list: home-manager now ships its own
  # programs.noctalia module, and importing both makes the option collide.
  # The flake's package is selected in
  # modules/nixos/desktop-environments/_home/common/noctalia.nix instead.
  home-manager.sharedModules = [
    inputs.zen-browser.homeModules.default
  ];

  # Enable app categories for desktop use
  apps = {
    cli.enable = true;
    neovim.nixvim.enable = false;
    theming.stylix.enable = true;
  };
}
