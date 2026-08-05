# Wine/yabridge track definitions, shared by reaper.nix and yabridge.nix.
#
# Underscore-prefixed, so import-tree skips it -- this is a plain function, not a module.
# Import it explicitly:  import ./_wine-tracks.nix { inherit pkgs pkgs-stable; }
#
# Why a matched pair: yabridge's plugin hosts run under whatever wine the yabridge *build*
# was linked against. nixpkgs hardcodes it via hardcode-dependencies.patch plus a postFixup
# that rewrites the winegcc wrapper, so setting WINELOADER in the environment only affects
# installers and standalone apps, never the bridged plugins. Wine and yabridge therefore
# have to be chosen together, and switching is a rebuild rather than a runtime flag: the
# chainloaders in ~/.local/share/yabridge can only point at one build at a time.
#
# Selected by apps.audio.reaper.wineTrack. Both tracks share WINEPREFIX=~/.wine-audio, so
# iLok and IK activations survive a switch.

{ pkgs, pkgs-stable }:

{
  # Wine 9.20 + yabridge 5.1.1 from stable. yabridge 5.1.1 requires wine <= 9.21, and
  # 9.22+ breaks plugin GUIs outright: https://github.com/robbert-vdh/yabridge/issues/382
  pinned = {
    wine = pkgs.wineAudioPinned;
    yabridge = pkgs-stable.yabridge;
    yabridgectl = pkgs-stable.yabridgectl;
    # 25.11's yabridge still builds the 32-bit bitbridge host; unstable's does not.
    has32bitHost = true;
  };

  # Wine 11 + yabridge's unreleased new-wine10-embedding branch (packages/yabridge-wine10).
  # Experimental: reportedly much better on wine 11, but has a known cursor-offset quirk.
  # https://github.com/robbert-vdh/yabridge/issues/409
  modern = {
    wine = pkgs.wineAudioModern;
    yabridge = pkgs.yabridge-wine10;
    yabridgectl = pkgs.yabridgectl-wine10;
    # Built from unstable's expression, which passes -Dbitbridge=false and installs only
    # the 64-bit host. 32-bit Windows plugins cannot be bridged on this track.
    has32bitHost = false;
  };
}
