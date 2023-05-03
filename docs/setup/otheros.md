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
   wget -q -O - https://apt.debmatic.de/debmatic/public.key | sudo tee /usr/share/keyrings/debmatic.asc
   echo "deb [signed-by=/usr/share/keyrings/debmatic.asc] https://apt.debmatic.de/debmatic stable main" | sudo tee /etc/apt/sources.list.d/debmatic.list
   sudo apt update
   ```
3. Ggf. Update auf Kernel >= 4.9
4. Installation der Pakete, welche für das Bauen von Kernel Modulen notwendig sind
   ```bash
   sudo apt install build-essential bison flex libssl-dev
   ```
5. Installation der Kernel Header (dieser Schritt ist abhängig von Distribution und verwendetem Kernel, bitte in der Hilfe der Distribution nachschlagen)
6. Installation der Kernel Module
   ```bash
   sudo apt install pivccu-modules-dkms
   ```
7. Falls ein HB-RF-ETH verwendet wird, Installation des benötigten Support Pakets
   ```bash
   sudo apt install hb-rf-eth
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

