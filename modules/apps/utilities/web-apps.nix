args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "web-apps";
  packages = pkgs: [ ];
  description = "Web desktop apps (PWAs)";
  extraConfig = {
    home-manager.users.${config.user.userName} =
      let
        browser = "${pkgs.chromium}/bin/chromium --enable-features=UseOzonePlatform --ozone-platform=wayland";
      in
      {
        xdg.desktopEntries = {
        youtube = {
          name = "YouTube";
          genericName = "Video Platform";
          exec = "${browser} --app=https://youtube.com --no-first-run --disable-default-apps";
          icon = "youtube";
          categories = [
            "Network"
            "AudioVideo"
          ];
          terminal = false;
          settings = {
            StartupWMClass = "youtube.com";
          };
        };

        mynixos = {
          name = "MyNixOS";
          genericName = "NixOS Configuration Search";
          exec = "${browser} --app=https://mynixos.com --no-first-run --disable-default-apps";
          icon = "nix-snowflake";
          categories = [
            "Development"
            "Documentation"
          ];
          terminal = false;
          settings = {
            StartupWMClass = "mynixos.com";
          };
        };

        protonmail = {
          name = "Proton Mail";
          genericName = "Email Client";
          exec = "${browser} --app=https://mail.proton.me --no-first-run --disable-default-apps";
          icon = "mail";
          categories = [
            "Network"
            "Email"
          ];
          terminal = false;
          settings = {
            StartupWMClass = "mail.proton.me";
          };
        };

        claude = {
          name = "Claude";
          genericName = "AI Assistant";
          exec = "${browser} --app=https://claude.ai --no-first-run --disable-default-apps";
          icon = "applications-science";
          categories = [
            "Network"
            "Utility"
          ];
          terminal = false;
          settings = {
            StartupWMClass = "claude.ai";
          };
        };

        github = {
          name = "GitHub";
          genericName = "Code Hosting Platform";
          exec = "${browser} --app=https://github.com --no-first-run --disable-default-apps";
          icon = "github";
          categories = [
            "Development"
            "Network"
          ];
          terminal = false;
          settings = {
            StartupWMClass = "github.com";
          };
        };

        nixpkgs = {
          name = "NixOS Packages";
          genericName = "Package Search";
          exec = "${browser} --app=https://search.nixos.org/packages --no-first-run --disable-default-apps";
          icon = "nix-snowflake";
          categories = [
            "Development"
            "Documentation"
          ];
          terminal = false;
          settings = {
            StartupWMClass = "search.nixos.org";
          };
        };

        nixoptions = {
          name = "NixOS Options";
          genericName = "NixOS Options Search";
          exec = "${browser} --app=https://search.nixos.org/options --no-first-run --disable-default-apps";
          icon = "nix-snowflake";
          categories = [
            "Development"
            "Documentation"
          ];
          terminal = false;
          settings = {
            StartupWMClass = "search.nixos.org";
          };
        };

        tidal = {
          name = "Tidal";
          genericName = "Music Streaming";
          exec = "${browser} --app=https://listen.tidal.com --no-first-run --disable-default-apps";
          icon = "tidal";
          categories = [
            "AudioVideo"
            "Audio"
            "Music"
          ];
          terminal = false;
          settings = {
            StartupWMClass = "listen.tidal.com";
          };
        };
      };
    };
  };
} args
