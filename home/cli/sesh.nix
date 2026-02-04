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
        package = pkgs.unstable.sesh;
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
                "git"
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
              startup_script = "jj pull; jj log";
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
