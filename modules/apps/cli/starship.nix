args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "starship";
  category = "cli";
  description = "Starship prompt";
  homeConfig =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      home.packages = [ pkgs.starship-jj ];

      xdg.configFile."starship-jj/starship-jj.toml".source =
        (pkgs.formats.toml { }).generate "starship-jj.toml"
          {
            module_separator = " ";
            reset_color = false;
            bookmarks = {
              search_depth = 100;
              exclude = [ ];
            };
            module = [
              {
                type = "Symbol";
                symbol = "󱗆";
                color = "Yellow";
              }
              {
                type = "Bookmarks";
                separator = " ";
                color = "Yellow";
                behind_symbol = "⇡";
                surround_with_quotes = false;
              }
              {
                type = "Commit";
                previous_message_symbol = "⇣";
                max_length = 24;
                show_previous_if_empty = false;
                empty_text = "";
                surround_with_quotes = false;
              }
              {
                type = "State";
                separator = " ";
                conflict = {
                  disabled = false;
                  text = "(CONFLICT)";
                  color = "Red";
                };
                divergent = {
                  disabled = false;
                  text = "(DIVERGENT)";
                  color = "Cyan";
                };
                empty = {
                  disabled = true;
                  text = "(EMPTY)";
                  color = "Yellow";
                };
                immutable = {
                  disabled = false;
                  text = "(IMMUTABLE)";
                  color = "Yellow";
                };
                hidden = {
                  disabled = false;
                  text = "(HIDDEN)";
                  color = "Yellow";
                };
              }
              {
                type = "Metrics";
                template = "[{changed} {added}{removed}]";
                hide_if_empty = true;
                color = "Yellow";
                changed_files = {
                  prefix = "";
                  suffix = "";
                  color = "Cyan";
                };
                added_lines = {
                  prefix = "+";
                  suffix = "";
                  color = "Green";
                };
                removed_lines = {
                  prefix = "-";
                  suffix = "";
                  color = "Red";
                };
              }
            ];
          };

      programs.starship = {
        enable = true;
        enableNushellIntegration = true;
        package = pkgs.starship;
        settings = {
          "$schema" = "https://starship.rs/config-schema.json";

          format = "$status$os $directory  \${custom.jj}\${custom.git} $golang$nodejs$php$python $cmd_duration$line_break$character";

          # palette = "catppuccin_mocha"; # managed by stylix

          os = {
            disabled = false;
            style = "fg:blue";
            format = "[$symbol]($style)";
            symbols = {
              Macos = " 󰀵 ";
              Linux = "  ";
              NixOS = "  ";
            };
          };

          username = {
            show_always = true;
            style_user = "fg:red";
            style_root = "fg:red";
            format = "[$user]($style)";
          };

          directory = {
            style = "fg:peach";
            format = "[󰉋/$path]($style)";
            truncation_length = 3;
            truncation_symbol = ".../";
            substitutions = {
              Documents = "󰈙";
              Downloads = "󰉍";
              Music = "󰝚";
              Pictures = "󰉏";
              Developer = "󰲋";
              github = "";
              work = "󰦑";
              serenityOs = "󰚀";
            };
          };

          custom.jj = {
            command = "starship-jj --ignore-working-copy starship prompt";
            when = "starship-jj root --ignore-working-copy";
            shell = [ "sh" ];
            format = "$output";
          };

          custom.git = {
            command =
              let
                starship = lib.getExe config.programs.starship.package;
              in
              "STARSHIP_SHELL= ${starship} module git_branch; STARSHIP_SHELL= ${starship} module git_status";
            when = "! starship-jj root --ignore-working-copy";
            require_repo = true;
            shell = [ "sh" ];
            format = "$output";
          };

          git_branch = {
            symbol = "󰘬/";
            style = "fg:yellow";
            format = "[[$symbol$branch ](fg:yellow)]($style)";
          };

          git_status = {
            style = "fg:yellow";
            format = "[[($all_status$ahead_behind)](fg:yellow)]($style)";
          };

          nodejs = {
            symbol = "";
            style = "fg:green";
            format = "[[$symbol( $version)](fg:green)]($style)";
          };

          golang = {
            symbol = "";
            style = "fg:green";
            format = "[[$symbol( $version)](fg:green)]($style)";
          };

          php = {
            symbol = "";
            style = "fg:green";
            format = "[[$symbol( $version)](fg:green)]($style)";
          };

          kotlin = {
            symbol = "";
            style = "fg:green";
            format = "[[$symbol( $version)](fg:green)]($style)";
          };

          python = {
            symbol = "";
            style = "fg:green";
            format = "[[$symbol( $version)(($virtualenv))](fg:green)]($style)";
          };

          docker_context = {
            symbol = "";
            style = "fg:sapphire";
            format = "[[$symbol( $context)](fg:sapphire)]($style)";
          };

          time = {
            disabled = false;
            time_format = "%R";
            style = "fg:lavender";
            format = "[[$time](fg:lavender)]($style)";
          };

          line_break = {
            disabled = false;
          };

          status = {
            disabled = false;
            success_symbol = "[╭─](bold fg:green)";
            format = "[$symbol]($style)";
            map_symbol = true;
          };

          character = {
            disabled = false;
            success_symbol = "[╰](bold fg:green)";
            error_symbol = "[╰](bold fg:red)";
            vimcmd_symbol = "[╰](bold fg:green)";
            vimcmd_replace_one_symbol = "[╰](bold fg:lavender)";
            vimcmd_replace_symbol = "[╰](bold fg:lavender)";
            vimcmd_visual_symbol = "[╰](bold fg:yellow)";
          };

          cmd_duration = {
            show_milliseconds = false;
            format = "[󱎫 $duration]($style)";
            style = "fg:pink";
            disabled = false;
            show_notifications = true;
            min_time_to_notify = 45000;
          };
        };
      };
    };
} args
