args@{
  mkModule,
  ...
}:

mkModule {
  name = "fladder";
  category = "media";
  packages = { pkgs, ... }: [ pkgs.fladder ];
  description = "Jellyfin video client";
} args
