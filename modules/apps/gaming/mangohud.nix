{ mkModule, ... }:

mkModule {
  name = "mangohud";
  category = "gaming";
  packages = { pkgs, ... }: [ pkgs.mangohud ];
  description = "MangoHud performance overlay";
}
