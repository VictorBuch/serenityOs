{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    home.desktop-environments.hyprland.waybar.enable = lib.mkEnableOption "Enables waybar home manager";
  };

  config = lib.mkIf config.home.desktop-environments.hyprland.waybar.enable {
    programs.waybar = {
      enable = true;
      style = ''
        * {
          font-family: "JetBrainsMono Nerd Font", FontAwesome, Roboto, Helvetica, Arial, sans-serif;
          font-size: 16px;
          transition: background-color 0.3s ease;
        }

        window#waybar {
          background: rgba(26, 27, 38, 0);
          color: #c0caf5;
          transition: background-color 0.5s;
        }

        .modules-left,
        .modules-center,
        .modules-right {
          background: #1e1e2e;
          margin: 5px 10px;
          padding: 0 10px;
          border-radius: 12px;
        }

        /* Workspaces styling */
        #workspaces {
          padding: 0 5px;
        }

        #workspaces button {
          padding: 0 8px;
          margin: 4px 3px;
          border-radius: 10px;
          background: transparent;
          color: #cdd6f4;
          border: none;
          transition: all 0.3s ease;
        }

        #workspaces button.active {
          background: #89b4fa;
          color: #11111b;
          font-weight: bold;
        }

        #workspaces button:hover {
          background: #313244;
          color: #cdd6f4;
          box-shadow: none;
        }

        /* Window title styling */
        #window {
          padding: 0 10px;
          font-weight: 500;
          color: #cdd6f4;
        }

        /* Status modules styling */
        #clock,
        #pulseaudio,
        #network,
        #custom-power {
          padding: 0 10px;
          margin: 0 2px;
          color: #cdd6f4;
        }

        #custom-power {
          color: #f38ba8;
          font-size: 18px;
          margin-right: 5px;
          font-weight: bold;
        }

        #clock {
          color: inherit;
        }

        #pulseaudio {
          color: inherit;
        }

        #network {
          color: inherit;
        }

        #pulseaudio.muted {
          color: inherit;
        }

        #network.disconnected {
          color: inherit;
        }
      '';

      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 24;
          spacing = 4;

          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ "hyprland/window" ];
          modules-right = [
            "hyprland/language"
            "pulseaudio"
            "network"
            "clock"
            "custom/power"
          ];

          "hyprland/workspaces" = {
            disable-scroll = true;
            all-outputs = true;
            format = "{name}";
            persistent-workspaces = {
              "1" = [ ];
              "2" = [ ];
              "3" = [ ];
              "4" = [ ];
              "5" = [ ];
            };
          };

          "hyprland/window" = {
            format = "{}";
            max-length = 30;
            icon = true;
            separate-outputs = true;
          };

          "hyprland/language" = {
            format = "  {}";
            format-en = "EN";
            format-dk = "DK";
          };

          "pulseaudio" = {
            format = "{icon} {volume}%";
            format-bluetooth = "{icon} {volume}%";
            format-muted = "";
            format-icons = {
              headphone = "";
              hands-free = "";
              headset = "";
              phone = "";
              portable = "";
              car = "";
              default = [
                ""
                ""
                ""
              ];
            };
            scroll-step = 1;
            on-click = "pavucontrol";
          };

          "network" = {
            format-wifi = "  {essid}";
            format-ethernet = "󰈀 Connected";
            format-disconnected = "󰖪 Disconnected";
            tooltip-format = "{ifname}: {ipaddr}/{cidr}";
            tooltip-format-wifi = "{essid} ({signalStrength}%) ";
            on-click = "nm-connection-editor";
          };

          "clock" = {
            format = "{:%H:%M}";
            on-click = "gnome-calendar";
          };

          "custom/power" = {
            format = "⏻";
            on-click = "wlogout -p layer-shell";
            tooltip = false;
          };
        };
      };
    };
  };
}
