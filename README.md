# debmatic

debmatic ist ein Projekt um eine Homematic CCU3 direkt unter Debian basierten Systemen zu betreiben.

## Beta-Status
debmatic befindet sich momentan noch im Betastatus!

### Ziele
* Betrieb der CCU unter Debian basierten Systemen
* Betrieb direkt ohne Nutzung einer Container Lösung
* Unterstützung von Single Board Computern und von x64 PC Hardware
* Unterstützung für Homematic und Homematic IP
* Einfache Installation und Update per apt
* Unterstützung für 
  * HM-MOD-RPI-PCB (HmRF + HmIP Funk)
  * RPI-RF-MOD (HmRF, HmIP Funk + HmIP Wired)
  * HmIP-RFUSB (nur HmIP Funk)
  * HmIP-RFUSB-TK (Telekom Version, nur HmIP Funk, Firmware Updates nicht möglich, Funktionalität nicht dauerhaft sichergestellt)
  * HM-CFG-USB-2 (nur HmRF)
  * HM-LGW-O-TW-W-EU (nur HmRF)
  * [HB-RF-USB](https://github.com/alexreinert/PCB/tree/master/HB-RF-USB) (abhängig von Funkmodul)

### Unterstützung [![Spenden](https://img.shields.io/badge/donate-PayPal-green.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=WUC7QU84EU7DA)
Die Entwicklung von debmatic ist sehr kostenintensiv, z.B. werden viele verschiedene Testgeräte benötigt. Allerdings erhält das Projekt keine Unterstützung durch kommerzielle Anbieter. Bitte unterstützen Sie die Entwicklung mit einer Spende via [PayPal](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=WUC7QU84EU7DA) oder durch eine Aufmerksamkeit auf meinem [Amazon Wunschzettel](https://www.amazon.de/gp/registry/wishlist/3NNUQIQO20AAP/ref=nav_wishlist_lists_1).

### Vorraussetzung
* Debian basiertes System (Debian, Ubuntu, Raspbian, Armbian)
* Mindestens Kernel 4.9

### Vorraussetzung für HM-MOD-RPI-PCB und RPI-RF-MOD 
* Unterstützter Single Board Computer
  * Raspberry Pi 2B/3B/3B+ mit Raspbian Stretch
  * Asus Tinkerboard mit Armbian und Mainline kernel
  * Asus Tinkerboard S mit Armbian und Mainline kernel
  * Banana Pi M1 mit Armbian und Mainline kernel (LEDs vom RPI-RF-MOD werden hardwaremäßig nicht unterstützt)
  * Banana Pi Pro mit Armbian und Mainline kernel
  * Libre Computer AML-S905X-CC (Le Potato) mit Armbian und Mainline kernel
  * Odroid C2 mit Armbian und Mainline kernel (LEDs vom RPI-RF-MOD werden hardwaremäßig nicht unterstützt)
  * Orange Pi Zero, Zero Plus, R1 running Armbian with Mainline kernel (LEDs vom RPI-RF-MOD werden hardwaremäßig nicht unterstützt)
  * Orange Pi One, 2, Lite, Plus, Plus 2, Plus 2E, PC, PC Plus mit Armbian und Mainline kernel

    :warning: WARNUNG: Manche Orange Pis haben gedrehte Pinleisten. Die richtige Position von Pin 1 muss beachtet werden!
  * NanoPC T4 mit Armbian und Dev kernel

    :warning: WARNING: Die Stromversorgung muss über den NanoPC erfolgen auch wenn ein RPI-RF-MOD verwendet wird. Dieses darf dann nicht an ein Netzteil angeschlossen werden.
  * NanoPi M4 mit Armbian und Dev kernel (Experimental)
  * Rock64 mit Armbian und Dev kernel (Experimental) (LEDs vom RPI-RF-MOD werden hardwaremäßig nicht unterstützt)
* Nutzung auf anderen Systemen (auch x64 Systeme) kann per USB mit der Platine [HB-RF-USB](https://github.com/alexreinert/PCB/tree/master/HB-RF-USB) erfolgen.

### Vorbereite Images
Fertige SD Karten Images und ISO Images sind in Planung.

### Manuelle Installation
* [Raspberry Pi](docs/setup/raspberrypi.md)
* [Armbian](docs/setup/armbian.md)
* [Andere Systeme](docs/setup/otheros.md)

### Updates
Updates werden über den normalen Debian Weg eingespielt:
```bash
sudo apt update && sudo apt upgrade
```

### Backup
Ein Backup kann entweder über die WebUI erfolgen oder auf der Konsole über
```bash
sudo debmatic-backup
```

### Addons
Addons können per apt installiert werden. Aktuell exitieren folgende Addons:
* [CUxD](http://www.cuxd.de/) (Paketname cuxd)
* [JP HB Devices](https://github.com/jp112sdl/JP-HB-Devices-addon) (Paketname jp-hb-devices)
* [Homematic check_mk addon](https://github.com/alexreinert/homematic_check_mk) (Paketname homematic-check-mk)
* [HB-UNI-Sensor1](https://github.com/TomMajor/SmartHome) (Paketname hb-uni-sensor1)
* [HB-SEN-LJet](https://github.com/TomMajor/SmartHome) (Paketname hb-sen-ljet)

### Restore
Backups können über die WebUI eingespielt werden.

### Migration von Original CCU
...

### Migration von RaspberryMatic
...

### Migration von piVCCU
...

### Lizenz
debmatic selbst (die Dateien in diesem Repository) steht unter [Apache License 2.0](https://opensource.org/licenses/Apache-2.0).
Die generierten .deb Pakete enthalten auch das Homematic OCCU, welches unterschiedlichste Lizenen enthält.
Die verwendeten Kernel Module aus dem piVCCU Projekt stehen unter [GPLv2](http://www.gnu.org/licenses/gpl-2.0.html).

