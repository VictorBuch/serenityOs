{ inputs, ... }:
let
  module =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
in
{
  flake.modules.nixos.zen = module;
  flake.modules.darwin.zen = module;
  flake.modules.homeManager.zen =
    {
      config,
      lib,
      ...
    }:
    {
      programs.zen-browser = {
        enable = true;
        profiles.${config.home.username} =
          let
            sheet =
              name: ''@import url("file://${config.xdg.cacheHome}/noctalia/zen-browser/zen-${name}.css");'';
          in
          {
            userChrome = sheet "userChrome";
            userContent = sheet "userContent";
            settings = {
              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
              "zen.view.window.scheme" = 0;
            }
            // lib.optionalAttrs (config ? stylix) {
              "font.name.monospace.x-western" = config.stylix.fonts.monospace.name;
              "font.name.sans-serif.x-western" = config.stylix.fonts.sansSerif.name;
              "font.name.serif.x-western" = config.stylix.fonts.serif.name;
            };
          };
      };
    };
}
