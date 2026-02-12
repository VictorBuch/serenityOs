args@{
  config,
  pkgs,
  lib,
  inputs,
  system,
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
    pkgs.unstable.lazysql
    pkgs.unstable.ripgrep
    pkgs.unstable.fd
    pkgs.unstable.nodejs_22
    pkgs.llm-agents.claude-code
    pkgs.unstable.gitea-mcp-server
    pkgs.unstable.yazi
    pkgs.unstable.devenv
    pkgs.unstable.jujutsu
    pkgs.unstable.jjui
    pkgs.unstable.go
    pkgs.unstable.opencode
  ];
  description = "Common development tools";
} args
