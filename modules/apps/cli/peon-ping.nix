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
  homeConfig =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      home.packages = [ pkgs.python3 ];

      programs.peon-ping = {
        enable = true;
        package = inputs.peon-ping.packages.${pkgs.stdenv.hostPlatform.system}.default;

        settings = {
          default_pack = "peon";
          active_pack = "jarvis";
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
