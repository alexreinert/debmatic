#!/bin/bash

ADDON_DIR=/usr/share/cloudmatic

. $ADDON_DIR/mhcfg

newver=`wget -q -O - --post-data="id=$userid&key=$userkey" https://www.meine-homematic.de/getverv3.php`
oldver=`cat $ADDON_DIR/oldver`

if [ $oldver -lt $newver ]; then
  TMPDIR=`mktemp -d`

  wget -q -O $TMPDIR/vpnkey_ccu2.tar.gz --post-data="id=$userid&key=$userkey" https://www.meine-homematic.de/getkeyccu2v3.php

  tar xzf $TMPDIR/vpnkey_ccu2.tar.gz -C $TMPDIR

  cp $TMPDIR/{client.conf,client.crt,client.key,cmid,mhca.crt,mhcfg} $ADDON_DIR/
  cp $TMPDIR/newver $ADDON_DIR/oldver

  sed -e "s|/usr/local/etc/config/addons/mh/|/usr/share/cloudmatic/|" -i $ADDON_DIR/client.conf

  rm -rf $TMPDIR

  systemctl reload cloudmatic-openvpn.service || true
fi

