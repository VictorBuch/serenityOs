# Windows VM with GPU Passthrough — "Studio Mode"

Goal: Stop dual-booting. Run DaVinci Resolve Studio + REAPER (Windows VSTs) in a VM with GPU passthrough. Keep GPU on Linux for gaming when VM is off.

## Hardware (verified 2026-04-17)

| Component | Detail | PCI / ID |
|-----------|--------|----------|
| CPU | AMD Ryzen 7 7800X3D (8c/16t) | `kvm-amd` loaded |
| Discrete GPU | AMD RX 7900 XT/XTX (Navi 31) | `03:00.0` / `1002:744c` / IOMMU Group 14 |
| GPU Audio | Navi 31 HDMI/DP Audio | `03:00.1` / `1002:ab30` / IOMMU Group 15 |
| iGPU | AMD Raphael | `0e:00.0` / `1002:164e` / IOMMU Group 25 |
| RAM | 64GB | 32GB host / 32GB VM |
| Windows SSD | Samsung 850 EVO 500GB | `ata-Samsung_SSD_850_EVO_500GB_S2RBNB0J500574E` |
| Linux NVMe | WD Black SN850X 2TB | btrfs root |

IOMMU groups are clean — each device in its own group. No ACS patch needed.

## Display Setup (Option B — recommended)

Monitor plugged into **both** iGPU (motherboard HDMI) and RX 7900 (DP on card).

- **Normal use + gaming:** Monitor input on DP (RX 7900). Full GPU acceleration, zero overhead.
- **VM mode:** Switch monitor input to HDMI (iGPU). See Windows via Looking Glass. RX 7900 passes to VM.
- **VM stops:** GPU rebinds to Linux. Switch monitor back to DP.

**You need an HDMI cable** to connect your monitor to the motherboard HDMI output. This is prerequisite #1.

## Step 0: GPU Reset Test (DO THIS FIRST)

The AMD reset bug can prevent the RX 7900 from cleanly unbinding/rebinding. If this test fails, the whole dynamic passthrough model needs to change.

**Prerequisites:**
1. HDMI cable plugged into motherboard output, monitor set to HDMI input
2. Confirm your Linux desktop displays on the iGPU

**Test procedure (from a TTY or SSH — as root):**

```bash
# 1. Unbind RX 7900 GPU from amdgpu
echo "0000:03:00.0" > /sys/bus/pci/devices/0000:03:00.0/driver/unbind

# 2. Unbind RX 7900 Audio from snd_hda_intel
echo "0000:03:00.1" > /sys/bus/pci/devices/0000:03:00.1/driver/unbind

# 3. Load vfio-pci and bind both devices
modprobe vfio-pci
echo "1002 744c" > /sys/bus/pci/drivers/vfio-pci/new_id
echo "1002 ab30" > /sys/bus/pci/drivers/vfio-pci/new_id

# 4. Verify vfio-pci claimed them
lspci -ks 03:00.0
lspci -ks 03:00.1
# Should show "Kernel driver in use: vfio-pci"

# 5. Unbind from vfio-pci
echo "0000:03:00.0" > /sys/bus/pci/drivers/vfio-pci/unbind
echo "0000:03:00.1" > /sys/bus/pci/drivers/vfio-pci/unbind

# 6. Rebind to original drivers (THE CRITICAL MOMENT)
echo "0000:03:00.0" > /sys/bus/pci/drivers/amdgpu/bind
echo "0000:03:00.1" > /sys/bus/pci/drivers/snd_hda_intel/bind

# 7. Verify GPU is back
lspci -ks 03:00.0
# Should show "Kernel driver in use: amdgpu"
```

**If step 6 hangs:** AMD reset bug confirmed. Fallback options:
1. `vendor-reset` kernel module (community workaround)
2. Static VFIO binding (GPU always reserved for VM, reboot to switch)
3. Keep dual-booting

**If step 6 succeeds:** Dynamic passthrough works. Proceed to Phase 1.

