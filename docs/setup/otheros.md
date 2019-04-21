### Vorraussetzung

* Debian oder Ubuntu
* Mind. Kernel 4.9

### Installation
0. Volles Backup des Systems erstellen
1. Notwendige Pakete für die Installation installieren (als Benutzer root)
   ```bash
   apt install sudo apt-transport-https
   ```
2. Hinzufügen des debmatic apt Repositories
   ```bash
   wget -q -O - https://www.debmatic.de/debmatic/public.key | sudo apt-key add -
   sudo bash -c 'echo "deb https://www.debmatic.de/debmatic stable main" > /etc/apt/sources.list.d/debmatic.list'
   sudo apt update
   ```
3. Ggf. Update auf Kernel >= 4.9
4. Installation der Kernel Header (dieser Schritt ist abhängig von Distribution und verwendetem Kernel, bitte in der Hilfe der Distribution nachschlagen)
5. Installation der Kernel Module
   ```bash
   sudo apt install pivccu-modules-dkms
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

