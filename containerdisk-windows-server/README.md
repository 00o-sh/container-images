# Windows Server Evaluation ContainerDisk

Container images for deploying Windows Server Evaluation editions in KubeVirt.

> **Note:** These contain 180-day evaluation licenses. Not for production use.

## Images

### Windows Server ISOs

| Version | Tag | Description |
|---------|-----|-------------|
| 2016 | `2016` / `2016-np` | Windows Server 2016 LTSC Evaluation |
| 2019 | `2019` / `2019-np` | Windows Server 2019 LTSC Evaluation |
| 2022 | `2022` / `2022-np` | Windows Server 2022 LTSC Evaluation |
| 2025 | `2025` / `2025-np` | Windows Server 2025 LTSC Evaluation |
| Latest | `rolling` / `rolling-np` | Latest version (currently 2025) |

**No-prompt (`-np`) versions:** Skip "Press any key to boot from CD" for fully automated EFI boot.

### VirtIO Drivers

| Tag | Description |
|-----|-------------|
| `server` | VirtIO drivers + autounattend.xml for Windows Server |
| `client` | VirtIO drivers + autounattend.xml for Windows 10/11 (future) |

```bash
# Windows Server images (~5-6GB each)
docker pull ghcr.io/00o-sh/windows-server:2025
docker pull ghcr.io/00o-sh/windows-server:2022
docker pull ghcr.io/00o-sh/windows-server:2019
docker pull ghcr.io/00o-sh/windows-server:2016

# No-prompt versions for automated boot
docker pull ghcr.io/00o-sh/windows-server:2025-np
docker pull ghcr.io/00o-sh/windows-server:rolling-np  # latest

# VirtIO drivers (~700MB)
docker pull ghcr.io/00o-sh/windows-drivers:server
```

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
            image: ghcr.io/00o-sh/windows-server:rolling-np  # Use -np for automated boot
        - name: drivers-iso
          containerDisk:
            image: ghcr.io/00o-sh/windows-drivers:server
```

Windows Setup will automatically:
1. Boot from the Windows ISO
2. Find `autounattend.xml` on the drivers ISO (OEMDRV volume)
3. Load VirtIO drivers during installation
4. Install VirtIO guest tools on first login

## Workflows

### Build Windows Server ISO
- **Trigger:** Manual dispatch or push to `containerdisk-windows-server/Dockerfile.windows`
- **Input:** Select specific version (2016, 2019, 2022, 2025) or build all
- **Output:** Original + no-prompt images for selected versions

### Build VirtIO Drivers ISO
- **Trigger:** Push to `Dockerfile.drivers` or `autounattend.xml`
- **Output:** Universal drivers ISO for all Windows Server versions

## Files

| File | Purpose |
|------|---------|
| `Dockerfile.windows` | Windows ISO container image (version-agnostic) |
| `Dockerfile.drivers` | Drivers ISO container image |
| `autounattend.xml` | Unattended installation config |

## Drivers ISO Contents

```
/
├── autounattend.xml          # Unattended install config
├── virtio-win-gt-x64.msi     # VirtIO guest tools installer
├── virtio-win-guest-tools.exe
└── virtio/                   # VirtIO drivers
    ├── vioscsi/              # SCSI controller
    ├── viostor/              # Block storage
    ├── NetKVM/               # Network adapter
    ├── Balloon/              # Memory ballooning
    ├── vioserial/            # Serial/guest agent
    ├── viorng/               # RNG
    ├── qxldod/               # QXL display
    └── pvpanic/              # Panic notification
```

## Default Credentials

| Account | Password |
|---------|----------|
| Administrator | Admin123! |
| user | User123! |