**Note on Navi 31:** Reports suggest reset bug is less severe on RDNA3 than older cards. Kernel 6.18+ may have improved it. But test first.

## Phase 1: Foundation

### 1.1 Create NixOS module: `modules/apps/emulation/gpu-passthrough.nix`

```nix
args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "gpu-passthrough";
  category = "emulation";
  description = "Windows VM with GPU passthrough (Studio Mode)";
  linuxExtraConfig = {
    # Kernel params for IOMMU and VFIO
    boot.kernelParams = [ "amd_iommu=on" "iommu=pt" "pcie_aspm=off" ];
    boot.initrd.kernelModules = [ "vfio-pci" "vfio" "vfio_iommu_type1" ];
    # NOTE: do NOT add vfio-pci.ids here — dynamic binding via hooks

    # Libvirt
    virtualisation.libvirtd = {
      enable = true;
      qemuOvmf = true;
      qemuRunAsRoot = false;
      onBoot = "ignore";
      onShutdown = "shutdown";
    };

    # Looking Glass shared memory
    systemd.tmpfiles.rules = [
      "f /dev/shm/looking-glass 0660 jayne qemu-libvirtd -"
      "f /dev/shm/scream 0660 jayne qemu-libvirtd -"
    ];

    # User permissions
    users.users.jayne.extraGroups = [ "libvirtd" "kvm" ];

    # Looking Glass client
    environment.systemPackages = with pkgs; [
      looking-glass-client
      virt-manager
    ];

    # Deploy libvirt hook script
    system.activationScripts.libvirt-hooks = ''
      mkdir -p /var/lib/libvirt/hooks
      ln -sf ${hookScript} /var/lib/libvirt/hooks/qemu
    '';

    # Studio VM systemd service
    systemd.services.studio-vm = {
      description = "Windows Studio VM with GPU passthrough";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "jayne";
        ExecStartPre = [
          "-${pkgs.util-linux}/bin/umount /mnt/windows"
          "-${pkgs.util-linux}/bin/umount /mnt/winefi"
        ];
        ExecStart = "${pkgs.libvirt}/bin/virsh start studio-vm";
        ExecStop = "${pkgs.libvirt}/bin/virsh shutdown studio-vm";
        ExecStopPost = [
          "-${pkgs.util-linux}/bin/mount /mnt/windows"
          "-${pkgs.util-linux}/bin/mount /mnt/winefi"
        ];
      };
    };

    # Scream audio receiver
    systemd.user.services.scream-ivshmem = {
      enable = true;
      description = "Scream IVSHMEM audio receiver";
      serviceConfig = {
        ExecStart = "${pkgs.scream}/bin/scream-ivshmem-pulse /dev/shm/scream";
        Restart = "always";
      };
    };
  };
} args
```

The hook script (bind/unbind logic):

```nix
hookScript = pkgs.writeShellScript "qemu-hook" ''
  GUEST_NAME="$1"
  HOOK_NAME="$2"
  STATE_NAME="$3"

  # Only act on studio-vm
  [ "$GUEST_NAME" != "studio-vm" ] && exit 0

  GPU_PCI="0000:03:00.0"
  AUDIO_PCI="0000:03:00.1"

  if [ "$HOOK_NAME" = "prepare" ] && [ "$STATE_NAME" = "begin" ]; then
    # Unbind from host drivers
    echo "$GPU_PCI" > /sys/bus/pci/devices/$GPU_PCI/driver/unbind 2>/dev/null || true
    echo "$AUDIO_PCI" > /sys/bus/pci/devices/$AUDIO_PCI/driver/unbind 2>/dev/null || true

    # Bind to vfio-pci
    modprobe vfio-pci
    echo "1002 744c" > /sys/bus/pci/drivers/vfio-pci/new_id 2>/dev/null || true
    echo "1002 ab30" > /sys/bus/pci/drivers/vfio-pci/new_id 2>/dev/null || true
  fi

  if [ "$HOOK_NAME" = "release" ] && [ "$STATE_NAME" = "end" ]; then
    # Unbind from vfio-pci
    echo "$GPU_PCI" > /sys/bus/pci/drivers/vfio-pci/unbind 2>/dev/null || true
    echo "$AUDIO_PCI" > /sys/bus/pci/drivers/vfio-pci/unbind 2>/dev/null || true

    # Remove vfio-pci IDs
    echo "1002 744c" > /sys/bus/pci/drivers/vfio-pci/remove_id 2>/dev/null || true
    echo "1002 ab30" > /sys/bus/pci/drivers/vfio-pci/remove_id 2>/dev/null || true

    # Rebind to host drivers
    echo "$GPU_PCI" > /sys/bus/pci/drivers/amdgpu/bind 2>/dev/null || true
    echo "$AUDIO_PCI" > /sys/bus/pci/drivers/snd_hda_intel/bind 2>/dev/null || true
  fi
'';
```

