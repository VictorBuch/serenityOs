{ pkgs, username, ... }:

{
  home.username = username;
  home.homeDirectory = if pkgs.stdenv.hostPlatform.isLinux then "/home/${username}" else "/Users/${username}";
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
}
