# Windows Server 2022 ContainerDisk

A minimal container image containing the Windows Server 2022 ISO for use as a ContainerDisk.

## Structure

```
/disk/
└── windows-server-2022.iso
```

## Prerequisites

Download the Windows Server 2022 Evaluation ISO from the [Microsoft Evaluation Center](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022):

- File: `SERVER_EVAL_x64FRE_en-us.iso` (~5.2GB)
- License: 180-day evaluation

Place the ISO file in this directory before building.

## Build

```bash
docker build -t ghcr.io/00o-sh/windows-server-2022-iso:ltsc2022 .
```

## Push

```bash
docker push ghcr.io/00o-sh/windows-server-2022-iso:ltsc2022
```

## Notes

- Base image is `scratch` (empty container)
- ISO is placed in `/disk/` directory with `.iso` extension
- Final image size: ~5.2GB
