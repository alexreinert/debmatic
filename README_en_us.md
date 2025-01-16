# debmatic&reg;

debmatic is a project to operate a Homematic CCU3 directly on Debian-based systems.

### Objectives
* Run the CCU on Debian-based systems
* Direct operation without using a container solution
* Support for single-board computers and x64 PC hardware
* Support for Homematic and Homematic IP
* Simple installation and updates via apt
* Support for
  * HM-MOD-RPI-PCB (HmRF + HmIP wireless)
  * RPI-RF-MOD (HmRF, HmIP wireless + HmIP wired)
  * HmIP-RFUSB (HmRF, HmIP wireless + HmIP wired)
  * HmIP-RFUSB-TK (Telekom version, HmIP wireless only, firmware updates not possible, functionality not guaranteed)
  * HM-CFG-USB-2 (HmRF only, not on ARM64)
  * HM-LGW-O-TW-W-EU (HmRF only)
  * [HB-RF-USB](https://github.com/alexreinert/PCB/tree/master/HB-RF-USB) (depends on wireless module)
  * [HB-RF-USB-2](https://github.com/alexreinert/PCB/tree/master/HB-RF-USB-2) (depends on wireless module)
  * [HB-RF-ETH](https://github.com/alexreinert/PCB/tree/master/HB-RF-ETH) (depends on wireless module)

### Support [<img src="https://ko-fi.com/img/githubbutton_sm.svg" height="20" alt="Support me on Ko-fi">](https://ko-fi.com/alexreinert) [<img src="https://img.shields.io/badge/donate-PayPal-green.svg" height="20" alt="Donate via Paypal">](https://www.paypal.com/donate/?cmd=_s-xclick&hosted_button_id=4PW43VJ2DZ7R2)
The development of debmatic is costly, requiring various test devices. As this project does not receive commercial support, please consider contributing via [Ko-fi](https://ko-fi.com/alexreinert), [PayPal](https://www.paypal.com/donate/?cmd=_s-xclick&hosted_button_id=4PW43VJ2DZ7R2), or my [Amazon Wishlist](https://www.amazon.de/gp/registry/wishlist/3NNUQIQO20AAP/ref=nav_wishlist_lists_1).

### Requirements
* Debian-based system (Debian, Ubuntu, Raspbian, Armbian)
* Kernel version 4.9 or higher (for ARM64, kernel 4.14 or higher)

### Requirements for HM-MOD-RPI-PCB and RPI-RF-MOD
* Supported Single Board Computers:
  * Raspberry Pi 2B/3B/3B+/4B/5B with Raspberry Pi OS Bullseye or Bookworm
  * Asus Tinkerboard with Armbian and Mainline kernel
  * Asus Tinkerboard S with Armbian and Mainline kernel
  * Banana Pi M1 with Armbian and Mainline kernel (RPI-RF-MOD LEDs are not supported at the hardware level)
  * Banana Pi Pro with Armbian and Mainline kernel
  * Libre Computer AML-S905X-CC (Le Potato) with Armbian and Mainline kernel
  * Odroid C2 with Armbian and Mainline kernel (RPI-RF-MOD LEDs are not supported at the hardware level)
  * Odroid C4 with Armbian and Mainline kernel (experimental, RPI-RF-MOD LEDs not supported at hardware level)
  * Orange Pi Zero, Zero Plus, R1 running Armbian with Mainline kernel (RPI-RF-MOD LEDs are not supported at hardware level)
  * Orange Pi One, 2, Lite, Plus, Plus 2, Plus 2E, PC, PC Plus with Armbian and Mainline kernel

    :warning: WARNING: Some Orange Pis have rotated pin headers. Ensure the correct position of Pin 1!
  * NanoPC T4 with Armbian and Dev kernel

    :warning: WARNING: Power must be supplied through the NanoPC even when using the RPI-RF-MOD. It should not be connected to an external power source.
  * NanoPi M4 with Armbian and Mainline kernel
  * Rock Pi 4 with Armbian and Mainline kernel
  * Rock64 with Armbian and Mainline kernel (experimental, RPI-RF-MOD LEDs are not supported at the hardware level)
  * RockPro64 with Armbian and Mainline kernel

    :warning: WARNING: Power must be supplied through the RockPro64, even when using the RPI-RF-MOD. It should not be connected to an external power source.
* On other systems (including x64 systems), the [HB-RF-USB](https://github.com/alexreinert/PCB/tree/master/HB-RF-USB) or [HB-RF-USB-2](https://github.com/alexreinert/PCB/tree/master/HB-RF-USB-2) boards can be used via USB.

### Prepared Images
Complete SD card images and ISO images are planned for future release.

### Manual Installation
* [Raspberry Pi](docs/setup/raspberrypi.md)
* [Armbian](docs/setup/armbian.md)
* [Proxmox](docs/setup/proxmox.md)
* [Andere Systeme](docs/setup/otheros.md)

### Updates
Updates are applied through the standard Debian update process:
```bash
sudo apt update && sudo apt upgrade
```

### Backup
A backup can be created either via the WebUI or in the console through 
```bash
sudo debmatic-backup
```
This backup only includes the settings of the CCU and does not replace a full system backup.

### Addons
Addons can be installed via apt. The following addons are currently available:
* [Cloudmatic Connect](https://www.cloudmatic.de) (Package name cloudmatic)
* [CUxD](http://www.cuxd.de/) (Package name cuxd)
* [JP HB Devices](https://github.com/jp112sdl/JP-HB-Devices-addon) (Is already included in debmatic)
* [Homematic check_mk addon](https://github.com/alexreinert/homematic_check_mk) (Package name homematic-check-mk)
* [HB-TM-Devices](https://github.com/TomMajor/SmartHome) (Is already included in debmatic)
* [XML-API](https://github.com/jens-maus/XML-API) (Package name xml-api)

### Restore
Backups can be restored via the WebUI.

### Migration from Original CCU, piVCCU, or RaspberryMatic
0. Create a system backup
1. Uninstall addons on the CCU
2. Create a backup via the WebUI
3. Power off the CCU
4. Install debmatic as per the instructions (piVCCU will automatically uninstall in this step)
5. Restore the backup from Step 2 via the WebUI
6. Reinstall necessary addons via apt

### Credits / Acknowledgments
* [Jérôme](https://github.com/jp112sdl) for his homebrew devices and his [addon](https://github.com/jp112sdl/JP-HB-Devices-addon) for these devices
* [TomMajor](https://github.com/TomMajor) for his homebrew devices and his [addon](https://github.com/TomMajor/SmartHome/HB-TP-Devices-AddOn) for these devices

### License
debmatic itself (the files in this repository) is licensed under the [Apache License 2.0](https://opensource.org/licenses/Apache-2.0).
The generated .deb packages also include the Homematic OCCU, which contains various licenses.
The kernel modules from the piVCCU project are licensed under [GPLv2](http://www.gnu.org/licenses/gpl-2.0.html).
