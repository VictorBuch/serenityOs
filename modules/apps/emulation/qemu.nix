{ mkModule, ... }:

mkModule {
  name = "qemu";
  category = "emulation";
  packages = { pkgs, ... }: [
    pkgs.qemu
    pkgs.quickemu
    pkgs.quickgui
  ];
  description = "QEMU virtualization with quickemu and quickgui";
}
