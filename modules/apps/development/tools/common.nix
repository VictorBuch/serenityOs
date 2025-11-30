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
    pkgs.fastfetch
    pkgs.starship
    pkgs.zoxide
    pkgs.fzf
    pkgs.lazygit
    pkgs.ripgrep
    pkgs.fd
    pkgs.nodePackages.nodejs
    pkgs.claude-code
    pkgs.mcp-nixos
    pkgs.yazi
    pkgs.devenv
    pkgs.jujutsu
    pkgs.pocketbase
  ];
  description = "Common development tools";
} args
