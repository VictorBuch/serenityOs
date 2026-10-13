args@{
  config,
  pkgs,
  lib,
  mkModule,
  ...
}:

mkModule {
  name = "claude";
  category = "development";
  description = "Claude Code skills and user CLAUDE.md";
  homeConfig =
    { lib, ... }:
    let
      # One dir per account: default, claudew, claudep (see nushell.nix).
      configDirs = [
        ".claude"
        ".claude-work"
        ".claude-personal"
      ];
      skills = builtins.attrNames (builtins.readDir ./claude/skills);
    in
    {
      home.file = {
        ".claude/CLAUDE.md".source = ./claude/CLAUDE.md;
      }
      // lib.listToAttrs (
        lib.concatMap (
          dir:
          map (skill: lib.nameValuePair "${dir}/skills/${skill}" { source = ./claude/skills/${skill}; }) skills
        ) configDirs
      );
    };
} args
