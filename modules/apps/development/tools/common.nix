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
  packages =
    { pkgs, ... }:
    [
      pkgs.fastfetch
      pkgs.starship
      pkgs.zoxide
      pkgs.fzf
      pkgs.lazygit
      pkgs.lazysql
      pkgs.ripgrep
      pkgs.fd
      pkgs.nodejs_22
      pkgs.llm-agents.claude-code
      pkgs.gitea-mcp-server
      pkgs.yazi
      pkgs.devenv
      pkgs.jujutsu
      pkgs.jjui
      pkgs.go
      pkgs.opencode
    ];
  description = "Common development tools";
} args
