args@{ config, pkgs, lib, mkHomeModule, ... }:

mkHomeModule {
  _file = toString ./.;
  name = "tmux";
  description = "Terminal multiplexer";
  homeConfig = { config, pkgs, lib, ... }: {

    home.packages = with pkgs; [
      tmux
      fortune
    ];

    programs.tmux = {
      enable = true;
      prefix = "C-Space";
      terminal = "screen-256color";
      baseIndex = 1;
      keyMode = "vi";
      escapeTime = 0;
      plugins = [ pkgs.tmuxPlugins.vim-tmux-navigator ];
      extraConfig = ''
        			## Unbind default session list (s) to allow sesh to use it
        			unbind s

        			## use prefix v or h to make a vertical split or horizontal
        			bind v split-window -hc "#{pane_current_path}"
        			bind h split-window -vc "#{pane_current_path}"

        			## use the arrows to move a window around
        			bind -r "<" swap-window -d -t -1
        			bind -r ">" swap-window -d -t +1

        			bind c new-window -c "#{pane_current_path}" ## new windows open in current path

        			bind Space last-window ## swicth to prev window
        			bind-key C-Space switch-client -l ## switch to prev session

        			set-option -g detach-on-destroy off
        			set-option -g renumber-windows on
        			set-option -g default-terminal "screen-256color"
        			set-option -sa terminal-overrides ",xterm-256color:RGB"


        			# Theme
        			set -g status-style "bg=default,fg=white" # transparent status bar
        			set -g status-position top
        			set -g pane-active-border-style "fg=white,bg=default"
        			set -g pane-border-style "fg=brightblack,bg=default"

        			set -g status-left-length 70
        			set -g status-left "#[fg=blue,bold]#S " # session name
        			set -ga status-left "#[fg=white,bold] "
        			# set -ga status-left "#[fg=white,nobold]#(gitmux -timeout 300ms -cfg $HOME/.config/tmux/gitmux.conf) "

        			set -g status-right-length 70
        			set -g status-right "#(${pkgs.writeShellScript "cached-fortune" ''
        			  CACHE_FILE="$HOME/.cache/tmux-fortune"
        			  CACHE_DURATION=1800  # 30 minutes in seconds

        			  mkdir -p "$HOME/.cache"

        			  if [ -f "$CACHE_FILE" ]; then
        			    CACHE_AGE=$(($(date +%s) - $(date -r "$CACHE_FILE" +%s)))
        			    if [ $CACHE_AGE -lt $CACHE_DURATION ]; then
        			      cat "$CACHE_FILE"
        			      exit 0
        			    fi
        			  fi

        			  ${pkgs.fortune}/bin/fortune -n 50 -s > "$CACHE_FILE"
        			  cat "$CACHE_FILE"
        			''})"


        			# [0 - command]
        			set -g window-status-format "#[fg=brightblack,nobold,bg=default]["
        			set -ga window-status-format "#[fg=brightblack,bg=default]#I #F "
        			set -ga window-status-format "#[fg=white,bg=default]#W"
        			set -ga window-status-format "#[fg=brightblack,nobold,bg=default]]"

        			# [0 * command]
        			set -g window-status-current-format "#[fg=brightblack,nobold,bg=default]["
        			set -ga window-status-current-format "#[fg=brightblack,nobold,bg=default]#I "
        			set -ga window-status-current-format "#[fg=magenta,nobold,bg=default]#F "
        			set -ga window-status-current-format "#[fg=white,bold,bg=default]#W"
        			set -ga window-status-current-format "#[fg=brightblack,nobold,bg=default]]"

              set -g mouse on
        		'';
    };
  };
} args
