{
  config,
  lib,
  ...
}:
{
  options = {
    home.zen-browser.enable = lib.mkEnableOption "Enables Zen browser home manager";
  };

  config = lib.mkIf config.home.zen-browser.enable {
    programs.zen-browser = {
      enable = true;

      profiles.${config.home.username} = {
        # Default profile using the username
      };
    };

    stylix.targets.zen-browser.profileNames = [ config.home.username ];
  };
}
