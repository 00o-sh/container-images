# Windows Server 2022 Evaluation ContainerDisk

Container images for deploying Windows Server 2022 Evaluation in KubeVirt.

> **Note:** This contains a 180-day evaluation license. Not for production use.

## Images

| Image | Description | Size |
|-------|-------------|------|
| `ghcr.io/00o-sh/windows-server:ltsc2022-eval` | Windows Server 2022 ISO (bootable) | ~5.2GB |
| `ghcr.io/00o-sh/windows-drivers:ltsc2022-eval` | VirtIO drivers + autounattend.xml | ~700MB |

## Usage in KubeVirt

Mount both images as CDROMs in your VirtualMachine spec:

```yaml
spec:
  template:
    spec:
      domain:
        devices:
          disks:
            - name: windows-iso
              cdrom:
                bus: sata
              bootOrder: 1
            - name: drivers-iso
              cdrom:
                bus: sata
      volumes:
        - name: windows-iso
          containerDisk:
            image: ghcr.io/00o-sh/windows-server:ltsc2022-eval
        - name: drivers-iso
          containerDisk:
            image: ghcr.io/00o-sh/windows-drivers:ltsc2022-eval
```

Windows Setup will automatically:
1. Boot from the Windows ISO
2. Find `autounattend.xml` on the drivers ISO (OEMDRV volume)
3. Load VirtIO drivers during installation
4. Install VirtIO guest tools on first login

## Automated Builds

Two separate GitHub Actions workflows:

- **Build Windows Server 2022 ISO** - Triggers on `Dockerfile.windows` changes
- **Build Windows VirtIO Drivers ISO** - Triggers on `Dockerfile.drivers` or `autounattend.xml` changes

To trigger manually: **Actions** → Select workflow → **Run workflow**

## Files

| File | Purpose |
|------|---------|
| `Dockerfile.windows` | Windows ISO container image |
| `Dockerfile.drivers` | Drivers ISO container image |
| `autounattend.xml` | Unattended installation config |

## Drivers ISO Contents

```
/
├── autounattend.xml          # Unattended install config
├── virtio-win-gt-x64.msi     # VirtIO guest tools installer
├── virtio-win-guest-tools.exe
└── virtio/                   # VirtIO drivers
    ├── vioscsi/2k22/amd64/   # SCSI controller
    ├── viostor/2k22/amd64/   # Block storage
    ├── NetKVM/2k22/amd64/    # Network adapter
    ├── Balloon/2k22/amd64/   # Memory ballooning
    ├── vioserial/2k22/amd64/ # Serial/guest agent
    ├── viorng/2k22/amd64/    # RNG
    ├── qxldod/2k22/amd64/    # QXL display
    └── pvpanic/2k22/amd64/   # Panic notification
```

## Default Credentials

| Account | Password |
|---------|----------|
| Administrator | Admin123! |
| user | User123! |