### 1.2 Enable in host config

In `hosts/jayne/configuration.nix`:
```nix
apps.emulation.gpu-passthrough.enable = true;
```

### 1.3 Rebuild and reboot

```bash
sudo nixos-rebuild switch --flake .
# Reboot required — kernel params changed
```

### 1.4 Back up Windows SSD (before first VM boot)

```bash
sudo dd if=/dev/disk/by-id/ata-Samsung_SSD_850_EVO_500GB_S2RBNB0J500574E \
  of=/home/jayne/windows-backup.img bs=4M status=progress
```

~500GB, takes a while. Store on the 2TB NVMe.

### 1.5 Create VM domain XML

Save as `studio-vm.xml` and define with `virsh define studio-vm.xml`:

```xml
<domain type='kvm'>
  <name>studio-vm</name>
  <memory unit='GiB'>32</memory>
  <vcpu placement='static'>8</vcpu>
  <cputune>
    <vcpupin vcpu='0' cpuset='4'/>
    <vcpupin vcpu='1' cpuset='5'/>
    <vcpupin vcpu='2' cpuset='6'/>
    <vcpupin vcpu='3' cpuset='7'/>
    <vcpupin vcpu='4' cpuset='12'/>
    <vcpupin vcpu='5' cpuset='13'/>
    <vcpupin vcpu='6' cpuset='14'/>
    <vcpupin vcpu='7' cpuset='15'/>
  </cputune>
  <os>
    <type arch='x86_64' machine='q35'>hvm</type>
    <loader readonly='yes' type='pflash'>/run/libvirt/nix-ovmf/OVMF_CODE.fd</loader>
    <nvram>/var/lib/libvirt/qemu/nvram/studio-vm_VARS.fd</nvram>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
  </features>
  <cpu mode='host-passthrough' check='none'>
    <topology sockets='1' dies='1' cores='4' threads='2'/>
    <feature policy='require' name='topoext'/>
  </cpu>
  <clock offset='localtime'>
    <timer name='rtc' tickpolicy='catchup'/>
    <timer name='pit' tickpolicy='delay'/>
    <timer name='hpet' present='no'/>
    <timer name='hypervclock' present='yes'/>
  </clock>
  <devices>
    <!-- Whole-disk passthrough of Windows SSD -->
    <disk type='block' device='disk'>
      <driver name='qemu' type='raw' cache='none' io='native'/>
      <source dev='/dev/disk/by-id/ata-Samsung_SSD_850_EVO_500GB_S2RBNB0J500574E'/>
      <target dev='sda' bus='sata'/>
    </disk>
    <!-- GPU passthrough -->
    <hostdev mode='subsystem' type='pci' managed='yes'>
      <source>
        <address domain='0x0000' bus='0x03' slot='0x00' function='0x0'/>
      </source>
    </hostdev>
    <!-- GPU Audio passthrough -->
    <hostdev mode='subsystem' type='pci' managed='yes'>
      <source>
        <address domain='0x0000' bus='0x03' slot='0x00' function='0x1'/>
      </source>
    </hostdev>
    <!-- Looking Glass IVSHMEM -->
    <shmem name='looking-glass'>
      <model type='ivshmem-plain'/>
      <size unit='M'>128</size>
    </shmem>
    <!-- Scream audio IVSHMEM -->
    <shmem name='scream'>
      <model type='ivshmem-plain'/>
      <size unit='M'>2</size>
    </shmem>
    <!-- VirtIO network -->
    <interface type='network'>
      <source network='default'/>
      <model type='virtio'/>
    </interface>
    <!-- USB controllers for passthrough -->
    <controller type='usb' model='qemu-xhci'/>
    <!-- Add audio interface USB passthrough here:
    <hostdev mode='subsystem' type='usb'>
      <source>
        <vendor id='0xXXXX'/>
        <product id='0xXXXX'/>
      </source>
    </hostdev>
    -->
  </devices>
</domain>
```

