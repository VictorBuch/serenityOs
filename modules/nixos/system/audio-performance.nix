{ inputs, ... }:
{
  flake.modules.nixos.audio-performance =
    {
      config,
      lib,
      ...
    }:

    # Realtime tuning for audio work, via musnix on the STOCK kernel.
    #
    # Deliberately no `musnix.kernel.realtime`: a PREEMPT_RT kernel means building (or at
    # least fetching) a separate kernel on every nixpkgs bump, and it breaks the DKMS/ZFS-ish
    # out-of-tree modules a desktop tends to carry. `threadirqs` plus prioritised IRQ threads
    # plus the rlimits is enough to hold a 128-frame quantum in REAPER without xruns.
    #
    # This makes the performance governor system-wide, not just while a DAW is running:
    # musnix sets powerManagement.cpuFreqGovernor without mkDefault, so it overrides the
    # schedutil default from modules/nixos/system/amd-gpu.nix.
    {
      imports = [ inputs.musnix.nixosModules.default ];

      config = {
        musnix.enable = true;

        # Raise the audio interface's IRQ thread above the rest. Defaults cover the
        # "snd usb i8042" IRQ names, which is what an onboard/USB interface shows up as.
        musnix.rtirq.enable = true;

        services.power-profiles-daemon.enable = lib.mkForce false;
      };
    };
}
