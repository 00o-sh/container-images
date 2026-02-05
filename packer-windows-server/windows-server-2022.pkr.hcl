# Windows Server 2022 Packer Template
# Creates a sysprepped QCOW2 disk image for KubeVirt

packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "iso_url" {
  type        = string
  description = "URL or path to the Windows Server 2022 ISO"
  default     = "windows-server-2022.iso"
}

variable "iso_checksum" {
  type        = string
  description = "Checksum of the ISO file (sha256:...)"
  default     = "none"
}

variable "oemdrv_iso" {
  type        = string
  description = "Path to the OEMDRV ISO (VirtIO drivers + autounattend.xml)"
  default     = "oemdrv.iso"
}

variable "disk_size" {
  type        = string
  description = "Size of the output disk image"
  default     = "40G"
}

variable "memory" {
  type        = number
  description = "Memory in MB for the build VM"
  default     = 4096
}

variable "cpus" {
  type        = number
  description = "Number of CPUs for the build VM"
  default     = 2
}

variable "headless" {
  type        = bool
  description = "Run the build without a GUI"
  default     = true
}

variable "accelerator" {
  type        = string
  description = "QEMU accelerator (kvm or tcg)"
  default     = "kvm"
}

variable "efi_firmware_code" {
  type        = string
  description = "Path to OVMF firmware code"
  default     = "/usr/share/OVMF/OVMF_CODE_4M.fd"
}

variable "efi_firmware_vars" {
  type        = string
  description = "Path to OVMF firmware vars"
  default     = "/usr/share/OVMF/OVMF_VARS_4M.fd"
}

variable "winrm_username" {
  type    = string
  default = "Administrator"
}

variable "winrm_password" {
  type    = string
  default = "Admin123!"
}

source "qemu" "windows-server-2022" {
  # ISO Configuration
  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum

  # VM Configuration
  vm_name     = "windows-server-2022"
  headless    = var.headless
  accelerator = var.accelerator

  # Hardware
  memory  = var.memory
  cpus    = var.cpus

  # Disk Configuration
  disk_size        = var.disk_size
  disk_interface   = "virtio"
  format           = "qcow2"
  disk_compression = true

  # Network - disable boot ROM to prevent iPXE network boot
  net_device = "virtio-net-pci"

  # UEFI Boot (required for Windows Server)
  machine_type      = "q35"
  efi_boot          = true
  efi_firmware_code = var.efi_firmware_code
  efi_firmware_vars = var.efi_firmware_vars

  # Autounattend.xml on floppy (Windows Setup checks A: drive)
  floppy_files = ["autounattend.xml"]

  # VirtIO drivers ISO mounted as secondary CD, disable network boot ROM
  # Index 2 to not conflict with Windows ISO at index 0
  qemuargs = [
    ["-drive", "file=${var.oemdrv_iso},index=2,media=cdrom"],
    ["-global", "virtio-net-pci.romfile="],
  ]

  # Boot Configuration
  # Increase wait time and press key to skip "Press any key to boot from CD"
  boot_wait    = "6s"
  boot_command = ["<spacebar><spacebar><spacebar>"]

  # WinRM Communication
  communicator   = "winrm"
  winrm_username = var.winrm_username
  winrm_password = var.winrm_password
  winrm_timeout  = "4h"
  winrm_use_ssl  = false
  winrm_insecure = true

  # Output
  output_directory = "output"

  # Shutdown
  shutdown_command = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
  shutdown_timeout = "15m"
}

build {
  sources = ["source.qemu.windows-server-2022"]

  # Wait for Windows to be ready after first boot
  provisioner "powershell" {
    inline = [
      "Write-Host 'Windows installation complete, starting provisioning...'",
      "Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsHardwareAbstractionLayer"
    ]
  }

  # Install VirtIO guest tools
  provisioner "powershell" {
    script = "scripts/install-virtio.ps1"
  }

  # Configure the system
  provisioner "powershell" {
    script = "scripts/configure-system.ps1"
  }

  # Run Sysprep as the final step
  provisioner "powershell" {
    script = "scripts/sysprep.ps1"
  }

  # Post-processor to compress the final image
  post-processor "shell-local" {
    inline = [
      "echo 'Compressing final disk image...'",
      "qemu-img convert -c -O qcow2 output/windows-server-2022 windows-server-2022.qcow2",
      "ls -lh windows-server-2022.qcow2"
    ]
  }
}
