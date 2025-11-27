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
  packages = { pkgs, unstable-pkgs }: [
    unstable-pkgs.fastfetch
    unstable-pkgs.starship
    unstable-pkgs.zoxide
    unstable-pkgs.fzf
    unstable-pkgs.lazygit
    unstable-pkgs.ripgrep
    unstable-pkgs.fd
    unstable-pkgs.nodePackages.nodejs
    unstable-pkgs.claude-code
    unstable-pkgs.mcp-nixos
    unstable-pkgs.yazi
    unstable-pkgs.devenv
    unstable-pkgs.jujutsu
    unstable-pkgs.pocketbase
  ];
  description = "Common development tools";
} args
