#!/bin/bash

set -e

if [ "$EUID" != 0 ]; then
  echo "Please run as root" >&2
  exit 1
fi

if [ $# -ne 1 ]; then
  echo "create_webui_backup.sh <backupfile>" >&2
  exit 1
fi

BACKUPPATH=$1
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

if [ "$(systemctl is-active debmatic-rega.service)" == "active" ]; then
  echo "load tclrega.so; rega system.Save()" | /bin/tclsh
fi

cd /
tar czf "$TMPDIR/usr_local.tar.gz" etc/config --transform 's/^/usr\/local\//g'
crypttool -s -t 1 < "$TMPDIR/usr_local.tar.gz" > "$TMPDIR/signature"
crypttool -g -t 1 > "$TMPDIR/key_index"
cp /VERSION "$TMPDIR/firmware_version"
tar cf "$BACKUPPATH" -C "$TMPDIR" usr_local.tar.gz signature firmware_version key_index
