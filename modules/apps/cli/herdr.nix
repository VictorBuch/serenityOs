{
  flake.modules.nixos.herdr =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        pkgs.herdr
        pkgs.herdr-desktop
        pkgs.jujutsu
        pkgs.cargo
        pkgs.rustc
        pkgs.jq
      ];
    };
  flake.modules.homeManager.herdr =
    { pkgs, lib, ... }:
    {
      xdg.configFile."herdr-app/keys.json".source = ./herdr-app-keys.json;
      xdg.configFile."herdr-app/layouts/clean.json".source = ./_herdr-app/layouts/clean.json;
      xdg.configFile."herdr-app/mods" = {
        source = ./_herdr-app/mods;
        recursive = true;
      };

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings."192.168.0.243" = {
          ControlMaster = "auto";
          ControlPath = "~/.ssh/cm-%C";
          ControlPersist = "yes";
        };
      };

      xdg.configFile."herdr/config.toml".source = (pkgs.formats.toml { }).generate "herdr-config.toml" {
        theme = {
          name = "terminal";
        };
        onboarding = false;
        ui = {
          prompt_new_tab_name = false;
          pane_outer_borders = false;
          pane_gaps = false;
          sidebar_start_collapsed = true;
          tab_bar_right = [
            {
              type = "command";
              command = "${pkgs.writeShellScript "herdr-fortune" "${pkgs.fortune}/bin/fortune -n 50 -s | tr -s '\\n\\t' ' '"}";
              interval_seconds = 1800;
            }
          ];
        };
        keys = {
          prefix = "ctrl+space";
          split_vertical = "prefix+v";
          split_horizontal = "prefix+h";
          focus_pane_left = "";
          move_tab_previous = "prefix+<";
          move_tab_next = "prefix+>";
          previous_tab = "prefix+space";
          settings = "prefix+comma";
          detach = "prefix+d";
          close_workspace = "prefix+ctrl+d";
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
              key = "prefix+shift+d";
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
}
