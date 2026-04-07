{ mkModule, ... }:

mkModule {
  name = "linux";
  category = "emacs";
  linuxPackages = { pkgs, ... }: [ ]; # Emacs daemon enabled via services.emacs
  description = "Emacs daemon service (Linux only)";
  linuxExtraConfig = {
    services.emacs.enable = true;
  };
}
