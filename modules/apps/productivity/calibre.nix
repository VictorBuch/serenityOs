args@{
  mkModule,
  ...
}:

mkModule {
  name = "calibre";
  category = "productivity";
  packages =
    { pkgs, ... }: [ pkgs.calibre ];
  description = "calibre";
} args
