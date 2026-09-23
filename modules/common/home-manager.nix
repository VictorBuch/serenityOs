{
  config,
  inputs,
  pkgs-stable,
  ...
}:
let
  username = config.user.userName;
in
{
  assertions = [
    {
      assertion = username != "default";
      message = "user.userName is unset; set it in hosts/<name>/configuration.nix so Home Manager knows which user to build.";
    }
  ];

  home-manager = {
    useGlobalPkgs = true;
    backupFileExtension = "hm-backup";
    extraSpecialArgs = {
      inherit username inputs pkgs-stable;
    };
    users.${username} = import ../../home/default.nix;
  };
}
