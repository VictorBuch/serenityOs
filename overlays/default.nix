{
  inputs,
  ...
}:
final: prev: {
  # AI coding agents from numtide/llm-agents.nix
  llm-agents = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system};

  # nixCats-style wrapped neovim. Module + lua live in modules/apps/neovim/_nixcats/.
  nixcatsNeovim =
    let
      module = final.lib.modules.importApply ../modules/apps/neovim/_nixcats/module.nix inputs;
      wrapper = inputs.nix-wrapper-modules.lib.evalModule module;
    in
    wrapper.config.wrap { pkgs = final; };

  # Herdr: mouse-first terminal multiplexer (flake ships only a package)
  herdr = inputs.herdr.packages.${final.stdenv.hostPlatform.system}.default;

  # Add the pam package (renamed to avoid conflict with linux-pam)
  pam-cli = final.callPackage ../packages/pam { };

  # Lute v3 - language learning web application
  lute-v3 = final.callPackage ../packages/lute-v3 { };

  # === Audio wine tracks (see modules/apps/audio/reaper.nix, apps.audio.reaper.wineTrack) ===
  #
  # "pinned" track. Wine 9.20 stagingFull from the nixpkgs-wine920 input. This is the
  # default because yabridge 5.1.1 (the last release) requires wine <= 9.21, and 9.22+
  # breaks plugin GUIs outright: https://github.com/robbert-vdh/yabridge/issues/382
  # stagingFull pulls in the full set of optional deps for maximum installer compatibility.
  #
  # NOTE: the plugin *hosts* run under whatever wine yabridge was built against, not this
  # one -- nixpkgs' yabridge hardcodes its wine via hardcode-dependencies.patch plus a
  # postFixup that rewrites the winegcc wrapper. This attr is what installers, winetricks
  # and the audio-wine helper use, and it must stay version-matched to the yabridge build
  # so both halves agree on the prefix layout.
  wineAudioPinned =
    let
      wine920Pkgs = import inputs.nixpkgs-wine920 {
        system = final.stdenv.hostPlatform.system;
        config = {
          allowUnfree = true;
        };
      };
    in
    wine920Pkgs.wineWowPackages.stagingFull;

  # "modern" track. Current unstable wine staging (11.x). Only usable together with the
  # yabridge new-wine10-embedding branch (packages/yabridge-wine10), which is the only
  # version that can embed plugin editors under wine 10/11:
  # https://github.com/robbert-vdh/yabridge/issues/409
  # wineWow64Packages, not the deprecated wineWowPackages alias.
  wineAudioModern = final.wineWow64Packages.stagingFull;

  # The other half of the "modern" track. Built on the unstable toolchain (not
  # pkgs-stable) -- the wineg++/meson cross-build is sensitive to the wine it is pointed
  # at, and mixing channels is what broke earlier attempts to swap yabridge's wine.
  yabridge-wine10 = final.callPackage ../packages/yabridge-wine10 { };
  yabridgectl-wine10 = final.yabridge-wine10.yabridgectl;

  # xdg-desktop-portal-wlr 0.8.3 stalls screencasts after the first frame: sharing a
  # screen shows a frozen still, sharing a window stays black. Upstream's own 0.8.3
  # release notes say "This version will sometimes stall screen recording. Please wait
  # for the next patch release before upgrading."
  #
  # 0.8.3 contains exactly one functional commit, c613a8b "screencast: drive the
  # Pipewire graph by ourselves", which is the regression. Traced on jayne/mango as:
  # one frame exported, then `pipewire: out of buffers` / `unable to export buffer`
  # and no further capture. Not compositor-specific — grim and wf-recorder are fine
  # because they use wlr-screencopy, while the portal takes the ext-image-copy-capture
  # path that 0.8.3 broke, and there is no config switch between the two.
  #
  # Pin to v0.8.2, the last release before that commit. It still carries 896cee8
  # "Fix screensharing on pipewire 1.6.x", which we need (system runs PipeWire 1.6.8).
  # master (544e114) only adds a guard on top of the regression instead of reverting
  # it, so it is not a safe target yet.
  #
  # Drop this once nixpkgs ships the upstream patch release that fixes the stall.
  xdg-desktop-portal-wlr = prev.xdg-desktop-portal-wlr.overrideAttrs (_old: {
    version = "0.8.2";
    src = final.fetchFromGitHub {
      owner = "emersion";
      repo = "xdg-desktop-portal-wlr";
      rev = "01171a150b705cf07066ebc0fb7e1ff537027bec";
      hash = "sha256-HITf/hgiASWvn/z49mzS8IS1vuyXwdk1JiAOOHRSQMo=";
    };
  });

  # DaVinci Resolve Studio: byte-level patches to the shipped binaries.
  #
  # bin/resolve lives in the inner `stdenv.mkDerivation` that package.nix binds
  # in a `let`; the buildFHSEnv wrapper only references its store path. That
  # inner derivation isn't exposed via .override, but `stdenv` is — so wrap
  # mkDerivation to append the patches to postFixup.
  #
  # These patterns are matched against one specific build, so every one carries
  # an exact-hit-count guard: a Resolve version bump fails the build loudly
  # instead of silently shipping an unpatched binary.
  davinci-resolve-studio =
    let
      inherit (final.lib)
        all
        assertMsg
        concatMapStrings
        concatStrings
        groupBy
        mapAttrsToList
        ;

      # Each entry is one byte substitution. To add another, append an attrset:
      #
      #   {
      #     name = "short-kebab-case-label";   # spliced into the failure message
      #     find = ''\x48\x8B\x45\xC8'';       # perl regex source, see below
      #     replace = ''\x48\x8B\x45\xC0'';    # MUST be the same byte length
      #     file = "bin/resolve";              # optional, this is the default
      #     count = 1;                         # optional, expected hit count
      #   }
      #
      # `find` and `replace` are spliced verbatim into a perl s///, so they are
      # regex/replacement *source*, not literals: write raw bytes as \xNN, and
      # `.` `(` `)` `$1` behave as regex metacharacters. Constraints:
      #   - no literal `/` (it is the delimiter) — use \x2F
      #   - no literal `'` anywhere (the program is a single-quoted shell arg)
      #   - find and replace must expand to the same byte length; the generated
      #     script asserts this, because an s/// of unequal length shifts every
      #     later byte and silently destroys the ELF
      # All patches for one file run as a single -0777 (slurp) pass in list
      # order, so \x0A is fine in a pattern and `.` never has to cross a line
      # boundary — but a later patch sees the output of the earlier ones.
      patches = [
        # Two sites, 0x37 bytes apart, both:
        #   call <init>; mov %eax,-0x4(%rbp); cmpl $0x0,-0x4(%rbp); je +0x11
        # where the not-taken path does ctx->err = ret; return 0. 74 -> EB
        # (je -> jmp) skips both bail-outs and continues as if the calls had
        # succeeded. .text vaddr 0x97e0741 and 0x97e0778.
        #
        # This subsumes the narrower \x03\x00\x89\x45... form of the same patch,
        # which anchored on the preceding call's rel32 tail to hit only the
        # first site. count = 2 is the stronger guard: it fails the build if
        # either site drifts, where two separate count = 1 entries would not.
        {
          name = "skip-error-bailouts";
          find = ''\x74\x11\x48\x8B\x45\xC8\x8B\x55\xFC\x89\x50\x58\xB8\x00\x00\x00'';
          replace = ''\xEB\x11\x48\x8B\x45\xC8\x8B\x55\xFC\x89\x50\x58\xB8\x00\x00\x00'';
          count = 2;
        }

        # .text vaddr 0xddcd08:
        #   test %bpl,%bpl; je +0x19; mov $0x16,%edi; mov $0x13f,%esi;
        #   call <report>; mov $0xffffffff,%eax; jmp <epilogue>
        # 74 -> 75 (je -> jne) inverts the guard, so the report(0x16=EINVAL,
        # 0x13f) / return -1 path is taken when the flag is clear rather than
        # set. The two `.` wildcards are the jump displacement and the low byte
        # of $0x13f; $1 carries the matched bytes through unchanged.
        {
          name = "invert-einval-guard";
          find = ''\x74(.\xBF\x16\x00\x00\x00\xBE.\x01\x00\x00\xE8..\x05)'';
          replace = ''\x75$1'';
        }
      ];

      expect = p: toString (p.count or 1);

      mkSub = p: ''
          $n = s/${p.find}/${p.replace}/g || 0;
          die "  patch ${p.name}: matched $n site(s), want ${expect p}\n" unless $n == ${expect p};
      '';

      # One slurp pass per file: read once, apply every substitution in order,
      # verify the length is untouched, then let -i rename the result into
      # place (which also avoids needing write permission on the 0555 binary).
      patchFile = file: ps: ''
        echo "patching $out/${file} (${toString (builtins.length ps)} patches)"
        perl -0777 -pi -e 'my $len = length($_); my $n;
        ${concatMapStrings mkSub ps}
          my $end = length($_);
          die "  byte length changed: $len -> $end (find/replace differ in length)\n" unless $end == $len;' \
          "$out/${file}"
      '';
    in
    assert assertMsg (all (p: builtins.match "[a-z0-9-]+" p.name != null) patches)
      "davinci-resolve-studio: patch names must be kebab-case (they are spliced into a perl string)";
    prev.davinci-resolve-studio.override {
      stdenv = prev.stdenv // {
        mkDerivation =
          attrs:
          (prev.stdenv.mkDerivation attrs).overrideAttrs (old: {
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.perl ];
            postFixup =
              (old.postFixup or "")
              + concatStrings (mapAttrsToList patchFile (groupBy (p: p.file or "bin/resolve") patches));
          });
      };
    };
}
