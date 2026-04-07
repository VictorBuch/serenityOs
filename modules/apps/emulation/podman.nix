{ mkModule, ... }:

mkModule {
  name = "podman";
  category = "emulation";
  linuxPackages = { pkgs, ... }: [ ]; # Podman enabled via virtualisation.podman
  description = "Podman container engine (Linux only)";
  linuxExtraConfig = {
    virtualisation.containers.enable = true;
    virtualisation.podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
