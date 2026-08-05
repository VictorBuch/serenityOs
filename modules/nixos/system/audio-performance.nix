{
  config,
  lib,
  inputs,
  ...
}:

# Realtime tuning for audio work, via musnix on the STOCK kernel.
#
# Deliberately no `musnix.kernel.realtime`: a PREEMPT_RT kernel means building (or at
# least fetching) a separate kernel on every nixpkgs bump, and it breaks the DKMS/ZFS-ish
# out-of-tree modules a desktop tends to carry. `threadirqs` plus prioritised IRQ threads
# plus the rlimits is enough to hold a 128-frame quantum in REAPER without xruns.
#
# This lives in modules/nixos/ rather than modules/apps/ on purpose: modules/apps/ is
# imported by mal (homelab) and inara (darwin), and neither may ever see musnix.* options.
# The import here is unconditional -- it has to be, since a `musnix.enable` definition
# needs the option declared even when it is guarded by mkIf -- so every host that imports
# modules/nixos/ carries musnix's option declarations. Only jayne turns it on.
{
  imports = [ inputs.musnix.nixosModules.default ];

  options.audio-performance.enable = lib.mkEnableOption ''
    musnix realtime tuning on the stock kernel: the threadirqs boot parameter, rtirq
    IRQ-thread priorities, @audio rlimits, and the performance CPU governor.

    Note this makes the performance governor system-wide, not just while a DAW is
    running -- musnix sets powerManagement.cpuFreqGovernor without mkDefault, so it
    overrides the schedutil default from modules/nixos/system/amd-gpu.nix
  '';

  config = lib.mkIf config.audio-performance.enable {
    musnix.enable = true;

    # Raise the audio interface's IRQ thread above the rest. Defaults cover the
    # "snd usb i8042" IRQ names, which is what an onboard/USB interface shows up as.
    musnix.rtirq.enable = true;
  };
}
