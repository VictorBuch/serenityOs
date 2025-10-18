{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.emulation.podman.enable = lib.mkEnableOption "Enables Podman";
  };

  config = lib.mkIf config.apps.emulation.podman.enable {
    virtualisation.containers.enable = true;
    virtualisation = {
      podman = {
        enable = true;

        # Create a `docker` alias for podman, to use it as a drop-in replacement
        dockerCompat = true;

        # Required for containers under podman-compose to be able to talk to each other.
        defaultNetwork.settings.dns_enabled = true;
      };
    };
  };
}
