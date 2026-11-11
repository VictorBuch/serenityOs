let
  module =
    {
      config,
      pkgs,
      lib,
      ...
    }:

    let
      isLinux = pkgs.stdenv.hostPlatform.isLinux;
      user = if (config ? user.userName) then config.user.userName else "victorbuch";
      homeDir = if isLinux then "/home" else "/Users";
      flakePath = "${homeDir}/${user}/serenityOs";
    in

    {
      config = {

        # environment.variables works on both NixOS and Darwin
        environment.variables = {
          NH_FLAKE = flakePath;
          NH_DARWIN_FLAKE = flakePath; # Darwin-specific variable
        };

        environment.systemPackages = with pkgs; [
          nh
        ];

      };

    };
in
{
  flake.modules.nixos.base = module;
  flake.modules.darwin.base = module;
}
