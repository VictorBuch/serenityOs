args@{ config, pkgs, lib, mkModule, ... }:

let
  # herdr-sesh: a sesh-style space picker for herdr (see ./herdr-sesh.sh).
  herdr-sesh = pkgs.writeShellApplication {
    name = "herdr-sesh";
    runtimeInputs = [ pkgs.herdr pkgs.jq pkgs.fzf pkgs.figlet pkgs.bash pkgs.zoxide pkgs.coreutils pkgs.gnugrep ];
    text = builtins.readFile ./herdr-sesh.sh;
  };

  # jjws: create a jj workspace and register it as a native herdr workspace, so
  # it shows up in the sidebar instead of being invisible (see ./jjws.sh).
  jjws = pkgs.writeShellApplication {
    name = "jjws";
    runtimeInputs = [ pkgs.jujutsu pkgs.git pkgs.herdr pkgs.coreutils ];
    text = builtins.readFile ./jjws.sh;
  };

  # adopt-jj-workspaces: sweep orphan jj workspaces (e.g. created by agents via
  # raw `jj workspace add`) into herdr. Bound to prefix+shift+j below.
  adopt-jj-workspaces = pkgs.writeShellApplication {
    name = "adopt-jj-workspaces";
    runtimeInputs = [ pkgs.herdr pkgs.coreutils ];
    text = builtins.readFile ./adopt-jj-workspaces.sh;
  };

  # Predefined spaces. Each becomes a fzf entry; selecting it focuses the
  # existing workspace or builds a fresh one with named tabs, split panes, and
  # startup commands already running. Mirrors modules/apps/cli/sesh.nix.
  spaces = [
    {
      name = "serenityOs";
      path = "~/serenityOs";
      preview = "figlet serenityOs";
      tabs = [
        {
          name = "edit";
          panes = [ { command = "nvim"; } ];
        }
        {
          name = "jj";
          panes = [
            { command = "jj log"; }
            {
              command = "jjui";
              direction = "down";
              ratio = 0.35;
            }
          ];
        }
      ];
    }
    {
      name = "web-builder";
      path = "~/Documents/work/web-builder";
      preview = "figlet web-builder";
      tabs = [
        {
          name = "edit";
          panes = [ 
            { command = "nvim"; } 
            {
              command = "claudew";
              direction = "right";
              ratio = 0.6;
            } 
          ];
        }
        {
          name = "jj";
          panes = [ { command = "jjui"; } ];
        }
        {
          name = "dev";
          panes = [ { command = "pnpm run dev"; } ];
        }
      ];
    }
    {
      name = "server mal";
      path = "~";
      preview = "figlet ssh mal";
      command = "ssh serenity@mal";
    }
  ];

  seshConfig = (pkgs.formats.json { }).generate "herdr-sesh-spaces.json" {
    inherit spaces;
  };
in
mkModule {
  name = "herdr";
  category = "cli";
  description = "Mouse-first terminal multiplexer (tmux/zellij alternative)";
  linuxPackages =
    { pkgs, ... }:
    [
      pkgs.herdr
      pkgs.jujutsu
      pkgs.cargo
      pkgs.rustc
      pkgs.jq
      herdr-sesh
      jjws
      adopt-jj-workspaces
    ];

  linuxHomeConfig = { pkgs, lib, ... }: {
    # Space definitions consumed by herdr-sesh at runtime.
    xdg.configFile."herdr/sesh-spaces.json".source = seshConfig;

    xdg.configFile."herdr/config.toml".source =
      (pkgs.formats.toml { }).generate "herdr-config.toml" {
        theme = {
          name = "terminal";
        };
        keys = {
          prefix = "ctrl+space";
          command = [
            # prefix+s: sesh-style space picker (fzf popup).
            {
              key = "prefix+s";
              type = "popup";
              command = "${herdr-sesh}/bin/herdr-sesh";
              description = "pick a space (herdr-sesh)";
              width = "60%";
              height = "60%";
            }
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
            # prefix+shift+j: adopt orphan jj workspaces (raw `jj workspace add`,
            # e.g. from agents) into herdr's sidebar (fzf-less popup).
            {
              key = "prefix+shift+j";
              type = "popup";
              command = "${adopt-jj-workspaces}/bin/adopt-jj-workspaces";
              description = "adopt orphan jj workspaces into herdr";
              width = "60%";
              height = "40%";
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
