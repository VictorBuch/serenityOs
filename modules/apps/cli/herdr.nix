args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "herdr";
  category = "cli";
  description = "Mouse-first terminal multiplexer (tmux/zellij alternative)";
  linuxPackages = { pkgs, ... }: [ pkgs.herdr pkgs.jujutsu pkgs.cargo pkgs.rustc pkgs.jq ];

  linuxHomeConfig = { pkgs, lib, ... }: {
    xdg.configFile."herdr/config.toml".source =
      (pkgs.formats.toml { }).generate "herdr-config.toml" {
        theme = {
          name = "terminal";
        };
        keys = {
          prefix = "ctrl+space";
          command = [
            {
              key = "prefix+a";
              type = "plugin_action";
              command = "nathanflurry.jj-workspace.new-tab";
              description = "new jj workspace (in tab)";
            }
            {
              key = "prefix+shift+a";
              type = "plugin_action";
              command = "nathanflurry.jj-workspace.new";
              description = "new jj workspace";
            }
            {
              key = "prefix+d";
              type = "plugin_action";
              command = "nathanflurry.jj-workspace.remove";
              description = "remove jj workspace";
            }
            # vim-herdr-navigation: vim-tmux-navigator equivalent (ctrl+hjkl).
            {
              key = "ctrl+h";
              type = "plugin_action";
              command = "vim-herdr-navigation.left";
              description = "navigate left (vim/herdr)";
            }
            {
              key = "ctrl+j";
              type = "plugin_action";
              command = "vim-herdr-navigation.down";
              description = "navigate down (vim/herdr)";
            }
            {
              key = "ctrl+k";
              type = "plugin_action";
              command = "vim-herdr-navigation.up";
              description = "navigate up (vim/herdr)";
            }
            {
              key = "ctrl+l";
              type = "plugin_action";
              command = "vim-herdr-navigation.right";
              description = "navigate right (vim/herdr)";
            }
          ];
        };
      };
  };
} args
