{
  flake.modules.nixos.agent-browser =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.agent-browser
        pkgs.chromium
      ];
    };
  flake.modules.homeManager.agent-browser =
    # Point agent-browser at the Nix chromium instead of letting
    # `agent-browser install` download a Chrome that won't run on NixOS.
    { pkgs, ... }:
    {
      home.sessionVariables.AGENT_BROWSER_EXECUTABLE_PATH = "${pkgs.chromium}/bin/chromium";
    };
}
