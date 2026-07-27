{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Monospace font presets. Switch the active font by setting
  # `fonts.mono.preset` to one of these keys (default below).
  monoPresets = {
    maple-mono = {
      package = pkgs.maple-mono.NF;
      family = "Maple Mono NF";
      familyMono = "Maple Mono NF";
    };
    jetbrains-mono = {
      package = pkgs.nerd-fonts.jetbrains-mono;
      family = "JetBrainsMono Nerd Font";
      familyMono = "JetBrainsMono Nerd Font Mono";
    };
  };
  selected = monoPresets.${config.fonts.mono.preset};
in
{

  options = {
    fonts.enable = lib.mkEnableOption "Enable custom fonts";

    fonts.mono = {
      preset = lib.mkOption {
        type = lib.types.enum (builtins.attrNames monoPresets);
        default = "maple-mono";
        description = "Active monospace font preset. Switch fonts here.";
      };
      package = lib.mkOption {
        type = lib.types.package;
        readOnly = true;
        default = selected.package;
        description = "Resolved monospace font package (from preset).";
      };
      family = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        default = selected.family;
        description = "Resolved monospace font family name (from preset).";
      };
      familyMono = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        default = selected.familyMono;
        description = "Resolved monospace (Mono) font family name (from preset).";
      };
    };
  };

  config = lib.mkIf config.fonts.enable {
    fonts.packages = [
      config.fonts.mono.package
    ];
  };
}
