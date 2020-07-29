### Vorraussetzung

* Proxmox 5.1 oder höher

### Installation innerhalb einer VM
Eventuelle USB Geräte in die VM durchleiten und innerhalb der VM eine [normale Installation](otheros.md) innerhalb der VM durchführen.

### Installation innerhalb eines (priviligierten) Containers
Aufgrund der Software Architektur der CCU braucht es spezielle Kernel Module, welche im Kontexts der Host laufen müssen, daher muss man sowohl im Host, als auch im Container Anpassungen vorgenommen werden.
Es darf nur einen einzigen (aktiven) Container mit debmatic geben.

#### Host
0. Volles Backup des Systems erstellen
1. Hinzufügen des debmatic apt Repositories
   ```bash
   wget -q -O - https://www.debmatic.de/debmatic/public.key | sudo apt-key add -
   sudo bash -c 'echo "deb https://www.debmatic.de/debmatic stable main" > /etc/apt/sources.list.d/debmatic.list'
   sudo apt update
   ```
3. Installation der Kernel Header
   ```bash 
   sudo apt install build-essential bison flex libssl-dev
   sudo apt install pve-headers
   ```
4. Installation der Host Pakete
   ```bash
   sudo apt install pivccu-modules-dkms debmatic-lxc-host
   ```
5. Falls ein HB-RF-ETH verwendet wird, Installation des benötigten Support Pakets
   ```bash
   sudo apt install hb-rf-eth
   ```
6. Erstellen des (priviligierten) Containers
7. Anpassen der Konfiguration des Containers, es müssen in der Datei /etc/pve/lxc/&lt;Container-ID&gt;.conf folgende beiden Zeilen eingefügt werden:
   ```
   lxc.apparmor.profile: unconfined
   lxc.hook.mount: /usr/share/debmatic/bin/lxc-start-hook.sh
   ```
8. Neustart des Containers

#### Container
### Installation
1. Notwendige Pakete für die Installation installieren (als Benutzer root)
   ```bash
   apt install sudo apt-transport-https gnupg
   ```
2. Hinzufügen des debmatic apt Repositories
   ```bash
   wget -q -O - https://www.debmatic.de/debmatic/public.key | sudo apt-key add -
   sudo bash -c 'echo "deb https://www.debmatic.de/debmatic stable main" > /etc/apt/sources.list.d/debmatic.list'
   sudo apt update
   ```
3. Installation von debmatic
   ```bash
   sudo apt install debmatic
   ```
4. Viel Spaß mit der Nutzung von debmatic
