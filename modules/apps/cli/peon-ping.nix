args@{
  config,
  pkgs,
  lib,
  mkModule,
  inputs,
  ...
}:

mkModule {
  name = "peon-ping";
  category = "cli";
  description = "Agent sound notifications (peon-ping)";
  extraConfig = {
    home-manager.sharedModules = [ inputs.peon-ping.homeManagerModules.default ];
  };
  homeConfig =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      home.packages = [
        pkgs.python3
        inputs.peon-ping.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];

      programs.peon-ping = {
        enable = true;
        package = inputs.peon-ping.packages.${pkgs.stdenv.hostPlatform.system}.default;

        settings = {
          default_pack = "jarvis";
          pack_rotation_mode = "session_override";
          pack_rotation = [
            "peon"
            "glados"
            "sc_kerrigan"
            "jarvis"
          ];
          volume = 0.7;
          enabled = true;
          desktop_notifications = true;
          categories = {
            "session.start" = true;
            "task.complete" = true;
            "task.error" = true;
            "input.required" = true;
            "resource.limit" = true;
            "user.spam" = false;
          };
        };

        installPacks = [
          "peon"
          "glados"
          "sc_kerrigan"
          {
            name = "jarvis";
            src = pkgs.fetchFromGitHub {
              owner = "FlynnCruse";
              repo = "openpeon-jarvis";
              rev = "307957814af48001f2b32c417acc89d222982ac9";
              hash = "sha256-SDelu1fhg2/JFKIQM4lSLevl7wMUBfuAFNOM/5gf8Mo=";
            };
          }
        ];

        enableZshIntegration = true;
      };
    };
} args
