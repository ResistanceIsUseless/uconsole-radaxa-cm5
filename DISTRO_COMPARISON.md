# Distribution Comparison Guide

Quick reference for choosing the right Radxa CM5 uConsole image.

## At a Glance

| Feature | Debian Bookworm | Kali Linux | RetroPie |
|---------|----------------|------------|----------|
| **Size** | ~1.5 GB | ~1.8 GB | ~1.6 GB |
| **Boot Time** | Fast | Fast | Fast |
| **Setup Required** | Minimal | Minimal | Yes (first boot) |
| **Primary Use** | General purpose | Security/Pentesting | Gaming/Emulation |
| **Package Manager** | apt | apt | apt + RetroPie |
| **Default Tools** | Basic CLI | Kali repos | Emulators (post-setup) |
| **Storage Needed** | 8GB+ | 16GB+ | 32GB+ |
| **Skill Level** | Beginner | Intermediate | Beginner |

## Debian Bookworm

**Best for:**
- Development and programming
- Server applications
- Custom projects
- Learning Linux

**Pre-installed:**
- Base system utilities
- SSH server
- Network tools
- Python 3

**Pros:**
- Lightweight and stable
- Fast boot times
- Maximum customization
- Well-documented

**Cons:**
- Requires manual tool installation
- Minimal out-of-box features

**Storage recommendation:** 8GB minimum, 16GB+ for development

---

## Kali Linux

**Best for:**
- Network security testing
- Penetration testing
- Security research
- CTF competitions

**Pre-installed:**
- Base Debian system
- Kali repositories configured
- SSH server
- Network tools

**Available tools (install on-demand):**
```bash
# Top 10 security tools
sudo apt-get install kali-tools-top10

# Web application testing
sudo apt-get install kali-tools-web

# Wireless testing (with USB adapters)
sudo apt-get install kali-tools-wireless

# All tools (requires 30GB+)
sudo apt-get install kali-linux-everything
```

**Pros:**
- Purpose-built for security
- Extensive tool repository
- Regular updates
- Active community

**Cons:**
- Larger install size
- Tools not pre-installed (by design)
- Requires security knowledge

**Storage recommendation:** 16GB minimum, 32GB+ for full toolset

**Security note:** Change default password immediately after first boot.

---

## RetroPie

**Best for:**
- Retro gaming
- Portable emulation station
- Media center (with Kodi)
- Family entertainment

**Requires first-boot setup:**
1. Log in as `retropie` / `retropie`
2. Run: `./install-retropie.sh`
3. Select "Basic Install"
4. Wait 30-60 minutes for installation
5. Reboot

**Supported emulators (after setup):**
- NES, SNES, Genesis/Mega Drive
- Game Boy, Game Boy Advance
- PlayStation 1
- Nintendo 64
- Arcade (MAME)
- And many more...

**Input:**
- uConsole keyboard mappings
- USB gamepad support
- Bluetooth controllers (with USB adapter)

**Performance notes:**
- 8-bit/16-bit systems: Excellent
- PSX: Good
- N64: Mixed (some games slow)
- GameCube/PS2: Not recommended

**Pros:**
- Easy gaming setup
- Automatic ROM scanning
- Wireless controller support
- Save state support

**Cons:**
- Large setup time (first boot)
- ROMs not included (legal requirement)
- Performance varies by system

**Storage recommendation:** 32GB minimum (64GB+ for large ROM collection)

---

## Common to All Images

### Hardware Support
- ✅ Display (5" IPS)
- ✅ Keyboard
- ✅ USB-A and USB-C ports
- ✅ Battery/Power management
- ✅ microSD card
- ✅ 4G LTE module

### Limitations
- ❌ No WiFi/BT (use USB dongles)
- ⚠️ Audio: mono only
- ⚠️ HDMI: requires adapter board (uConsole Upgrade Kit)

### Credentials
- **Debian:** `clockwork` / `clockwork`
- **Kali:** `clockwork` / `clockwork` (change ASAP!)
- **RetroPie:** `retropie` / `retropie`

### Same Kernel
All images use identical kernel:
- Linux 6.1.x with ClockworkRadxa patches
- Same hardware drivers
- Same performance
- Same compatibility

---

## Use Case Examples

### "I want to learn programming"
→ **Debian** - Clean slate, install what you need

### "I'm studying cybersecurity"
→ **Kali** - Industry-standard security tools

### "I want a portable game console"
→ **RetroPie** - Plug and play retro gaming

### "I need a development environment for IoT"
→ **Debian** - Lightweight base for custom builds

### "I'm doing WiFi security testing"
→ **Kali** + USB WiFi adapter with monitor mode

### "I want to play classic games on the go"
→ **RetroPie** + 64GB microSD for ROMs

---

## Switching Distributions

You can switch between distributions by:

1. **Clean install:** Flash different image to microSD
2. **Dual boot:** Use multiple microSD cards, swap as needed
3. **Kernel update only:** Keep your OS, update just the kernel

### Kernel-only update (advanced)
```bash
# Download kernel packages from build artifacts
wget <kernel-packages-url>/*.deb

# Install
sudo dpkg -i linux-image-*.deb
sudo dpkg -i linux-headers-*.deb
sudo apt-get install -f
sudo update-initramfs -u -k all
sudo reboot
```

---

## FAQ

**Q: Can I run Kali tools on Debian?**  
A: Yes, add Kali repos to Debian. However, official Kali image is tested and recommended.

**Q: Can I install desktop environment?**  
A: Yes, all images support `apt-get install` of XFCE, LXDE, etc. Not recommended due to performance.

**Q: Which image is fastest?**  
A: All boot at same speed. Debian uses least RAM. RetroPie uses most CPU when gaming.

**Q: Can I resize partitions after flashing?**  
A: Yes, use `raspi-config` or manual partition tools. All images auto-expand root on first boot.

**Q: Which should I choose for general use?**  
A: Debian - most versatile, smallest, easiest to customize.

---

**Last updated:** January 2025
