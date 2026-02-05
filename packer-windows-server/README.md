# Windows Server Disk Image Builder (Packer)

This directory contains Packer templates and scripts for building pre-installed, sysprepped Windows Server disk images.

## Overview

Instead of distributing Windows ISOs that require installation on every deployment, this creates ready-to-boot QCOW2 disk images with:

- Windows Server pre-installed
- VirtIO drivers included
- Sysprepped for deployment (boots to OOBE)
- Optimized for KubeVirt

## Benefits

| Approach | Boot Time | Install Time | Total Time |
|----------|-----------|--------------|------------|
| ISO + Install | ~2 min | ~20-30 min | ~25-35 min |
| Disk Image | ~2 min | 0 (pre-installed) | ~2 min |

## Files

```
packer-windows-server/
├── windows-server-2022.pkr.hcl  # Packer template
├── autounattend.xml              # Unattended install config
├── Dockerfile.disk               # Container image for disk
├── scripts/
│   ├── install-virtio.ps1        # Install VirtIO guest tools
│   ├── configure-system.ps1      # System configuration
│   └── sysprep.ps1               # Sysprep and shutdown
└── README.md
```

## Building Locally

### Prerequisites

- QEMU with KVM support (recommended)
- Packer 1.10+
- ~50GB free disk space

### Steps

1. Download the Windows Server 2022 ISO and VirtIO drivers ISO:

```bash
# Windows Server 2022 Evaluation
curl -L -o windows-server-2022.iso "https://go.microsoft.com/fwlink/p/?LinkID=2195280&clcid=0x409&culture=en-us&country=US"

# VirtIO drivers
curl -L -o virtio-win.iso "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso"
```

2. Initialize Packer:

```bash
cd packer-windows-server
packer init windows-server-2022.pkr.hcl
```

3. Create the drivers ISO with autounattend:

```bash
mkdir -p output-drivers/virtio
7z x virtio-win.iso -ooutput-drivers/virtio
cp autounattend.xml output-drivers/virtio/
genisoimage -o output-drivers/oemdrv.iso -V "OEMDRV" -J -r output-drivers/virtio/
```

4. Build the image:

```bash
# With KVM (fast, ~30-45 min)
packer build \
  -var "iso_url=windows-server-2022.iso" \
  -var "virtio_iso_url=virtio-win.iso" \
  -var "accelerator=kvm" \
  windows-server-2022.pkr.hcl

# Without KVM (slow, ~3-4 hours)
packer build \
  -var "iso_url=windows-server-2022.iso" \
  -var "virtio_iso_url=virtio-win.iso" \
  -var "accelerator=tcg" \
  windows-server-2022.pkr.hcl
```

5. The output will be `windows-server-2022.qcow2`

## GitHub Actions

The workflow `.github/workflows/build-windows-disk.yml` automates this process:

- **Manual trigger only** (workflow_dispatch)
- Downloads ISOs from Microsoft and Fedora
- Builds with TCG (no KVM on standard runners)
- Takes ~3-4 hours on standard runners
- Publishes to `ghcr.io/00o-sh/windows-server:2022-disk`

## Using the Disk Image in KubeVirt

### As a ContainerDisk (ephemeral)

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: windows-server-2022
spec:
  running: true
  template:
    spec:
      domain:
        devices:
          disks:
            - name: rootdisk
              disk:
                bus: virtio
        resources:
          requests:
            memory: 4Gi
      volumes:
        - name: rootdisk
          containerDisk:
            image: ghcr.io/00o-sh/windows-server:2022-disk
```

### As a DataVolume (persistent)

```yaml
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataVolume
metadata:
  name: windows-server-2022-dv
spec:
  source:
    registry:
      url: "docker://ghcr.io/00o-sh/windows-server:2022-disk"
  pvc:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 40Gi
```

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `iso_url` | `windows-server-2022.iso` | Path to Windows ISO |
| `iso_checksum` | `none` | ISO checksum (sha256:...) |
| `virtio_iso_url` | `virtio-win.iso` | Path to VirtIO drivers ISO |
| `disk_size` | `40G` | Output disk size |
| `memory` | `4096` | Build VM memory (MB) |
| `cpus` | `2` | Build VM CPUs |
| `headless` | `true` | Run without GUI |
| `accelerator` | `kvm` | QEMU accelerator (kvm/tcg) |

## Notes

- The resulting image boots to Windows OOBE (Out-of-Box Experience)
- Administrator password is cleared by sysprep
- The image is generalized and can be deployed multiple times
- VirtIO drivers are pre-installed for optimal KubeVirt performance
