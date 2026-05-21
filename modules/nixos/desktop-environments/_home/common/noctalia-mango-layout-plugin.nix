{
  config,
  pkgs,
  lib,
  ...
}:
let
  optPath = [ "home" "desktop-environments" "common" "mango-layout-plugin" ];
  cfg = lib.attrByPath optPath { enable = false; } config;

  # Upstream community plugins repo. Pin to a known-good commit.
  pluginsRepo = pkgs.fetchFromGitHub {
    owner = "noctalia-dev";
    repo = "noctalia-plugins";
    rev = "1b0008f8d6fe43db142b78919eec4a709806b1df";
    sha256 = "0yhfg5hmxvyn0gjcnf0gb3fx2kvhc8n4cxk5l290bpmix8ars3q6";
  };
in
{
  options = lib.setAttrByPath (optPath ++ [ "enable" ]) (
    lib.mkEnableOption "Noctalia mangowc-layout-switcher community plugin"
  );

  config = lib.mkIf cfg.enable {
    xdg.configFile."noctalia/plugins/mangowc-layout-switcher".source =
      "${pluginsRepo}/mangowc-layout-switcher";
  };
}
