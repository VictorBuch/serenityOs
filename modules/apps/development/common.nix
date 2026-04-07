args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "common";
  category = "development";
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
