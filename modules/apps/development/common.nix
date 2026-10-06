args@{
  config,
  pkgs,
  lib,
  mkModule,
  ...
}:

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
      pkgs.lazyjj
      pkgs.go
      pkgs.opencode
      pkgs.bun
      pkgs.pnpm
      pkgs.gh
      pkgs.tea
      pkgs.bat
    ];
  homeConfig = {
    programs.superfile = {
      enable = true;
      settings = {
        editor = "nvim";
        zoxide_support = true;
        ignore_missing_fields = true;
      };
    };
  };
  description = "Common development tools";
} args
