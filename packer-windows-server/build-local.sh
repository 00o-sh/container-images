#!/bin/bash
set -e

cd "$(dirname "$0")"

# Parse arguments
INSTALL_DEPS=false
HEADLESS=true

for arg in "$@"; do
    case $arg in
        --install-deps) INSTALL_DEPS=true ;;
        --gui) HEADLESS=false ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --install-deps  Install required dependencies"
            echo "  --gui           Show QEMU window (requires X/display)"
            echo "  --help          Show this help"
            exit 0
            ;;
    esac
done

# Install dependencies if requested
if [ "$INSTALL_DEPS" == "true" ]; then
    echo "Installing dependencies..."
    sudo apt-get update
    sudo apt-get install -y \
        qemu-system-x86 \
        qemu-utils \
        p7zip-full \
        genisoimage \
        curl \
        unzip

    # Install Packer if not present
    if ! command -v packer &> /dev/null; then
        echo "Installing Packer..."
        PACKER_VERSION="1.10.0"

        # Detect architecture
        ARCH=$(uname -m)
        case $ARCH in
            x86_64)  PACKER_ARCH="amd64" ;;
            aarch64) PACKER_ARCH="arm64" ;;
            arm64)   PACKER_ARCH="arm64" ;;
            *)       echo "ERROR: Unsupported architecture: $ARCH"; exit 1 ;;
        esac

        curl -fsSL "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_${PACKER_ARCH}.zip" -o /tmp/packer.zip
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

# Using BIOS boot (no OVMF needed)

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
echo "  Accelerator: $ACCELERATOR"
echo "  Headless: $HEADLESS"
if [ "$HEADLESS" == "true" ]; then
    echo ""
    echo "Running headless. To view the VM, connect via VNC to the port shown in the logs."
    echo "Or re-run with --gui if you have a display."
fi
echo ""

PACKER_LOG=1 packer build \
    -var "iso_url=$WINDOWS_ISO" \
    -var "iso_checksum=none" \
    -var "oemdrv_iso=$OEMDRV_ISO" \
    -var "accelerator=$ACCELERATOR" \
    -var "headless=$HEADLESS" \
    windows-server-2022.pkr.hcl

echo ""
echo "Build complete!"
ls -lh windows-server-2022.qcow2
