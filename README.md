# winlink-rms-gateway
Winlink Packet RMS Gateway on Debian
# Hardware Used
- Transceiver
- Digirig Lite + Cable
- Dell Wyse 3040 Thin Client (8GB eMMC Flash / 2GB RAM)
- Edimax EW-7811Un Wi-Fi Adapter (Ethernet preferred)
- Monitor with DisplayPort (Used during setup)

# Software Used
- Debian 12.11 Bookworm (netinst)
- Direwolf 1.7
- LinBPQ 6.0.24.71

# Debian Install
- ***Ensure Digirig is disconnected while installing!***
- No root password set, which enables sudo for created user
- Select Use network mirror
- De-select Debian desktop environment
- De-select GNOME
- Select SSH server

# RMS Gateway Install
- On a fresh Debian installation:
  * Comment out the CD-ROM repository in `/etc/apt/sources.list`
  * Install git: `sudo apt update && sudo apt install git`
- Clone this repository
- `git clone https://github.com/kg4vdk/winlink-rms-gateway`
- Change into repository directory
- `cd winlink-rms-gateway`
- **Modify the variables at the top of `winlink-rms-gateway-build.sh`**
- `nano winlink-rms-gateway.sh`
- Run the script: `bash ./winlink-rms-gateway-build.sh`

# Manage RMS Gateway
- `monitor-services` opens in `tmux`
  * Exit `tmux` with `Ctrl+B`, followed by `D`
- `stop-services`, and `start-services`

# Notes
### Dell Wyse 3040 WILL NOT REBOOT if attached to a monitor.
- Power cycle to reboot (When running headless, this is not an issue)
### Dell Wyse 3040 BIOS Settings (F2 to access)
- Restore Settings (Factory)
- System Configuration
  * USB Configuration --> Enable USB Boot Support
  * Audio --> Disable Audio (Optional, but eliminates some kernel messages printing to the console)
- Maintenance
  * Data Wipe --> Wipe on Next Boot

### Dell Wyse 3040 EFI Fix
- Reboot into installer (F12 to select boot device)
  * Advanced --> Rescue Mode
  * Select `/dev/mmcblk0p2` as root file system
  * `mkdir -p /boot/efi/EFI/BOOT`
  * `cp /boot/efi/EFI/debian/grubx64.efi /boot/efi/EFI/BOOT/BOOTX64.EFI`
  * `CTL+D` to exit shell
  * Reboot the system (remove the installer USB)
