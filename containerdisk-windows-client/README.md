# Windows Client Evaluation ContainerDisk

Container images for deploying Windows 10/11 LTSC Evaluation editions in KubeVirt.

> **Note:** These contain 90-day evaluation licenses. Not for production use.

## Images

### Windows Client ISOs

| Version | Tag | Description |
|---------|-----|-------------|
| Win10 LTSC 2021 | `10` / `10-np` | Windows 10 Enterprise LTSC 2021 Evaluation |
| Win11 LTSC 2024 | `11` / `11-np` | Windows 11 Enterprise LTSC 2024 Evaluation |
| Latest | `rolling` / `rolling-np` | Latest version (currently Win11) |

**No-prompt (`-np`) versions:** Skip "Press any key to boot from CD" for fully automated EFI boot.

### VirtIO Drivers

| Tag | Description |
|-----|-------------|
| `client` | VirtIO drivers + autounattend.xml for Windows 10/11 |

```bash
# Windows Client images (~4-5GB each)
docker pull ghcr.io/00o-sh/windows-client:11
docker pull ghcr.io/00o-sh/windows-client:10

# No-prompt versions for automated boot
docker pull ghcr.io/00o-sh/windows-client:rolling-np  # latest
docker pull ghcr.io/00o-sh/windows-client:11-np

# VirtIO drivers (~700MB)
docker pull ghcr.io/00o-sh/windows-drivers:client
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
            image: ghcr.io/00o-sh/windows-client:rolling-np
        - name: drivers-iso
          containerDisk:
            image: ghcr.io/00o-sh/windows-drivers:client
```

## Evaluation License

- 90-day evaluation period
- Can be extended 3 times using `slmgr /rearm` (total 270 days)
- Requires internet activation within 10 days

## Files

| File | Purpose |
|------|---------|
| `Dockerfile.windows` | Windows ISO container image (version-agnostic) |
