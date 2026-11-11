let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [
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
    };
in
{
  flake.modules.nixos.common = module;
  flake.modules.darwin.common = module;
  flake.modules.homeManager.common = {
    programs.superfile = {
      enable = true;
      settings = {
        editor = "nvim";
        zoxide_support = true;
        ignore_missing_fields = true;
      };
    };
  };
}
