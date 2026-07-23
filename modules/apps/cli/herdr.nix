args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "herdr";
  category = "cli";
  description = "Mouse-first terminal multiplexer (tmux/zellij alternative)";
  # jujutsu: runtime dep of the jj-workspace plugin (needs `jj` on PATH).
  # cargo/rustc: herdr builds plugins with cargo at `plugin install` time.
  # jq: optional Vim-detection helper for vim-herdr-navigation plugin.
  linuxPackages = { pkgs, ... }: [ pkgs.herdr pkgs.jujutsu pkgs.cargo pkgs.rustc pkgs.jq ];

  # Herdr reads ~/.config/herdr/config.toml (TOML). Own it declaratively.
  # Run `herdr --default-config` to see every available default to add here.
  #
  # Plugin binaries are NOT declarative — install once (imperative):
  #   herdr plugin install NathanFlurry/herdr-plugin-jj-workspace
  # Only its keybindings live here.
  linuxHomeConfig = { pkgs, lib, ... }: {
    xdg.configFile."herdr/config.toml".source =
      (pkgs.formats.toml { }).generate "herdr-config.toml" {
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
