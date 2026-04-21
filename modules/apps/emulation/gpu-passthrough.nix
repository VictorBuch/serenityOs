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

  # Wrapper scripts: user is in libvirtd group, virsh talks to qemu:///system
  studioStart = pkgs.writeShellScriptBin "studio-start" ''
    set -e
    STATE=$(${pkgs.libvirt}/bin/virsh -c qemu:///system domstate ${vmName} 2>/dev/null || echo missing)
    if [ "$STATE" != "running" ]; then
      ${pkgs.libvirt}/bin/virsh -c qemu:///system start ${vmName}
      sleep 3
    fi
    exec ${pkgs.looking-glass-client}/bin/looking-glass-client -F
  '';

  studioStop = pkgs.writeShellScriptBin "studio-stop" ''
    # Graceful ACPI shutdown, force destroy after 20s
    ${pkgs.libvirt}/bin/virsh -c qemu:///system shutdown ${vmName} 2>/dev/null || true
    for i in $(seq 1 20); do
      STATE=$(${pkgs.libvirt}/bin/virsh -c qemu:///system domstate ${vmName} 2>/dev/null || echo "shut off")
      [ "$STATE" = "shut off" ] && echo "VM stopped cleanly" && exit 0
      sleep 1
    done
    echo "VM did not respond to ACPI shutdown, forcing destroy"
    ${pkgs.libvirt}/bin/virsh -c qemu:///system destroy ${vmName} 2>/dev/null || true
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
    fi

    if [ "$HOOK_NAME" = "release" ] && [ "$STATE_NAME" = "end" ]; then
      # Run rebind in background — libvirt sandbox enforces hook timeout (~30s)
      # and amdgpu bind can block while GPU reinitializes. Detach via setsid+nohup.
      setsid nohup sh -c "
        echo '$GPU_PCI'   > /sys/bus/pci/drivers/vfio-pci/unbind 2>/dev/null
        echo '$AUDIO_PCI' > /sys/bus/pci/drivers/vfio-pci/unbind 2>/dev/null
        echo '$GPU_ID'    > /sys/bus/pci/drivers/vfio-pci/remove_id 2>/dev/null
        echo '$AUDIO_ID'  > /sys/bus/pci/drivers/vfio-pci/remove_id 2>/dev/null

        # Let PCI state settle before touching the GPU again. Navi 3x PSP/SMU
        # need quiet time after vfio releases them; binding amdgpu immediately
        # races the SMU and leaves it wedged.
        sleep 2

        # Function-level reset while no driver is bound — clears any half
        # torn-down state before amdgpu takes over.
        echo 1 > '/sys/bus/pci/devices/$GPU_PCI/reset'   2>/dev/null
        echo 1 > '/sys/bus/pci/devices/$AUDIO_PCI/reset' 2>/dev/null
        sleep 1

        echo '$GPU_PCI'   > /sys/bus/pci/drivers/amdgpu/bind 2>/dev/null
        echo '$AUDIO_PCI' > /sys/bus/pci/drivers/snd_hda_intel/bind 2>/dev/null
      " </dev/null >/dev/null 2>&1 &
      disown
    fi
  '';
in
mkModule {
  name = "gpu-passthrough";
  category = "emulation";
  description = "Windows VM with GPU passthrough (Studio Mode)";

  linuxPackages = { pkgs, ... }: [
    pkgs.looking-glass-client
    pkgs.virt-manager
    pkgs.virt-viewer # standalone SPICE/VNC console
    pkgs.usbutils # lsusb for finding USB passthrough IDs
    pkgs.e2fsprogs # chattr for btrfs nodatacow on VM images
    studioStart
    studioStop
  ];

  linuxExtraConfig = {
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
