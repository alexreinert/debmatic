### Vorraussetzung

* Proxmox 5.1 oder höher

### Installation innerhalb einer VM
Eventuelle USB Geräte in die VM durchleiten und innerhalb der VM eine [normale Installation](otheros.md) durchführen.

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
##### Installation
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

#### Troubleshooting
1. Wenn bei der Installation im Container eine Fehlermeldung der Form
   ```bash
   Error! There are no instances of module: pivccu
   [...]
   Error! Your kernel headers for kernel 5.4.174-2-pve cannot be found.
   Please install the linux-headers-5.4.174-2-pve package,
   ```
   auftritt gibt es dafür zwei mögliche Ursachen:
   
   a) 
   Die Installationspakete für den Host `pivccu-modules-dkms` und `debmatic-lxc-host` wurden fälschlicherweise im Container ausgeführt.

   b)
   Aufgrund einer  Abhängigkeit von `debmatic` zu `pivccu-modules-dkms` wurde dies auf dem Container bei der Installation von `debmatic` automatisch installiert. Es kann entfernt werden via
   ```bash
   sudo apt remove pivccu-modules-dkms
   ```
   Siehe hierzu Issue #300.
