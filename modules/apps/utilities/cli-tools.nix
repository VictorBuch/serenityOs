let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.pam-cli
        pkgs.yt-dlp
      ];
    };
in
{
  flake.modules.nixos.cli-tools = module;
  flake.modules.darwin.cli-tools = module;
}
