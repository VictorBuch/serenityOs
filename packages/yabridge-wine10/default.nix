# yabridge built against wine 11, for apps.audio.reaper.wineTrack = "modern".
#
# Released yabridge (5.1.1) cannot embed plugin editors under wine 10/11; the fix lives on
# the unreleased `new-wine10-embedding` branch:
#   https://github.com/robbert-vdh/yabridge/issues/409
#
# Rather than vendoring nixpkgs' package.nix and its patches -- which would silently drift
# from nixpkgs -- this overrides the real package. The two things that have to change are
# the source (branch commit instead of the 5.1.1 tag) and the wine it is linked against.
# The latter matters more than it looks: yabridge's plugin hosts run under their
# build-time wine, so `wineWow64Packages.yabridge` (9.21) IS the version bridged plugins
# see, no matter what WINELOADER says at runtime.
#
# The wine version is passed through the same `wineWow64Packages` argument nixpkgs uses,
# so it reaches both `hardcode-dependencies.patch` (via replaceVars) and the postFixup
# that rewrites winegcc's WINELOADER. Substituting only one of those is what broke
# previous attempts at this.
#
# Returns yabridge, with the matching yabridgectl as passthru.

{
  lib,
  fetchFromGitHub,
  rustPlatform,
  yabridge,
  yabridgectl,
  wineAudioModern,
}:

let
  # github.com/robbert-vdh/yabridge, branch new-wine10-embedding
  rev = "ba7022df0aee1e91cde62d7f0e940d3bc43a82b0";
  version = "5.1.1-unstable-2026-01-21";

  src = fetchFromGitHub {
    owner = "robbert-vdh";
    repo = "yabridge";
    inherit rev;
    hash = "sha256-0ju/mfmhutuuPezq1GhiAEiQV/gnfEbrhjX4ydxLX+A=";
  };

  # nixpkgs carries an upstream cherry-pick dropping 32-bit libyabridge support. The
  # branch already contains that commit, so applying it again fails. Drop it by name and
  # assert we dropped exactly one, so a nixpkgs restructure fails loudly here instead of
  # silently building something else.
  dropped = "libyabridge-drop-32-bit-support";
  keepPatch = p: !(lib.hasInfix dropped (toString p));

  yabridge-wine10 =
    (yabridge.override {
      # Only `.yabridge` is read out of this, in two places.
      wineWow64Packages = {
        yabridge = wineAudioModern;
      };
    }).overrideAttrs
      (old: {
        inherit src version;
        # Tracking a branch, not a tag; the version bump is the point.
        __intentionallyOverridingVersion = true;

        patches =
          assert lib.assertMsg (lib.length (lib.filter (p: !keepPatch p) old.patches) == 1)
            "yabridge-wine10: expected exactly one '${dropped}' patch in nixpkgs' yabridge; the patch set changed";
          lib.filter keepPatch old.patches;

        passthru = {
          yabridgectl = yabridgectl-wine10;
          wine = wineAudioModern;
        };

        meta = old.meta // {
          description = "${old.meta.description} (wine 10/11 embedding branch)";
          changelog = "https://github.com/robbert-vdh/yabridge/blob/${rev}/CHANGELOG.md";
        };
      });

  yabridgectl-wine10 =
    (yabridgectl.override {
      yabridge = yabridge-wine10;
      wineWow64Packages = {
        yabridge = wineAudioModern;
      };
    }).overrideAttrs
      (old: {
        inherit version;
        # Tracking a branch, not a tag; the version bump is the point.
        __intentionallyOverridingVersion = true;

        # buildRustPackage turns `cargoHash` into `cargoDeps` before overrideAttrs can see
        # it, so re-derive the vendor directory for the branch's Cargo.lock by hand.
        cargoDeps = rustPlatform.fetchCargoVendor {
          inherit src;
          sourceRoot = "${src.name}/tools/yabridgectl";
          hash = "sha256-VcBQxKjjs9ESJrE4F1kxEp4ah3j9jiNPq/Kdz/qPvro=";
        };
      });
in
yabridge-wine10
