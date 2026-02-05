#!/bin/bash
set -e

cd "$(dirname "$0")"

# Install dependencies if requested
if [ "$1" == "--install-deps" ]; then
    echo "Installing dependencies..."
    sudo apt-get update
    sudo apt-get install -y \
        qemu-system-x86 \
        qemu-utils \
        ovmf \
        p7zip-full \
        genisoimage \
        curl

    # Install Packer if not present
    if ! command -v packer &> /dev/null; then
        echo "Installing Packer..."
        PACKER_VERSION="1.10.0"
        curl -fsSL "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip" -o /tmp/packer.zip
        unzip -o /tmp/packer.zip -d /tmp
        sudo mv /tmp/packer /usr/local/bin/
        rm /tmp/packer.zip
    fi

    echo "Dependencies installed!"
    echo ""
fi

# Check for required commands
for cmd in qemu-system-x86_64 packer 7z genisoimage; do
    if ! command -v $cmd &> /dev/null; then
        echo "ERROR: $cmd not found. Run: $0 --install-deps"
        exit 1
    fi
done

# Configuration
WINDOWS_ISO="windows-server-2022.iso"
VIRTIO_ISO="virtio-win.iso"
OEMDRV_ISO="oemdrv.iso"

# Detect KVM
if [ -e /dev/kvm ] && [ -r /dev/kvm ]; then
    ACCELERATOR="kvm"
    echo "KVM detected - build will be fast (~30-45 min)"
else
    ACCELERATOR="tcg"
    echo "WARNING: No KVM - build will be SLOW (~3-4 hours)"
fi

# Find OVMF firmware
for path in /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd /usr/share/edk2/ovmf/OVMF_CODE.fd; do
    if [ -f "$path" ]; then
        EFI_CODE="$path"
        break
    fi
done

for path in /usr/share/OVMF/OVMF_VARS_4M.fd /usr/share/OVMF/OVMF_VARS.fd /usr/share/edk2/ovmf/OVMF_VARS.fd; do
    if [ -f "$path" ]; then
        EFI_VARS="$path"
        break
    fi
done

if [ -z "$EFI_CODE" ] || [ -z "$EFI_VARS" ]; then
    echo "ERROR: OVMF firmware not found. Install with: sudo apt install ovmf"
    exit 1
fi

echo "Using OVMF: $EFI_CODE"

# Download Windows ISO if missing
if [ ! -f "$WINDOWS_ISO" ]; then
    echo "Downloading Windows Server 2022 ISO..."
    curl -L -o "$WINDOWS_ISO" "https://go.microsoft.com/fwlink/p/?LinkID=2195280&clcid=0x409&culture=en-us&country=US"
fi

# Download VirtIO ISO if missing
if [ ! -f "$VIRTIO_ISO" ]; then
    echo "Downloading VirtIO drivers ISO..."
    curl -L -o "$VIRTIO_ISO" "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso"
fi

# Create OEMDRV ISO
echo "Creating OEMDRV ISO..."
rm -rf oemdrv-contents
mkdir -p oemdrv-contents
7z x "$VIRTIO_ISO" -ooemdrv-contents -y
cp autounattend.xml oemdrv-contents/
genisoimage -o "$OEMDRV_ISO" -V "OEMDRV" -J -r oemdrv-contents/
rm -rf oemdrv-contents
echo "Created: $OEMDRV_ISO ($(ls -lh $OEMDRV_ISO | awk '{print $5}'))"

# Initialize Packer
echo "Initializing Packer..."
packer init windows-server-2022.pkr.hcl

# Run Packer
echo ""
echo "Starting Packer build..."
echo "Accelerator: $ACCELERATOR"
echo ""

# Add -debug flag to see VNC connection info for debugging
# Remove PACKER_LOG=1 for cleaner output, add it back for debugging
PACKER_LOG=1 packer build \
    -var "iso_url=$WINDOWS_ISO" \
    -var "iso_checksum=none" \
    -var "accelerator=$ACCELERATOR" \
    -var "efi_firmware_code=$EFI_CODE" \
    -var "efi_firmware_vars=$EFI_VARS" \
    -var "headless=false" \
    windows-server-2022.pkr.hcl

echo ""
echo "Build complete!"
ls -lh windows-server-2022.qcow2
