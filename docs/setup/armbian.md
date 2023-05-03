### Vorraussetzung

* Armbian
* Mind. Kernel 4.9

### Installation
0. Volles Backup der SD Karte erstellen
1. Hinzufügen des debmatic apt Repositories
   ```bash
   wget -q -O - https://apt.debmatic.de/debmatic/public.key | sudo tee /usr/share/keyrings/debmatic.asc
   echo "deb [signed-by=/usr/share/keyrings/debmatic.asc] https://apt.debmatic.de/debmatic stable main" | sudo tee /etc/apt/sources.list.d/debmatic.list
   sudo apt update
   ```
3. Installation der Kernel Header
   ```bash
   sudo apt install build-essential bison flex libssl-dev
   sudo apt install `dpkg --get-selections | grep 'linux-image-' | grep '\sinstall' | sed -e 's/linux-image-\([a-z0-9-]\+\).*/linux-headers-\1/'`
   ```
4. Installation der Kernel Module
   ```bash
   sudo apt install pivccu-modules-dkms
   ```
5. Falls ein HB-RF-ETH verwendet wird, Installation des benötigten Support Pakets
   ```bash
   sudo apt install hb-rf-eth
   ```
6. Installation der Device Tree Patches (Dieser Schritt kann übersprungen werden, falls kein Funkmodul direkt auf die GPIO Leiste aufgesteckt wird)
   ```bash
   sudo apt install pivccu-devicetree-armbian
   ```
7. Neustart
   ```bash
   sudo reboot
   ```
8. Installation von debmatic
   ```bash
   sudo apt install debmatic
   ```
9. Viel Spaß mit der Nutzung von debmatic

