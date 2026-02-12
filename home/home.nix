{
  config,
  pkgs,
  username,
  inputs,
  lib,
  isLinux,
  ...
}:

{
  home.username = username;
  home.homeDirectory = if isLinux then "/home/${username}" else "/Users/${username}";

  home.stateVersion = "24.05"; # Please read the comment before changing.

  # HM now follows unstable nixpkgs (same as our hosts), so no version mismatch anymore
  # No need to disable the release check

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through "home.file".
  home.file = {
  };

  home.sessionVariables = {
  };

}
