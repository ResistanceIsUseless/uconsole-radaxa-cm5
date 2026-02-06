# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Automated GitHub Actions pipeline for building custom Radxa CM5 images for the ClockworkPi uConsole. The pipeline cross-compiles a Linux kernel, builds device tree overlays, and creates flashable images for multiple distributions (Debian, Kali, RetroPie).

## Key Source Repositories

- **Kernel**: `ak-rex/ClockworkRadxa-linux` (branch: `linux-6.1-stan-rkr4.1`)
- **Overlays**: `dev-null2019/radxa-cm5-uconsole`
- **Base Images**: Radxa official releases from `radxa-build/radxa-cm5-rpi-cm4-io`

## Build Commands

### Local Validation
```bash
# Run local validation before triggering CI/CD
./local-validate.sh

# With Docker (recommended)
docker run --rm -v "$(pwd):/work" -w /work ubuntu:22.04 ./local-validate.sh
```

This script validates:
- Kernel source accessibility
- Overlay compilation
- Workflow YAML syntax
- Build configuration

### Manual Workflow Triggers

The repository has **no automated triggers** - all builds are manual via GitHub Actions:

1. **Single image** (`.github/workflows/build-uconsole-image.yml` - currently missing, only multi-distro exists)
2. **All images** (`.github/workflows/build-all-images.yml`)

Parameters:
- `kernel_version`: Version suffix (default: "1") - increment for each build
- `base_image_url`: Custom base image URL (optional, single-image workflow only)

## Architecture

### Multi-Stage Pipeline (build-all-images.yml)

```
┌─────────────────┐
│  build-kernel   │  Compiles kernel once, creates shared artifacts
└────────┬────────┘
         │
    ┌────┴────┬────────────┬─────────────┐
    │         │            │             │
┌───▼───┐ ┌──▼────┐  ┌────▼─────┐  ┌────▼──────────────┐
│Debian │ │ Kali  │  │RetroPie  │  │release-notes      │
└───────┘ └───────┘  └──────────┘  └───────────────────┘
```

**Job 1: build-kernel**
- Installs ARM cross-compiler (GCC 12.2 from developer.arm.com)
- Clones kernel source
- Configures with `rockchip_linux_defconfig`
- Cross-compiles kernel, modules, DTBs
- Builds Debian packages via `bindeb-pkg`
- Compiles device tree overlays (`.dts` → `.dtbo`)
- Uploads artifacts (1-day retention)

**Jobs 2-4: build-{debian,kali,retropie}** (run in parallel)
- Download shared kernel artifacts
- Download base Radxa image
- Mount image partitions via loopback device
- Install kernel packages via chroot
- Copy overlays to boot partition
- Distribution-specific configuration:
  - **Kali**: Add Kali repos, configure GPG key
  - **RetroPie**: Create user, clone setup script, add first-boot instructions
- Compress with xz -9
- Generate SHA256 checksums
- Upload artifacts (30-day retention)

**Job 5: create-release-notes**
- Generates multi-distro installation guide
- Documents build metadata

### Image Mounting Pattern

All image build jobs use this pattern:
```bash
# Mount
sudo losetup -fP <image>.img
export LOOP_DEVICE=$(losetup -a | grep <image>.img | cut -d: -f1)
sudo mount ${LOOP_DEVICE}p1 /mnt/boot  # Boot partition
sudo mount ${LOOP_DEVICE}p2 /mnt/root  # Root partition

# Chroot operations
sudo chroot /mnt/root /bin/bash -c "commands..."

# Cleanup (always runs even on failure)
sudo umount /mnt/boot /mnt/root
sudo losetup -d $LOOP_DEVICE
```

## Configuration Constants

Environment variables set in workflows:
- `ARCH=arm64`
- `CROSS_COMPILE=aarch64-none-linux-gnu-`
- `DEBIAN_FRONTEND=noninteractive`
- `KERNEL_BRANCH=linux-6.1-stan-rkr4.1`

Cross-compiler path: `/opt/arm-gnu-toolchain-12.2.rel1-x86_64-aarch64-none-linux-gnu/bin`

## Hardware Support Matrix

**Working:**
- Display (IPS LCD), Keyboard (I2C), USB ports, Power management, 4G LTE, microSD

**Limitations:**
- WiFi/Bluetooth: Not available (CM5 hardware limitation)
- Audio: Mono only, experimental
- HDMI: Requires hardware modifications

**Workarounds:** USB WiFi/BT dongles, USB audio devices

## Modifying Builds

### Change Kernel Configuration

Edit workflow file, modify "Configure kernel" step:
```yaml
- name: Configure kernel
  working-directory: kernel
  run: |
    export ARCH=arm64
    export CROSS_COMPILE=aarch64-none-linux-gnu-
    make rockchip_linux_defconfig

    # Enable/disable features
    ./scripts/config --enable CONFIG_MODULE_NAME
    ./scripts/config --disable CONFIG_UNWANTED_FEATURE

    make olddefconfig
```

### Add Device Tree Overlays

Add `.dts` files to the overlays repository's `devicetree_overlays/` directory. They are automatically compiled during builds.

### Use Different Base Image

When triggering single-image workflow, set `base_image_url` parameter. Requirements:
- `.img.xz` format
- Compatible partition layout (boot + root)
- Accessible via wget

## GitHub Actions Optimization

**Free tier considerations:**
- Manual dispatch only (prevents accidental builds)
- Standard ubuntu-22.04 runners
- 30-day artifact retention
- No build caching (GitHub 10GB cache limit)
- Disk space maximization: removes dotnet, llvm, php, mongodb, mysql, azure-cli in first step

**Monitoring:** Check Actions tab for build progress, download artifacts immediately after success.

## Distribution Differences

All images use the **same kernel** with identical hardware support:

- **Debian Bookworm**: Base CLI system (~1.5 GB) - general purpose, development
- **Kali Linux**: Kali repos enabled (~1.8 GB) - security testing (tools installed on-demand)
- **RetroPie**: Gaming platform (~1.6 GB) - requires first-boot setup via `./install-retropie.sh`

Default credentials:
- Debian/Kali: `clockwork` / `clockwork`
- RetroPie: `retropie` / `retropie`

## Troubleshooting Patterns

**Build fails: out of disk space**
- Already removes unnecessary packages in workflow
- Consider reducing kernel modules or splitting jobs

**Build fails: mount/unmount errors**
- Workflow uses `if: always()` to ensure cleanup
- Check base image partition layout matches expectations
- Verify loop devices are available on runner

**Build fails: kernel compilation**
- Verify `KERNEL_BRANCH` matches upstream
- Check cross-compiler compatibility with kernel version
- Review kernel build logs for specific errors

## Security Considerations

- Kernel source: Pulled from known GitHub repository (ClockworkRadxa fork)
- Cross-compiler: Official ARM GCC toolchain from developer.arm.com
- Base images: Radxa official releases
- SHA256 checksums generated for all artifacts
- Consider pinning to specific commits instead of branch names for reproducibility
