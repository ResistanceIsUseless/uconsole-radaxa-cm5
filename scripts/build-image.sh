#!/bin/bash
#
# Build image for Radxa CM5 uConsole
#
# Usage: ./build-image.sh <distro> <kernel_version> [base_image_url]
#
# Arguments:
#   distro: debian, kali, or retropie
#   kernel_version: Kernel version suffix
#   base_image_url: Optional custom base image URL

set -e  # Exit on error
set -u  # Exit on undefined variable

# Configuration
DISTRO="${1:-debian}"
KERNEL_VERSION="${2:-1}"
BASE_IMAGE_URL="${3:-}"

WORK_DIR="$(pwd)/build"
OUTPUT_DIR="${WORK_DIR}/output"
MOUNT_DIR="/tmp/uconsole-mount-$$"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate distro
case "$DISTRO" in
    debian|kali|retropie)
        ;;
    *)
        log_error "Invalid distro: $DISTRO (must be debian, kali, or retropie)"
        exit 1
        ;;
esac

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

# Check dependencies
for cmd in wget xz kmod cpio rsync dosfstools parted qemu-user-static losetup; do
    if ! command -v "$cmd" &> /dev/null; then
        log_error "Required command not found: $cmd"
        exit 1
    fi
done

# Check for kernel packages
if [ ! -d "${OUTPUT_DIR}/kernel-packages" ] || [ -z "$(ls -A ${OUTPUT_DIR}/kernel-packages/*.deb 2>/dev/null)" ]; then
    log_error "Kernel packages not found. Run build-kernel.sh first."
    exit 1
fi

# Set base image URL if not provided
if [ -z "$BASE_IMAGE_URL" ]; then
    BASE_IMAGE_URL="https://github.com/radxa-build/radxa-cm5-rpi-cm4-io/releases/download/rsdk-b3/radxa-cm5-rpi-cm4-io_bookworm_cli_b3.output.img.xz"
fi

IMAGE_FILE="${WORK_DIR}/${DISTRO}.img"

# Cleanup function
cleanup() {
    log_info "Cleaning up..."
    umount "${MOUNT_DIR}/boot" 2>/dev/null || true
    umount "${MOUNT_DIR}/root" 2>/dev/null || true

    LOOP_DEVICE=$(losetup -a | grep "${DISTRO}.img" | cut -d: -f1 || true)
    if [ -n "$LOOP_DEVICE" ]; then
        losetup -d "$LOOP_DEVICE" || true
    fi

    rm -rf "${MOUNT_DIR}"
}

trap cleanup EXIT

# Download base image
log_info "Downloading base image for ${DISTRO}..."
wget -O "${WORK_DIR}/${DISTRO}.img.xz" "$BASE_IMAGE_URL"
xz -d "${WORK_DIR}/${DISTRO}.img.xz"

# Mount image
log_info "Mounting image..."
losetup -fP "${IMAGE_FILE}"
LOOP_DEVICE=$(losetup -a | grep "${DISTRO}.img" | cut -d: -f1)
log_info "Loop device: $LOOP_DEVICE"

mkdir -p "${MOUNT_DIR}/boot" "${MOUNT_DIR}/root"
mount "${LOOP_DEVICE}p1" "${MOUNT_DIR}/boot" || true
mount "${LOOP_DEVICE}p2" "${MOUNT_DIR}/root"

# Verify mount and create tmp directory
log_info "Verifying mount..."
ls -la "${MOUNT_DIR}/root/" > /dev/null || log_error "Root filesystem not mounted properly"
mkdir -p "${MOUNT_DIR}/root/tmp"

