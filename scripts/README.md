# Build Scripts

These scripts allow you to build Radxa CM5 uConsole images locally without using GitHub Actions.

## Prerequisites

### For Kernel Build
- Cross-compiler toolchain (aarch64)
- Build tools: `build-essential`, `bc`, `bison`, `flex`, `libssl-dev`, `libncurses5-dev`, `device-tree-compiler`

Install on Ubuntu/Debian:
```bash
sudo apt-get install build-essential bc bison flex libssl-dev libncurses5-dev \
    device-tree-compiler u-boot-tools dwarves git wget xz-utils kmod cpio

# Install ARM cross-compiler
wget https://developer.arm.com/-/media/Files/downloads/gnu/12.2.rel1/binrel/arm-gnu-toolchain-12.2.rel1-x86_64-aarch64-none-linux-gnu.tar.xz
sudo tar -xf arm-gnu-toolchain-12.2.rel1-x86_64-aarch64-none-linux-gnu.tar.xz -C /opt/
export PATH="/opt/arm-gnu-toolchain-12.2.rel1-x86_64-aarch64-none-linux-gnu/bin:$PATH"
```

### For Image Build
- Root access (sudo)
- Image tools: `wget`, `xz`, `kmod`, `cpio`, `rsync`, `dosfstools`, `parted`, `qemu-user-static`, `losetup`

Install on Ubuntu/Debian:
```bash
sudo apt-get install wget xz-utils kmod cpio rsync dosfstools parted \
    qemu-user-static binfmt-support pixz
```

## Usage

### 1. Build Kernel

```bash
# Build kernel with version suffix "1"
./scripts/build-kernel.sh 1

# Output:
#   build/output/kernel-packages/*.deb
#   build/output/overlays/*.dtbo
```

This will:
- Clone the kernel and overlay repositories
- Cross-compile the kernel
- Build Debian packages
- Compile device tree overlays

### 2. Build Image

```bash
# Build Debian image (requires sudo)
sudo ./scripts/build-image.sh debian 1

# Build Kali image
sudo ./scripts/build-image.sh kali 1

# Build RetroPie image
sudo ./scripts/build-image.sh retropie 1

# Output:
#   build/output/radxa-cm5-uconsole_<distro>_kernel-<version>_<date>.img.xz
#   build/output/radxa-cm5-uconsole_<distro>_kernel-<version>_<date>.img.xz.sha256
```

### Custom Base Image

You can provide a custom base image URL as the third argument:

```bash
sudo ./scripts/build-image.sh debian 1 "https://example.com/custom-image.img.xz"
```

## Environment Variables

### build-kernel.sh

- `KERNEL_REPO`: Git repository URL (default: `ak-rex/ClockworkRadxa-linux`)
- `KERNEL_BRANCH`: Git branch (default: `linux-6.1-stan-rkr4.1`)
- `OVERLAYS_REPO`: Overlays repository (default: `dev-null2019/radxa-cm5-uconsole`)
- `ARCH`: Target architecture (default: `arm64`)
- `CROSS_COMPILE`: Cross-compiler prefix (default: `aarch64-none-linux-gnu-`)

Example:
```bash
export KERNEL_REPO="https://github.com/my-fork/kernel.git"
export KERNEL_BRANCH="my-custom-branch"
./scripts/build-kernel.sh 1
```

## CI Script

The `build-kernel-ci.sh` script is used by GitHub Actions and assumes the kernel and overlay repositories are already cloned in the `build/` directory.

## Troubleshooting

### Kernel build fails
- Ensure cross-compiler is in PATH
- Check that all build dependencies are installed
- Verify you have enough disk space (kernel build requires ~15GB)

### Image build fails
- Must run as root (use `sudo`)
- Ensure kernel packages exist from previous build step
- Check for available loop devices: `losetup -f`
- Verify you have enough disk space (image build requires ~10GB)

### Loop device issues
If you get "loop device not found" errors:
```bash
# Check available loop devices
losetup -a

# Detach hung loop devices
sudo losetup -D
```

## Build Times

- Kernel build: 30-45 minutes (parallel compilation)
- Image build: 20-30 minutes per distro
- Total (kernel + 1 image): ~50-75 minutes

## Output Structure

```
build/
├── kernel/              # Cloned kernel source
├── overlays/            # Cloned overlay source
└── output/
    ├── kernel-packages/ # .deb files
    ├── overlays/        # .dtbo files
    ├── *.img.xz         # Compressed images
    └── *.img.xz.sha256  # Checksums
```
