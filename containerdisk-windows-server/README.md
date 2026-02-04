# Windows Server 2022 Evaluation ContainerDisk

A minimal container image containing the Windows Server 2022 **Evaluation** ISO for use as a ContainerDisk.

> **Note:** This contains a 180-day evaluation license. Not for production use.

## Automated Build

This image is built automatically via GitHub Actions:
- Triggers on push to `main` or manual dispatch
- Downloads ISO directly from Microsoft
- Pushes to `ghcr.io`

To trigger manually: **Actions** → **Build Windows Server 2022 ContainerDisk** → **Run workflow**

## Structure

```
/disk/
└── disk.img
```

## Prerequisites

Download the Windows Server 2022 Evaluation ISO from the [Microsoft Evaluation Center](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022):

- File: `SERVER_EVAL_x64FRE_en-us.iso` (~5.2GB)
- License: 180-day evaluation

Place the ISO file in this directory before building.

## Build

```bash
docker build -t ghcr.io/00o-sh/windows-server-2022-eval-iso:ltsc2022-eval .
```

## Push

```bash
docker push ghcr.io/00o-sh/windows-server-2022-eval-iso:ltsc2022-eval
```

## Notes

- Base image is `scratch` (empty container)
- ISO is placed in `/disk/disk.img` (KubeVirt containerDisk naming convention)
- Final image size: ~5.2GB
