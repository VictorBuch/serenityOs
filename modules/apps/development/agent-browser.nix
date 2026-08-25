args@{
  config,
  pkgs,
  lib,
  mkModule,
  ...
}:

mkModule {
  name = "agent-browser";
  platforms = [ "linux" ];
  category = "development";
  description = "Browser automation CLI for AI agents";
  packages =
    { pkgs, ... }:
    [
      pkgs.agent-browser
      pkgs.chromium
    ];
  # Point agent-browser at the Nix chromium instead of letting
  # `agent-browser install` download a Chrome that won't run on NixOS.
  homeConfig =
    { pkgs, ... }:
    {
      home.sessionVariables.AGENT_BROWSER_EXECUTABLE_PATH = "${pkgs.chromium}/bin/chromium";
    };
} args