### 1.6 First VM boot

```bash
systemctl start studio-vm
# Or: virsh start studio-vm
```

- Windows should boot from SSD seeing its native SATA disk
- Only VirtIO **network** and **balloon** drivers needed (not storage — disk is raw SATA passthrough)
- Download VirtIO drivers: https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/
- Verify GPU in Device Manager, install AMD drivers
- May need to re-activate Windows (hardware fingerprint changed)

## Phase 2: Looking Glass + USB

After Phase 1 works:

1. VM XML already has IVSHMEM device for Looking Glass
2. In Windows VM: download and install Looking Glass Host (match version with `looking-glass-client --version`)
3. On Linux: `looking-glass-client` — should show Windows desktop
4. Add audio interface USB IDs to VM XML (find with `lsusb`)
5. Test DaVinci Resolve + REAPER

## Phase 3: Polish

1. Set up virtiofs or Samba shared folder for project files
2. Test `systemctl start/stop studio-vm` full lifecycle
3. Verify bare-metal Windows boot still works (select SSD in BIOS)
4. Add Scream audio driver in Windows for VM→host audio

## Daily Workflow

```
Gaming / normal use:
  Monitor on DP (RX 7900). Full GPU. Normal Linux desktop.

Video editing / music production:
  1. Switch monitor input to HDMI (iGPU)
  2. systemctl start studio-vm
  3. looking-glass-client
  4. Edit in DaVinci / produce in REAPER
  5. systemctl stop studio-vm
  6. Switch monitor back to DP
  7. Game
```

## Open Questions

1. **Audio interface USB IDs** — run `lsusb` and add to VM XML
2. **Windows activation** — may need to reactivate after first VM boot
3. **GRUB os-prober** — may get confused with raw disk passthrough; might need to hardcode Windows boot entry (already done in current config)
4. **Looking Glass version sync** — client and host must match; check after NixOS updates

## Fallback if Reset Bug Hits

If GPU doesn't cleanly rebind in Step 0, use static VFIO binding instead:

```nix
# In gpu-passthrough.nix — replace dynamic hooks with:
boot.initrd.preDeviceCommands = ''
  DEVS="0000:03:00.0 0000:03:00.1"
  for DEV in $DEVS; do
    echo "vfio-pci" > /sys/bus/pci/devices/$DEV/driver_override
  done
  modprobe -i vfio-pci
'';
```

This permanently reserves RX 7900 for VFIO at boot. Linux always uses iGPU. No dynamic switching. Gaming would require PRIME render offload (`DRI_PRIME=1`) with ~2-5% overhead... which mostly defeats the purpose. If this happens, dual-booting may remain the better option for gaming.

## References

- [Alex Bakker — NixOS PCI Passthrough](https://alexbakker.me/post/nixos-pci-passthrough-qemu-vfio.html)
- [NixOS Wiki — PCI Passthrough](https://wiki.nixos.org/wiki/PCI_passthrough)
- [Arch Wiki — PCI passthrough via OVMF](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF)
- [pigs.dev — Gaming in a Windows VM with NixOS (2025)](https://pigs.dev/posts/2025-04-15-gaming-in-vm-with-nixos.html)
- [GamiNiX — Full NixOS VFIO config](https://github.com/iggut/GamiNiX)
