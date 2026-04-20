args@{
  mkModule,
  ...
}:

mkModule {
  name = "logseq";
  category = "productivity";
  packages = { pkgs, ... }: [ pkgs.logseq ];
  description = "logseq note-taking app";
} args
