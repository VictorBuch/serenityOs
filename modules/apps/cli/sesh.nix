args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "sesh";
  category = "cli";
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
        package = pkgs.sesh;
        enableTmuxIntegration = true;
        enableAlias = false;
        tmuxKey = "s";
        settings = {
          session = [
            {
              name = "web-builder";
              path = "~/Documents/work/web-builder";
              startup_command = "nvim";
              preview_command = "figlet web-builder";
              windows = [
                "jj"
                "node"
              ];
            }
            {
              name = "serenityOs";
              path = "~/serenityOs";
              startup_command = "nvim";
              preview_command = "figlet serenityOs";
              windows = [
                "jj"
              ];
            }
            {
              name = "server serenity";
              path = "~";
              startup_command = "ssh serenity@serenity";
              preview_command = "figlet ssh serenity";
            }
          ];
          window = [
            {
              name = "git";
              startup_script = "lazygit";
            }
            {
              name = "jj";
              startup_script = "jj pull; jjui";
            }
            {
              name = "node";
              startup_script = "pnpm run dev";
            }
          ];
        };
      };
    };
} args
