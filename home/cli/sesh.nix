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
            # {
            #   name = "tmux config";
            #   path = "~/c/dotfiles/.config/tmux";
            #   startup_command = "nvim tmux.conf";
            #   preview_command = "bat --color=always ~/c/dotfiles/.config/tmux/tmux.conf";
            # }
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
