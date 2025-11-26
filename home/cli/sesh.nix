args@{
  config,
  pkgs,
  lib,
  mkHomeModule,
  ...
}:

mkHomeModule {
  _file = toString ./.;
  name = "sesh";
  description = "Session manager for tmux";
  homeConfig =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      programs.sesh = {
        enable = true;
        enableTmuxIntegration = true;
        enableAlias = false;
        tmuxKey = "s";
        settings = {
          session = [
            {
              name = "web-builder";
              path = "~/Documents/work/web-builder";
              startup_command = "nvim";
              preview_command = "bat --color=always 'web-builder'";
              windows = [
                "git"
                "node"
              ];
            }
            {
              name = "serenityOs";
              path = "~/serenityOs";
              startup_command = "nvim";
              preview_command = "bat --color=always 'serenityOs'";
              windows = [
                "git"
              ];
            }
            {
              name = "server serenity";
              path = "~";
              startup_command = "ssh serenity@serenity";
              preview_command = "bat --color=always 'ssh serenity'";
            }
          ];
          window = [
            {
              name = "git";
              startup_script = "lazygit";
            }
            {
              name = "node";
              startup_script = "npm run dev";
            }
          ];
        };
      };
    };
} args
