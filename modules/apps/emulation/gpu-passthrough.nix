args@{ config, pkgs, lib, mkModule, ... }:

let
  username = config.user.userName;

  # PCI addresses for RX 7900 XT (verified on jayne)
  gpuPci = "0000:03:00.0";
  gpuAudioPci = "0000:03:00.1";

  # PCI device IDs
  gpuId = "1002 744c";
  gpuAudioId = "1002 ab30";

  # VM name for which hooks fire
  vmName = "studio-vm";

  # Wrapper scripts: user is in libvirtd group, virsh talks to qemu:///system.
  # Run inside the user's Wayland session, so wlr-randr can drive the outputs.
  #   DP-1     = RX 7900 XT  → handed to the VM (vanishes from the compositor)
  #   HDMI-A-4 = iGPU HDMI    → the display we fall back to during Studio Mode
  wlrRandr = "${pkgs.wlr-randr}/bin/wlr-randr";
  studioStart = pkgs.writeShellScriptBin "studio-start" ''
    set -e
    # Bring the iGPU HDMI output up BEFORE the RX 7900 is yanked, so there is a
    # live display the moment DP-1 disappears. (Switch the monitor's physical
    # input to HDMI now — see docs/windows_VM.md "Daily Workflow".)
    ${wlrRandr} --output HDMI-A-4 --on --mode 2560x1440@59.951 --pos 0,0 || true
    STATE=$(${pkgs.libvirt}/bin/virsh -c qemu:///system domstate ${vmName} 2>/dev/null || echo missing)
    if [ "$STATE" != "running" ]; then
      ${pkgs.libvirt}/bin/virsh -c qemu:///system start ${vmName}
      sleep 3
    fi
    exec ${pkgs.looking-glass-client}/bin/looking-glass-client -F
  '';

  studioStop = pkgs.writeShellScriptBin "studio-stop" ''
    virsh() { ${pkgs.coreutils}/bin/timeout 20 ${pkgs.libvirt}/bin/virsh -c qemu:///system "$@"; }

    # Graceful ACPI shutdown, force destroy after 20s.
    # NOTE: a clean guest shutdown (Windows releases the GPU itself) is what lets
    # the RX 7900 rebind to amdgpu. A force-destroy of a *running* Windows can
    # trip the Navi 31 reset bug and wedge the vfio teardown in the kernel — an
    # unrecoverable hang that needs a reboot. Prefer shutting Windows down from
    # inside the guest, or via a working qemu guest agent, before running this.
    virsh shutdown ${vmName} 2>/dev/null || true
    for i in $(seq 1 20); do
      STATE=$(virsh domstate ${vmName} 2>/dev/null || echo "shut off")
      [ "$STATE" = "shut off" ] && break
      sleep 1
    done
    STATE=$(virsh domstate ${vmName} 2>/dev/null || echo "shut off")
    if [ "$STATE" != "shut off" ]; then
      echo "VM did not respond to ACPI shutdown, forcing destroy (reset-bug risk)"
      # timeout wraps virsh so a wedged libvirtd can't freeze this terminal;
      # it will NOT un-wedge a stuck GPU (that still needs a reboot).
      virsh destroy ${vmName} 2>/dev/null || true
    fi

    # The qemu release hook rebinds the RX 7900 to amdgpu in the background
    # (setsid + sleeps, ~5-8s). Wait for DP-1 to reappear, then restore the
    # normal-mode layout: DP-1 at 1440p@144, HDMI-A-4 off. (Switch the monitor's
    # physical input back to DP.)
    for i in $(seq 1 25); do
      ${wlrRandr} 2>/dev/null | grep -q '^DP-1' && break
      sleep 1
    done
    ${wlrRandr} --output DP-1 --on --mode 2560x1440@143.912 --pos 0,0 --output HDMI-A-4 --off || true
    echo "Studio Mode ended — restored DP-1 @ 1440p144"
  '';

  # libvirt qemu hook: dynamic GPU bind/unbind per VM lifecycle
  qemuHook = pkgs.writeShellScript "qemu-hook" ''
    #!/usr/bin/env bash
    # Do NOT set -e: individual bind/unbind ops may legitimately fail
    # (e.g. device already unbound). || true pattern handles each one.

    GUEST_NAME="$1"
    HOOK_NAME="$2"
    STATE_NAME="$3"

    # Only act on our studio VM
    [ "$GUEST_NAME" != "${vmName}" ] && exit 0

    GPU_PCI="${gpuPci}"
    AUDIO_PCI="${gpuAudioPci}"
    GPU_ID="${gpuId}"
    AUDIO_ID="${gpuAudioId}"

    if [ "$HOOK_NAME" = "prepare" ] && [ "$STATE_NAME" = "begin" ]; then
      # Unbind from host drivers
      [ -e "/sys/bus/pci/devices/$GPU_PCI/driver" ] && \
        echo "$GPU_PCI" > "/sys/bus/pci/devices/$GPU_PCI/driver/unbind" || true
      [ -e "/sys/bus/pci/devices/$AUDIO_PCI/driver" ] && \
        echo "$AUDIO_PCI" > "/sys/bus/pci/devices/$AUDIO_PCI/driver/unbind" || true

      # Load vfio-pci and claim devices
      modprobe vfio-pci
      echo "$GPU_ID"   > /sys/bus/pci/drivers/vfio-pci/new_id 2>/dev/null || true
      echo "$AUDIO_ID" > /sys/bus/pci/drivers/vfio-pci/new_id 2>/dev/null || true

      # Forbid D3cold on both functions — pairs with vfio-pci.disable_idle_d3=1.
      # Prevents the "power state D3(hot|cold) to D0, device inaccessible" hang
      # on reclaim by keeping the card powered.
      echo 0 > "/sys/bus/pci/devices/$GPU_PCI/d3cold_allowed"   2>/dev/null || true
      echo 0 > "/sys/bus/pci/devices/$AUDIO_PCI/d3cold_allowed" 2>/dev/null || true
    fi

    if [ "$HOOK_NAME" = "release" ] && [ "$STATE_NAME" = "end" ]; then
      # Run rebind in background — libvirt sandbox enforces hook timeout (~30s)
      # and amdgpu bind can block while GPU reinitializes. Detach via setsid+nohup.
      #
      # IMPORTANT: do NOT issue a manual PCI function-level reset here
      # (`echo 1 > .../reset`). On this Navi 31 card that raw FLR reliably HANGS
      # a kernel worker in D-state (unrecoverable without a reboot) — verified
      # 2026-07. amdgpu performs its own reset/init on bind, which is robust;
      # let it handle the reset. Also NOTE hostdevs are managed='no' so libvirt
      # does not also try to rebind (no race with this hook).
      setsid nohup sh -c "
        echo '$GPU_PCI'   > /sys/bus/pci/drivers/vfio-pci/unbind 2>/dev/null
        echo '$AUDIO_PCI' > /sys/bus/pci/drivers/vfio-pci/unbind 2>/dev/null
        echo '$GPU_ID'    > /sys/bus/pci/drivers/vfio-pci/remove_id 2>/dev/null
        echo '$AUDIO_ID'  > /sys/bus/pci/drivers/vfio-pci/remove_id 2>/dev/null

        # Let PCI state settle before binding amdgpu. Navi 3x PSP/SMU need a
        # brief quiet window after vfio releases them.
        sleep 2

        echo '$GPU_PCI'   > /sys/bus/pci/drivers/amdgpu/bind 2>/dev/null
        echo '$AUDIO_PCI' > /sys/bus/pci/drivers/snd_hda_intel/bind 2>/dev/null
      " </dev/null >/dev/null 2>&1 &
      disown
    fi
  '';
in
mkModule {
  name = "gpu-passthrough";
  platforms = [ "linux" ];
  category = "emulation";
  description = "Windows VM with GPU passthrough (Studio Mode)";

  packages = { pkgs, ... }: [
    pkgs.looking-glass-client
    pkgs.virt-manager
    pkgs.virt-viewer # standalone SPICE/VNC console
    pkgs.usbutils # lsusb for finding USB passthrough IDs
    pkgs.e2fsprogs # chattr for btrfs nodatacow on VM images
    pkgs.wlr-randr # display switching in studio-start/studio-stop
    studioStart
    studioStop
  ];

  extraConfig = {
    # IOMMU + VFIO kernel setup. pcie_aspm=off prevents AER errors on AMD.
    # amdgpu.runpm=0 disables dGPU runtime power management. Without this,
    # amdgpu cycles the RX 7900 XT through PSP/SMU suspend+resume when idle;
    # after enough cycles the SMU wedges ("SMU: I'm not done with your
    # previous command") and the fan pins at 100% because PWM control is
    # lost. Cost: ~15-25W extra idle draw. Benefit: GPU stays reachable.
    boot.kernelParams = [
      "amd_iommu=on"
      "iommu=pt"
      "pcie_aspm=off"
      "amdgpu.runpm=0"
      # Stop vfio-pci idling the card into D3 when no VM holds it. The reclaim
      # crash on this RX 7900 is a power-state failure ("Unable to change power
      # state from D3hot to D0, device inaccessible") + wedged SMU, NOT the FLR
      # silicon reset bug (resets complete) and NOT the kfd-disconnect kernel
      # regression (already fixed in 6.18.39 via pci_dev_is_disconnected).
      # disable_idle_d3 keeps the device in D0 so there is no failing D3->D0.
      "vfio-pci.disable_idle_d3=1"
    ];
    boot.kernelModules = [
      "vfio"
      "vfio_iommu_type1"
      "vfio_pci"
    ];
    # Ensure vfio-pci is loaded in initrd (before amdgpu claims anything static)
    boot.initrd.availableKernelModules = [ "vfio-pci" "vfio_iommu_type1" "vfio" ];

    # libvirt (OVMF/UEFI shipped with QEMU by default now)
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        runAsRoot = false;
        swtpm.enable = true; # TPM 2.0 emulation for Windows 11
        vhostUserPackages = [ pkgs.virtiofsd ];
      };
      onBoot = "ignore";
      onShutdown = "shutdown";
    };
    virtualisation.spiceUSBRedirection.enable = true;

    # virt-manager GUI
    programs.virt-manager.enable = true;

    # User permissions
    users.groups.libvirtd.members = [ username ];
    users.groups.kvm.members = [ username ];

    # Shared memory files for Looking Glass + Scream (IVSHMEM).
    # Looking Glass: 128MB sufficient for 4K; Scream: 2MB for audio stream.
    systemd.tmpfiles.rules = [
      "f /dev/shm/looking-glass 0660 ${username} qemu-libvirtd -"
      "f /dev/shm/scream        0660 ${username} qemu-libvirtd -"
    ];

    # Deploy libvirt hook script (libvirt reads from /var/lib/libvirt/hooks/)
    system.activationScripts.libvirt-hooks = ''
      mkdir -p /var/lib/libvirt/hooks
      ln -sf ${qemuHook} /var/lib/libvirt/hooks/qemu
    '';

    # Scream IVSHMEM receiver — bridges VM audio into host PipeWire/PulseAudio
    systemd.user.services.scream-ivshmem = {
      description = "Scream IVSHMEM audio receiver";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.scream}/bin/scream -m /dev/shm/scream -o pulse";
        Restart = "always";
        RestartSec = "5s";
      };
    };

    # studio-vm lifecycle service (fresh-install VM, no bare-metal SSD touched)
    systemd.services.studio-vm = {
      description = "Windows Studio VM (GPU passthrough)";
      after = [ "libvirtd.service" ];
      requires = [ "libvirtd.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.libvirt}/bin/virsh start ${vmName}";
        # Try graceful shutdown, force destroy after 20s if VM still running
        ExecStop = pkgs.writeShellScript "studio-vm-stop" ''
          ${pkgs.libvirt}/bin/virsh shutdown ${vmName} 2>/dev/null || true
          for i in $(seq 1 20); do
            STATE=$(${pkgs.libvirt}/bin/virsh domstate ${vmName} 2>/dev/null || echo "shut off")
            [ "$STATE" = "shut off" ] && exit 0
            sleep 1
          done
          ${pkgs.libvirt}/bin/virsh destroy ${vmName} 2>/dev/null || true
        '';
        TimeoutStopSec = "30s";
      };
    };
  };
} args
