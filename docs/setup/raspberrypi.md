### Vorraussetzung

* Raspberry Pi 2B/3B/3B+/4B
* Raspbian Stretch oder Raspbian Buster

### Installation
0. Volles Backup der SD Karte erstellen
1. Hinzufügen des debmatic apt Repositories
   ```bash
   wget -q -O - https://www.debmatic.de/debmatic/public.key | sudo apt-key add -
   sudo bash -c 'echo "deb https://www.debmatic.de/debmatic stable main" > /etc/apt/sources.list.d/debmatic.list'
   sudo apt update
   ```
3. Installation der Kernel Module
   ```bash
   sudo apt install build-essential bison flex libssl-dev
   sudo apt install raspberrypi-kernel-headers pivccu-modules-dkms
   ```
4. Falls ein HB-RF-ETH verwendet wird, Installation des benötigten Support Pakets
   ```bash
   sudo apt install hb-rf-eth
   ```
5. Installation der Device Tree Patches (Dieser Schritt kann übersprungen werden, falls kein Funkmodul direkt auf die GPIO Leiste aufgesteckt wird)
   ```bash
   sudo apt install pivccu-modules-raspberrypi
   ```
6. UART Schnittstelle der GPIO Leiste aktivieren (Dieser Schritt kann übersprungen werden, falls kein Funkmodul direkt auf die GPIO Leiste aufgesteckt wird oder falls ein Raspberry Pi 2B eingesetzt wird)
   * Option 1: Bluetooth deaktivieren
      ```bash
      sudo bash -c 'cat << EOT >> /boot/config.txt
      dtoverlay=pi3-disable-bt
      EOT'
      sudo systemctl disable hciuart.service
      ```
   * Option 2: Bluetooth über Soft-UART betreiben
      ```bash
      sudo bash -c 'cat << EOT >> /boot/config.txt
      dtoverlay=pi3-miniuart-bt
      enable_uart=1
      force_turbo=1
      core_freq=250
      EOT'
      ```
7. Serielle Konsole deaktivieren (Dieser Schritt kann übersprungen werden, falls kein Funkmodul direkt auf die GPIO Leiste aufgesteckt wird)
   ```bash
   sudo sed -i /boot/cmdline.txt -e "s/console=serial0,[0-9]\+ //"
   sudo sed -i /boot/cmdline.txt -e "s/console=ttyAMA0,[0-9]\+ //"
   ```
8. Neustart
   ```bash
   sudo reboot
   ```
9. Installation von debmatic
   ```bash
   sudo apt install debmatic
   ```
10. Viel Spaß mit der Nutzung von debmatic

