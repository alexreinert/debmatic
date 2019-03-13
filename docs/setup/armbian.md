### Vorraussetzung

* Armbian
* Mind. Kernel 4.9

### Installation
0. Volles Backup der SD Karte erstellen
1. Hinzufügen des debmatic apt Repositories
   ```bash
   wget -q -O - https://www.debmatic.de/debmatic/public.key | sudo apt-key add -
   sudo bash -c 'echo "deb https://www.debmatic.de/debmatic stable main" > /etc/apt/sources.list.d/debmatic.list'
   sudo apt update
   ```
3. Installation der Kernel Header
   ```bash
   sudo apt install `dpkg --get-selections | grep 'linux-image-' | grep '\sinstall' | sed -e 's/linux-image-\([a-z0-9-]\+\).*/linux-headers-\1/'`
   ```
4. Installation der Kernel Module
   ```bash
   sudo apt install pivccu-modules-dkms
   ```
5. Installation der Device Tree Patches (Dieser Schritt kann übersprungen werden, falls kein Funkmodul direkt auf die GPIO Leiste aufgesteckt wird)
   ```bash
   sudo apt install pivccu-devicetree-armbian
   ```
6. Neustart
   ```bash
   sudo reboot
   ```
7. Installation von debmatic
   ```bash
   sudo apt install debmatic
   ```
8. Viel Spaß mit der Nutzung von debmatic

