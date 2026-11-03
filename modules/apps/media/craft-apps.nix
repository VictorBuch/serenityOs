args@{
  config,
  pkgs,
  lib,
  mkModule,
  ...
}:

mkModule {
  name = "craft-apps";
  category = "media";
  platforms = [ "linux" ];
  packages = { pkgs, lib, ... }: lib.filter lib.isDerivation (builtins.attrValues pkgs.craft-apps);
  description = "storytold Craft apps: PhotoCraft, FilmCraft, LightCraft, PdfCraft, FigCraft, VectorCraft, EffectCraft";
} args
