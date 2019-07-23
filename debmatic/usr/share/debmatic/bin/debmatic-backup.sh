#!/bin/bash

set -e

if [ $EUID != 0 ]; then
  echo "Please run as root"
  exit
fi

if [ $# -ne 1 ] || [ ! -d "$1" ]; then
  echo "debmatic-backup <backupdir>"
  exit 1
fi

CURDIR=`pwd`

BACKUPPATH="$1/`hostname`_`date '+%Y-%m-%d_%H-%M-%S'`.sbk"
BACKUPPATH=`realpath $BACKUPPATH`

if [ `systemctl is-active debmatic-rega.service` == "active" ]; then
  echo "load tclrega.so; rega system.Save()" | /bin/tclsh
fi

TMPDIR=`mktemp -d`

cd /
tar czf $TMPDIR/usr_local.tar.gz etc/config --transform 's/^/usr\/local\//g'

crypttool -s -t 1 < $TMPDIR/usr_local.tar.gz > $TMPDIR/signature
crypttool -g -t 1 > $TMPDIR/key_index
cp /boot/VERSION $TMPDIR/firmware_version

cd $TMPDIR

tar cf $BACKUPPATH usr_local.tar.gz signature firmware_version key_index

cd $CURDIR
rm -rf $TMPDIR

echo "Backup written to $BACKUPPATH"
