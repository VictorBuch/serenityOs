args@{
  mkModule,
  ...
}:

mkModule {
  name = "language-learning";
  category = "productivity";
  packages =
    { pkgs, ... }:
    [
      pkgs.anki
    ];
  description = "Language learning apps (Anki)";
} args
