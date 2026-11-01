args@{
  config,
  pkgs,
  lib,
  mkModule,
  ...
}:

mkModule {
  name = "eden";
  category = "gaming";
  packages = { pkgs, ... }: [ pkgs.eden ];
  description = "Nintendo switch emulation";
} args
