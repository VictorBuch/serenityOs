args@{
  config,
  pkgs,
  lib,
  inputs ? null,
  isLinux,
  mkApp,
  ...
}:

mkApp {
  _file = toString ./.;
  name = "common";
  packages = pkgs: [
    pkgs.unstable.fastfetch
    pkgs.unstable.starship
    pkgs.unstable.zoxide
    pkgs.unstable.fzf
    pkgs.unstable.lazygit
    pkgs.unstable.ripgrep
    pkgs.unstable.fd
    pkgs.unstable.nodePackages.nodejs
    pkgs.unstable.claude-code
    pkgs.unstable.mcp-nixos
    pkgs.unstable.yazi
    pkgs.unstable.devenv
    pkgs.unstable.jujutsu
    pkgs.unstable.pocketbase
  ];
  description = "Common development tools";
} args
