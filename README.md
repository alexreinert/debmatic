# debmatic&reg;

debmatic ist ein Projekt um eine Homematic CCU3 direkt unter Debian basierten Systemen zu betreiben.

### Ziele
* Betrieb der CCU unter Debian basierten Systemen
* Betrieb direkt ohne Nutzung einer Container Lösung
* Unterstützung von Single Board Computern und von x64 PC Hardware
* Unterstützung für Homematic und Homematic IP
* Einfache Installation und Update per apt
* Unterstützung für 
  * HM-MOD-RPI-PCB (HmRF + HmIP Funk)
  * RPI-RF-MOD (HmRF, HmIP Funk + HmIP Wired)
  * HmIP-RFUSB (HmRF, HmIP Funk + HmIP Wired)
  * HmIP-RFUSB-TK (Telekom Version, nur HmIP Funk, Firmware Updates nicht möglich, Funktionalität nicht dauerhaft sichergestellt)
  * HM-CFG-USB-2 (nur HmRF, nicht bei ARM64)
  * HM-LGW-O-TW-W-EU (nur HmRF)
  * [HB-RF-USB](https://github.com/alexreinert/PCB/tree/master/HB-RF-USB) (abhängig von Funkmodul)
  * [HB-RF-USB-2](https://github.com/alexreinert/PCB/tree/master/HB-RF-USB-2) (abhängig von Funkmodul)
  * [HB-RF-ETH](https://github.com/alexreinert/PCB/tree/master/HB-RF-ETH) (abhängig von Funkmodul)

### Unterstützung [<img src="https://ko-fi.com/img/githubbutton_sm.svg" height="20" alt="Support me on Ko-fi">](https://ko-fi.com/alexreinert) [<img src="https://img.shields.io/badge/donate-PayPal-green.svg" height="20" alt="Donate via Paypal">](https://www.paypal.com/donate/?cmd=_s-xclick&hosted_button_id=4PW43VJ2DZ7R2)
Die Entwicklung von debmatic ist sehr kostenintensiv, z.B. werden viele verschiedene Testgeräte benötigt. Allerdings erhält das Projekt keine Unterstützung durch kommerzielle Anbieter. Bitte unterstützen Sie die Entwicklung mit einer Spende via [Ko-fi](https://ko-fi.com/alexreinert), [PayPal](https://www.paypal.com/donate/?cmd=_s-xclick&hosted_button_id=4PW43VJ2DZ7R2) oder durch eine Aufmerksamkeit auf meinem [Amazon Wunschzettel](https://www.amazon.de/gp/registry/wishlist/3NNUQIQO20AAP/ref=nav_wishlist_lists_1).

### Voraussetzung
* Debian basiertes System (Debian, Ubuntu, Raspbian, Armbian)
* Mindestens Kernel 4.9 (Bei ARM64 mind. Kernel 4.14)

### Voraussetzung für HM-MOD-RPI-PCB und RPI-RF-MOD
* Unterstützter Single Board Computer
  * Raspberry Pi 2B/3B/3B+/4B mit Raspberry Pi OS Buster oder Bullseye
  * Asus Tinkerboard mit Armbian und Mainline kernel
  * Asus Tinkerboard S mit Armbian und Mainline kernel
  * Banana Pi M1 mit Armbian und Mainline kernel (LEDs vom RPI-RF-MOD werden hardwaremäßig nicht unterstützt)
  * Banana Pi Pro mit Armbian und Mainline kernel
  * Libre Computer AML-S905X-CC (Le Potato) mit Armbian und Mainline kernel
  * Odroid C2 mit Armbian und Mainline kernel (LEDs vom RPI-RF-MOD werden hardwaremäßig nicht unterstützt)
  * Odroid C4 mit Armbian und Mainline kernel (Experimentell, LEDs vom RPI-RF-MOD werden hardwaremäßig nicht unterstützt)
  * Orange Pi Zero, Zero Plus, R1 running Armbian with Mainline kernel (LEDs vom RPI-RF-MOD werden hardwaremäßig nicht unterstützt)
  * Orange Pi One, 2, Lite, Plus, Plus 2, Plus 2E, PC, PC Plus mit Armbian und Mainline kernel

    :warning: WARNUNG: Manche Orange Pis haben gedrehte Pinleisten. Die richtige Position von Pin 1 muss beachtet werden!
  * NanoPC T4 mit Armbian und Dev kernel

    :warning: WARNING: Die Stromversorgung muss über den NanoPC erfolgen auch wenn ein RPI-RF-MOD verwendet wird. Dieses darf dann nicht an ein Netzteil angeschlossen werden.
  * NanoPi M4 mit Armbian und Mainline kernel
  * Rock Pi 4 mit Armbian und Mainline kernel
  * Rock64 mit Armbian und Mainline kernel (Experimentell, LEDs vom RPI-RF-MOD werden hardwaremäßig nicht unterstützt)
  * RockPro64 mit Armbian und Mainline kernel

    :warning: WARNING: Die Stromversorgung muss über den RockPro64 erfolgen auch wenn ein RPI-RF-MOD verwendet wird. Dieses darf dann nicht an ein Netzteil angeschlossen werden.
* Nutzung auf anderen Systemen (auch x64 Systeme) kann per USB mit der Platine [HB-RF-USB](https://github.com/alexreinert/PCB/tree/master/HB-RF-USB) oder [HB-RF-USB-2](https://github.com/alexreinert/PCB/tree/master/HB-RF-USB-2) erfolgen.

### Vorbereite Images
Fertige SD Karten Images und ISO Images sind in Planung.

### Manuelle Installation
* [Raspberry Pi](docs/setup/raspberrypi.md)
* [Armbian](docs/setup/armbian.md)
* [Proxmox](docs/setup/proxmox.md)
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
Dieses Backup enthält nur die Einstellungen der CCU und ersetzt daher nicht ein Backup des Gesamtsystems.

### Restore
Ein Restore kann entweder über die WebUI erfolgen oder auf der Konsole über
```bash
sudo debmatic-restore $BACKUPFILE
```

### Addons
Addons können per apt installiert werden. Aktuell exitieren folgende Addons:
* [Cloudmatic Connect](https://www.cloudmatic.de) (Paketname cloudmatic)
* [CUxD](http://www.cuxd.de/) (Paketname cuxd)
* [JP HB Devices](https://github.com/jp112sdl/JP-HB-Devices-addon) (Ist bereits in debmatic enthalten)
* [Homematic check_mk addon](https://github.com/alexreinert/homematic_check_mk) (Paketname homematic-check-mk)
* [HB-TM-Devices](https://github.com/TomMajor/SmartHome) (Ist bereits in debmatic enthalten)
* [XML-API](https://github.com/jens-maus/XML-API) (Paketname xml-api)

### Restore
Backups können über die WebUI eingespielt werden.

### Migration von Original CCU, piVCCU oder RaspberryMatic
0. Backup des Systems machen
1. Addons auf CCU deinstallieren
2. Backup per WebUI erstellen
3. CCU abschalten
4. debmatic nach Anleitung installieren (piVCCU wird in diesem Schritt automatisch deinstalliert)
5. Backup aus Schritt 2. per WebUI einspielen
6. Notwendige Addons per apt nachinstallieren

### Credits / Danksagung
* [Jérôme](https://github.com/jp112sdl) für seine Homebrew Geräte und sein [Addon](https://github.com/jp112sdl/JP-HB-Devices-addon) für diese Geräte
* [TomMajor](https://github.com/TomMajor) für seine Homebrew Geräte und sein [Addon](https://github.com/TomMajor/SmartHome/HB-TP-Devices-AddOn) für diese Geräte

### Lizenz
debmatic selbst (die Dateien in diesem Repository) steht unter [Apache License 2.0](https://opensource.org/licenses/Apache-2.0).
Die generierten .deb Pakete enthalten auch das Homematic OCCU, welches unterschiedlichste Lizenen enthält.
Die verwendeten Kernel Module aus dem piVCCU Projekt stehen unter [GPLv2](http://www.gnu.org/licenses/gpl-2.0.html).

