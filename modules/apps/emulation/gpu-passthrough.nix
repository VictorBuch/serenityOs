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

  # libvirt qemu hook: dynamic GPU bind/unbind per VM lifecycle
  qemuHook = pkgs.writeShellScript "qemu-hook" ''
    #!/usr/bin/env bash
    set -e

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
      # Unbind from vfio-pci
      echo "$GPU_PCI"   > /sys/bus/pci/drivers/vfio-pci/unbind 2>/dev/null || true
      echo "$AUDIO_PCI" > /sys/bus/pci/drivers/vfio-pci/unbind 2>/dev/null || true

      # Remove IDs so vfio-pci doesn't auto-reclaim
      echo "$GPU_ID"   > /sys/bus/pci/drivers/vfio-pci/remove_id 2>/dev/null || true
      echo "$AUDIO_ID" > /sys/bus/pci/drivers/vfio-pci/remove_id 2>/dev/null || true

      # Rebind to host drivers
      echo "$GPU_PCI"   > /sys/bus/pci/drivers/amdgpu/bind        2>/dev/null || true
      echo "$AUDIO_PCI" > /sys/bus/pci/drivers/snd_hda_intel/bind 2>/dev/null || true
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
  ];

  linuxExtraConfig = {
    # IOMMU + VFIO kernel setup. pcie_aspm=off prevents AER errors on AMD.
    boot.kernelParams = [
      "amd_iommu=on"
      "iommu=pt"
      "pcie_aspm=off"
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
        ExecStop  = "${pkgs.libvirt}/bin/virsh shutdown ${vmName}";
        TimeoutStopSec = "120s";
      };
    };
  };
} args
