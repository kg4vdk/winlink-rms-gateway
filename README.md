# winlink-rms-gateway
Winlink Packet RMS Gateway on Debian
# Hardware
- Yaesu FT-2980R
- Digirig + Cable
- Dell Wyse 3040 Thin Client (8GB eMMC Flash / 2GB RAM)
- Edimax EW-7811Un Wi-Fi Adapter (Ethernet preferred)
- Monitor with DisplayPort (Used during setup)

# Software
- Debian 12.7 Bookworm
- Direwolf 1.7
- LinBPQ 6.0.24.47
- Tor (to enable remote SSH access without port forwarding)

# RMS Gateway Install
- On a fresh Debian installation:
  * Comment out the CD-ROM repository in `/etc/apt/sources.list`
  * Install git: `sudo apt update && sudo apt install git`
- Clone this repository
- **Modify the variables at the top of `winlink-rms-gateway-build.sh`**
- Run the script: `bash winlink-rms-gateway-build.sh`

# Notes
### Dell Wyse 3040 BIOS Settings (F2 to access)
- Restore Settings (Factory)
- System Configuration
  * USB Configuration --> Enable USB Boot Support
  * Audio --> Disable Audio (Optional, but eliminates some kernel messages printing to the console)
- Maintenance
  * Data Wipe --> Wipe on Next Boot
  
### Debian Install on Dell Wyse 3040
- ***Ensure Digirig is disconnected while installing!***
- No root password set, which enables sudo for created user
- Use network mirror
- Deselect Debian desktop environment
- Deselect GNOME
- Select SSH server
- Reboot into installer (F12 to select boot device)
  * Advanced --> Rescue Mode
  *  /dev/mmcblk0p2 as root file system
  * mkdir -p /boot/efi/EFI/BOOT
  * cp /boot/efi/EFI/debian/grubx64.efi /boot/efi/EFI/BOOT/BOOTX64.EFI
  * CTL+D to exit shell
  * Reboot the system (remove the installer USB)
  * ***The Wyse 3040 WILL NOT REBOOT if attached to a monitor.***
    - When running headless, this is not an issue.
