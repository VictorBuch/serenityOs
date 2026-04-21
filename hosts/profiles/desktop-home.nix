# Shared configuration for Linux desktop machines (jayne, kaylee)
# Enables common app categories for desktops.
# HM config is now injected by unified modules via home-manager.sharedModules.
{ inputs, ... }:
{
  # Flake HM modules still need to be imported here
  # (they define HM options used by our modules)
  home-manager.sharedModules = [
    inputs.noctalia.homeModules.default
    inputs.zen-browser.homeModules.default
    inputs.peon-ping.homeManagerModules.default
  ];

  # Enable app categories for desktop use
  apps = {
    cli.enable = true;
    neovim.nixvim.enable = true;
    theming.stylix.enable = true;
  };
}
