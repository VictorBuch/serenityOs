{
  config,
  lib,
  pkgs,
  ...
}:
let
  scriptsDir = "${config.xdg.configHome}/waybar/scripts";
in
{
  options = {
    home.desktop-environments.niri.waybar.enable = lib.mkEnableOption "Enables waybar for niri";
  };

  config = lib.mkIf config.home.desktop-environments.niri.waybar.enable {
    # Deploy waybar scripts
    xdg.configFile = {
      "waybar/scripts/volume.sh" = {
        source = ./scripts/volume.sh;
        executable = true;
      };
      "waybar/scripts/backlight.sh" = {
        source = ./scripts/backlight.sh;
        executable = true;
      };
      "waybar/scripts/bluetooth.sh" = {
        source = ./scripts/bluetooth.sh;
        executable = true;
      };
      "waybar/scripts/network.sh" = {
        source = ./scripts/network.sh;
        executable = true;
      };
      "waybar/scripts/system-update.sh" = {
        source = ./scripts/system-update.sh;
        executable = true;
      };
    };

    programs.waybar = {
      enable = true;
      style = builtins.readFile ./style.css;

      settings = {
        mainBar = {
          # Layout
          modules-left = [
            "group/user"
            "custom/left_div#1"
            "niri/workspaces"
            "custom/right_div#1"
            "niri/window"
          ];
          modules-center = [
            "custom/left_div#2"
            "temperature"
            "custom/left_div#3"
            "memory"
            "custom/left_div#4"
            "cpu"
            "custom/left_inv#1"
            "custom/left_div#5"
            "custom/distro"
            "custom/right_div#2"
            "custom/right_inv#1"
            "idle_inhibitor"
            "clock#time"
            "custom/right_div#3"
            "clock#date"
            "custom/right_div#4"
            "network"
            "bluetooth"
            "custom/system_update"
            "custom/right_div#5"
          ];
          modules-right = [
            "mpris"
            "custom/left_div#6"
            "group/pulseaudio"
            "custom/left_div#7"
            "backlight"
            "custom/left_div#8"
            "battery"
            "custom/left_inv#2"
            "custom/power_menu"
          ];

          # Options
          layer = "top";
          height = 0;
          width = 0;
          margin = 0;
          spacing = 0;
          mode = "dock";
          reload_style_on_change = true;

          # Niri Workspaces
          "niri/workspaces" = {
            format = "{icon}";
            format-icons = {
              active = "";
              default = "";
            };
          };

          # Niri Window
          "niri/window" = {
            format = "{}";
            rewrite = {
              "" = "Desktop";
              "ghostty" = "Terminal";
              "kitty" = "Terminal";
              "zsh" = "Terminal";
              "~" = "Terminal";
            };
            separate-outputs = true;
          };

          # User Group
          "group/user" = {
            orientation = "horizontal";
            modules = [ "custom/user" ];
          };

          "custom/user" = {
            exec = "id -un";
            format = "{}";
            tooltip = false;
          };

          # Dividers (Powerline triangles)
          "custom/left_div#1" = {
            format = "";
            tooltip = false;
          };
          "custom/left_div#2" = {
            format = "";
            tooltip = false;
          };
          "custom/left_div#3" = {
            format = "";
            tooltip = false;
          };
          "custom/left_div#4" = {
            format = "";
            tooltip = false;
          };
          "custom/left_div#5" = {
            format = "";
            tooltip = false;
          };
          "custom/left_div#6" = {
            format = "";
            tooltip = false;
          };
          "custom/left_div#7" = {
            format = "";
            tooltip = false;
          };
          "custom/left_div#8" = {
            format = "";
            tooltip = false;
          };

          "custom/right_div#1" = {
            format = "";
            tooltip = false;
          };
          "custom/right_div#2" = {
            format = "";
            tooltip = false;
          };
          "custom/right_div#3" = {
            format = "";
            tooltip = false;
          };
          "custom/right_div#4" = {
            format = "";
            tooltip = false;
          };
          "custom/right_div#5" = {
            format = "";
            tooltip = false;
          };

          "custom/left_inv#1" = {
            format = "";
            tooltip = false;
          };
          "custom/left_inv#2" = {
            format = "";
            tooltip = false;
          };

          "custom/right_inv#1" = {
            format = "";
            tooltip = false;
          };

          # Temperature
          temperature = {
            thermal-zone = 1;
            critical-threshold = 90;
            interval = 10;
            format-critical = "󰀦 {temperatureC}°C";
            format = "{icon} {temperatureC}°C";
            format-icons = [
              "󱃃"
              "󰔏"
              "󱃂"
            ];
            min-length = 8;
            max-length = 8;
            tooltip-format = "Temp in Fahrenheit: {temperatureF}°F";
          };

          # Memory
          memory = {
            interval = 10;
            format = "󰘚 {percentage}%";
            format-warning = "󰀧 {percentage}%";
            format-critical = "󰀧 {percentage}%";
            states = {
              warning = 75;
              critical = 90;
            };
            min-length = 7;
            max-length = 7;
            tooltip-format = "Memory Used: {used:0.1f} GB / {total:0.1f} GB";
          };

          # CPU
          cpu = {
            interval = 10;
            format = "󰍛 {usage}%";
            format-warning = "󰀨 {usage}%";
            format-critical = "󰀨 {usage}%";
            min-length = 7;
            max-length = 7;
            states = {
              warning = 75;
              critical = 90;
            };
            tooltip = false;
          };

          # Distro Icon
          "custom/distro" = {
            format = "";
            tooltip = false;
          };

          # Idle Inhibitor
          idle_inhibitor = {
            format = "{icon}";
            format-icons = {
              activated = "󰈈";
              deactivated = "󰈉";
            };
            min-length = 3;
            max-length = 3;
            tooltip-format-activated = "Keep Screen On: <span text_transform='capitalize'>{status}</span>";
            tooltip-format-deactivated = "Keep Screen On: <span text_transform='capitalize'>{status}</span>";
            start-activated = false;
          };

          # Clock
          "clock#time" = {
            format = "{:%H:%M}";
            min-length = 5;
            max-length = 5;
            tooltip-format = "Standard Time: {:%I:%M %p}";
          };

          "clock#date" = {
            format = "󰸗 {:%m-%d}";
            min-length = 8;
            max-length = 8;
            tooltip-format = "{calendar}";
            calendar = {
              mode = "month";
              mode-mon-col = 6;
              format = {
                months = "<span alpha='100%'><b>{}</b></span>";
                days = "<span alpha='90%'>{}</span>";
                weekdays = "<span alpha='80%'><i>{}</i></span>";
                today = "<span alpha='100%'><b><u>{}</u></b></span>";
              };
            };
            actions = {
              on-click = "mode";
            };
          };

          # Network
          network = {
            interval = 10;
            format = "󰤨";
            format-ethernet = "󰈀";
            format-wifi = "{icon}";
            format-disconnected = "󰤯";
            format-disabled = "󰤮";
            format-icons = [
              "󰤟"
              "󰤢"
              "󰤥"
              "󰤨"
            ];
            min-length = 2;
            max-length = 2;
            on-click = "ghostty -e ${scriptsDir}/network.sh";
            on-click-right = "nmcli radio wifi off && notify-send 'Wi-Fi Disabled' -i 'network-wireless-off' -r 1125";
            tooltip-format = "Gateway: {gwaddr}";
            tooltip-format-ethernet = "Interface: {ifname}";
            tooltip-format-wifi = "Network: {essid}\nIP Addr: {ipaddr}/{cidr}\nStrength: {signalStrength}%\nFrequency: {frequency} GHz";
            tooltip-format-disconnected = "Wi-Fi Disconnected";
            tooltip-format-disabled = "Wi-Fi Disabled";
          };

          # Bluetooth
          bluetooth = {
            format = "󰂯";
            format-disabled = "󰂲";
            format-off = "󰂲";
            format-on = "󰂰";
            format-connected = "󰂱";
            min-length = 2;
            max-length = 2;
            on-click = "ghostty -e ${scriptsDir}/bluetooth.sh";
            on-click-right = "bluetoothctl power off && notify-send 'Bluetooth Off' -i 'network-bluetooth-inactive' -r 1925";
            tooltip-format = "Device Addr: {device_address}";
            tooltip-format-disabled = "Bluetooth Disabled";
            tooltip-format-off = "Bluetooth Off";
            tooltip-format-on = "Bluetooth Disconnected";
            tooltip-format-connected = "Device: {device_alias}";
            tooltip-format-enumerate-connected = "Device: {device_alias}";
            tooltip-format-connected-battery = "Device: {device_alias}\nBattery: {device_battery_percentage}%";
            tooltip-format-enumerate-connected-battery = "Device: {device_alias}\nBattery: {device_battery_percentage}%";
          };

          # System Update
          "custom/system_update" = {
            exec = "${scriptsDir}/system-update.sh module";
            return-type = "json";
            interval = 3600;
            format = "{}";
            min-length = 2;
            max-length = 2;
            on-click = "ghostty -e ${scriptsDir}/system-update.sh";
          };

          # MPRIS (Media Player)
          mpris = {
            format = "{player_icon} {title} - {artist}";
            format-paused = "{status_icon} {title} - {artist}";
            tooltip-format = "Playing: {title} - {artist}";
            tooltip-format-paused = "Paused: {title} - {artist}";
            player-icons = {
              default = "󰐊";
            };
            status-icons = {
              paused = "󰏤";
            };
            max-length = 1000;
          };

          # PulseAudio Group
          "group/pulseaudio" = {
            orientation = "horizontal";
            modules = [
              "pulseaudio#output"
              "pulseaudio#input"
            ];
            drawer = {
              transition-left-to-right = false;
            };
          };

          "pulseaudio#output" = {
            format = "{icon} {volume}%";
            format-muted = "{icon} {volume}%";
            format-icons = {
              default = [
                "󰕿"
                "󰖀"
                "󰕾"
              ];
              default-muted = "󰝟";
              headphone = "󰋋";
              headphone-muted = "󰟎";
              headset = "󰋎";
              headset-muted = "󰋐";
            };
            min-length = 7;
            max-length = 7;
            on-click = "${scriptsDir}/volume.sh output mute";
            on-scroll-up = "${scriptsDir}/volume.sh output raise";
            on-scroll-down = "${scriptsDir}/volume.sh output lower";
            tooltip-format = "Output Device: {desc}";
          };

          "pulseaudio#input" = {
            format = "{format_source}";
            format-source = "󰍬 {volume}%";
            format-source-muted = "󰍭 {volume}%";
            min-length = 7;
            max-length = 7;
            on-click = "${scriptsDir}/volume.sh input mute";
            on-scroll-up = "${scriptsDir}/volume.sh input raise";
            on-scroll-down = "${scriptsDir}/volume.sh input lower";
            tooltip-format = "Input Device: {desc}";
          };

          # Backlight
          backlight = {
            format = "{icon} {percent}%";
            format-icons = [
              ""
              ""
              ""
              ""
              ""
              ""
              ""
              ""
              ""
            ];
            min-length = 7;
            max-length = 7;
            on-scroll-up = "${scriptsDir}/backlight.sh up";
            on-scroll-down = "${scriptsDir}/backlight.sh down";
            tooltip = false;
          };

          # Battery
          battery = {
            states = {
              warning = 20;
              critical = 10;
            };
            format = "{icon} {capacity}%";
            format-time = "{H} hr {M} min";
            format-icons = [
              "󰂎"
              "󰁻"
              "󰁼"
              "󰁽"
              "󰁾"
              "󰁿"
              "󰂀"
              "󰂁"
              "󰂂"
              "󰁹"
            ];
            format-charging = "󰉁 {capacity}%";
            min-length = 7;
            max-length = 7;
            tooltip-format = "Discharging: {time}";
            tooltip-format-charging = "Charging: {time}";
          };

          # Power Menu
          "custom/power_menu" = {
            format = "󰤄";
            on-click = "wlogout";
            tooltip-format = "Power Menu";
          };
        };
      };
    };
  };
}
