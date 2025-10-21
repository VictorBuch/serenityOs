{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    home.desktop-environments.niri.waybar.enable = lib.mkEnableOption "Enables waybar for niri";
  };

  config = lib.mkIf config.home.desktop-environments.niri.waybar.enable {
    programs.waybar = {
      enable = true;
      style = ''
        * {
          font-family: JetBrainsMono;
          font-size: 16px;
          min-height: 0;
          color: white;
        }

        window#waybar {
          background-color: transparent;
        }

        #workspaces {
          margin-top: 3px;
          margin-bottom: 2px;
          margin-right: 10px;
          margin-left: 25px;
        }

        #workspaces button {
          border-radius: 15px;
          margin-right: 10px;
          padding: 1px 10px;
          font-weight: bolder;
          background-color: #181818;
        }

        #workspaces button.active, #workspaces button.focused {
          padding: 0 22px;
          box-shadow: rgba(6, 24, 44, 0.4) 0px 0px 0px 2px, rgba(6, 24, 44, 0.65) 0px 4px 6px -1px, rgba(255, 255, 255, 0.08) 0px 1px 0px inset;
          background: #7C9D96;
        }

        #workspaces button.empty:not(.active):not(.focused) {
          opacity: 0;
          min-width: 0;
          padding: 0;
          margin: 0;
        }

        #tray,
        #mpd,
        #custom-weather,
        #cpu,
        #temperature,
        #memory,
        #sway-mode,
        #backlight,
        #pulseaudio,
        #custom-vpn,
        #disk,
        #custom-recorder,
        #custom-audiorec,
        #battery,
        #clock,
        #idle_inhibitor,
        #network {
          padding: 0 10px;
        }
      '';

      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 16;
          margin-bottom = 0;
          margin-top = 0;

          modules-left = [
          ];
          modules-center = [
            "niri/workspaces"
          ];
          modules-right = [
            "tray"
            "pulseaudio"
            "clock"
          ];

          "battery" = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{icon} {capacity}%";
            format-charging = " {capacity}%";
            format-plugged = " {capacity}%";
            format-alt = "{icon} {time}";
            format-icons = [ ];
          };

          "niri/workspaces" = {
            all-outputs = true;
            format = "{index}";
          };

          "niri/window" = {
            max-length = 200;
            separate-outputs = true;
          };

          "tray" = {
            icon-size = 16;
            spacing = 6;
          };

          "clock" = {
            locale = "C";
            format = " {:%I:%M %p}";
            format-alt = " {:%a,%b %d}";
          };

          "cpu" = {
            format = " {usage}%";
            tooltip = false;
            on-click = "kitty -e 'htop'";
          };

          "memory" = {
            interval = 30;
            format = " {used:0.2f}GB";
            max-length = 10;
            tooltip = false;
            warning = 70;
            critical = 90;
          };

          "network" = {
            interval = 2;
            format-wifi = " {signalStrength}%";
            format-ethernet = "";
            format-linked = " {ipaddr}";
            format-disconnected = " Disconnected";
            format-disabled = "";
            tooltip = false;
            max-length = 20;
            min-length = 6;
            format-alt = "{essid}";
          };

          "idle_inhibitor" = {
            format = "{icon}";
            format-icons = {
              activated = "";
              deactivated = "";
            };
          };

          "backlight" = {
            format = "{icon} {percent}%";
            format-icons = [
              ""
              ""
            ];
            on-scroll-down = "brightnessctl -c backlight set 1%-";
            on-scroll-up = "brightnessctl -c backlight set +1%";
          };

          "pulseaudio" = {
            format = "{icon} {volume}% {format_source}";
            format-bluetooth = "{icon} {volume}% {format_source}";
            format-bluetooth-muted = " {format_source}";
            format-muted = "  {format_source}";
            format-source = " {volume}%";
            format-source-muted = "";
            format-icons = {
              headphone = "🎧";
              hands-free = "🎧";
              headset = "🎧";
              phone = "🎧";
              portable = "🎧";
              car = "🎧";
              default = [ "🎧" ];
            };
            on-click = "pavucontrol";
          };

          "mpd" = {
            format = "{stateIcon} {artist} - {title}";
            format-disconnected = "🎶";
            format-stopped = "♪";
            interval = 10;
            consume-icons = {
              on = " ";
            };
            random-icons = {
              off = "<span color=\"#f53c3c\"></span> ";
              on = " ";
            };
            repeat-icons = {
              on = " ";
            };
            single-icons = {
              on = "1 ";
            };
            state-icons = {
              paused = "";
              playing = "";
            };
            tooltip-format = "MPD (connected)";
            tooltip-format-disconnected = "MPD (disconnected)";
            max-length = 35;
          };

          "custom/recorder" = {
            format = " Rec";
            format-disabled = " Off-air";
            return-type = "json";
            interval = 1;
            exec = "echo '{\"class\": \"recording\"}'";
            exec-if = "pgrep wf-recorder";
          };

          "custom/audiorec" = {
            format = "♬ Rec";
            format-disabled = "♬ Off-air";
            return-type = "json";
            interval = 1;
            exec = "echo '{\"class\": \"audio recording\"}'";
            exec-if = "pgrep ffmpeg";
          };
        };
      };
    };
  };
}
