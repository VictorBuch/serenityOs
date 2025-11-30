{ config, lib, ... }:
let
  iconDir = ./icons;
in

{

  options = {
    home.desktop-environments.common.wlogout.enable = lib.mkEnableOption "Enables wlogout home manager";
  };

  config = lib.mkIf config.home.desktop-environments.common.wlogout.enable {
      programs.wlogout = {
      enable = true;
      style = ''
        * {
          box-shadow: none;
        }

        window {
          background-image: linear-gradient(rgba(0, 0, 0, 0.25), rgba(0, 0, 0, 0.25)), url("${config.wallpaper}");
          background-size: cover;
          background-position: center;
          background-repeat: no-repeat;
        }

        button {
          border-radius: 0;
          border-color: #89b4fa;
          text-decoration-color: #cdd6f4;
          color: #cdd6f4;
          background-color: rgba(0, 0, 0, 0.5);
          border-style: solid;
          border-width: 1px;
          background-repeat: no-repeat;
          background-position: center;
          background-size: 25%;
        }

        button:focus, button:active, button:hover {
          background-color: rgba(0, 0, 0, 0.8);
          outline-style: none;
        }
        #lock {
            background-image: url("${iconDir}/lock.svg");
        }

        #logout {
            background-image: url("${iconDir}/logout.svg");
        }

        #suspend {
            background-image: url("${iconDir}/suspend.svg");
        }

        #hibernate {
            background-image: url("${iconDir}/hibernate.svg");
        }

        #shutdown {
            background-image: url("${iconDir}/shutdown.svg");
        }

        #reboot {
            background-image: url("${iconDir}/reboot.svg");
        }
      '';

      layout = [
        {
          label = "lock";
          text = "Lock";
          action = "hyprlock";
          keybind = "l";
        }
        {
          label = "hibernate";
          text = "Hibernate";
          action = "systemctl hibernate";
          keybind = "h";
        }
        {
          label = "suspend";
          text = "Suspend";
          action = "loginctl suspend";
          keybind = "s";
        }
        {
          label = "reboot";
          text = "Reboot";
          action = "systemctl reboot";
          keybind = "r";
        }
        {
          label= "logout";
          text= "Logout";
          action= "niri msg action quit --skip-confirmation";
          keybind= "t";
        }
        {
          label = "shutdown";
          text = "Shutdown";
          action = "systemctl poweroff";
          keybind = "p";
        }

      ];
    };
  };
}