# Install kernel
log_info "Installing kernel packages..."
cp "${OUTPUT_DIR}"/kernel-packages/*.deb "${MOUNT_DIR}/root/tmp/"

chroot "${MOUNT_DIR}/root" /bin/bash -c "
    export DEBIAN_FRONTEND=noninteractive
    cd /tmp
    dpkg -i linux-image-*.deb || true
    apt-get install -f -y
    rm -f /tmp/*.deb
    update-initramfs -u -k all
"

# Install overlays
log_info "Installing device tree overlays..."
mkdir -p "${MOUNT_DIR}/boot/overlays"
cp "${OUTPUT_DIR}"/overlays/*.dtbo "${MOUNT_DIR}/boot/overlays/" 2>/dev/null || true

# Distro-specific configuration
case "$DISTRO" in
    kali)
        log_info "Configuring Kali Linux..."
        chroot "${MOUNT_DIR}/root" /bin/bash -c "
            export DEBIAN_FRONTEND=noninteractive

            # Add Kali repos
            echo 'deb http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware' > /etc/apt/sources.list.d/kali.list

            # Add Kali GPG key
            wget -q -O /tmp/kali-archive-key.asc https://archive.kali.org/archive-key.asc
            gpg --dearmor < /tmp/kali-archive-key.asc > /etc/apt/trusted.gpg.d/kali-archive-keyring.gpg
            rm /tmp/kali-archive-key.asc

            # Update package lists
            apt-get update || true
        "
        ;;

    retropie)
        log_info "Configuring RetroPie..."
        chroot "${MOUNT_DIR}/root" /bin/bash -c "
            export DEBIAN_FRONTEND=noninteractive

            # Install RetroPie dependencies
            apt-get install -y git dialog unzip xmlstarlet python3-pip

            # Create RetroPie user
            useradd -m -G video,audio,input,dialout,plugdev -s /bin/bash retropie || true
            echo 'retropie:retropie' | chpasswd

            # Download RetroPie setup script
            cd /home/retropie
            git clone --depth=1 https://github.com/RetroPie/RetroPie-Setup.git
            chown -R retropie:retropie RetroPie-Setup

            # Create installation script
            cat > /home/retropie/install-retropie.sh << 'SCRIPT_EOF'
#!/bin/bash
cd /home/retropie/RetroPie-Setup
sudo ./retropie_setup.sh
SCRIPT_EOF
            chmod +x /home/retropie/install-retropie.sh
            chown retropie:retropie /home/retropie/install-retropie.sh
        "

        # Create MOTD
        printf '%s\n' \
            '===========================================' \
            "  Radxa CM5 uConsole - ${DISTRO^} Edition" \
            '===========================================' \
            '' \
            'To complete RetroPie installation:' \
            '  1. Run: ./install-retropie.sh' \
            '  2. Select "Basic Install"' \
            '  3. Wait for installation to complete' \
            '  4. Reboot' \
            '' \
            'Default credentials:' \
            '  User: retropie' \
            '  Pass: retropie' \
            '' \
            '===========================================' \
            > "${MOUNT_DIR}/root/etc/motd"
        ;;
esac

# Sync and unmount
log_info "Syncing filesystem..."
sync

log_info "Unmounting image..."
umount "${MOUNT_DIR}/boot" "${MOUNT_DIR}/root"
losetup -d "$LOOP_DEVICE"

# Compress image
log_info "Compressing image..."
IMAGE_NAME="radxa-cm5-uconsole_${DISTRO}_kernel-${KERNEL_VERSION}_$(date +%Y%m%d).img"
mv "${IMAGE_FILE}" "${OUTPUT_DIR}/${IMAGE_NAME}"
xz -z -9 -T$(nproc) "${OUTPUT_DIR}/${IMAGE_NAME}"

# Generate checksum
log_info "Generating checksum..."
cd "${OUTPUT_DIR}"
sha256sum "${IMAGE_NAME}.xz" > "${IMAGE_NAME}.xz.sha256"

log_info "Build complete!"
log_info "Image: ${OUTPUT_DIR}/${IMAGE_NAME}.xz"
log_info "Checksum: ${OUTPUT_DIR}/${IMAGE_NAME}.xz.sha256"
