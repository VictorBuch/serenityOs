{
  config,
  pkgs,
  lib,
  isLinux,
  ...
}:

let
  user = if (config ? user.userName) then config.user.userName else "victorbuch";
  homeDir = if isLinux then "/home" else "/Users";
  flakePath = "${homeDir}/${user}/nixos";
in

{
  options = {
    nh.enable = lib.mkEnableOption "Enables nh";
  };

  config = lib.mkIf config.nh.enable {

    # environment.variables works on both NixOS and Darwin
    environment.variables = {
      NH_FLAKE = flakePath;
      NH_DARWIN_FLAKE = flakePath; # Darwin-specific variable
    };

    environment.systemPackages = with pkgs; [
      nh
    ];

  };

}
