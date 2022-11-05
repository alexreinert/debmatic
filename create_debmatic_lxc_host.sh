#!/bin/bash

PKG_BUILD=6

CURRENT_DIR=$(pwd)
WORK_DIR=$(mktemp -d)

PKG_VERSION=1.0.$PKG_BUILD

umask 0022 # use root default umask (0022), instead of default user umask (0002)

cd $WORK_DIR

TARGET_DIR=$WORK_DIR/debmatic-lxc-host-$PKG_VERSION

mkdir -p $TARGET_DIR

cp -pR $CURRENT_DIR/debmatic-lxc-host/* $TARGET_DIR 

for file in $TARGET_DIR/DEBIAN/*; do
  sed -i "s/{PKG_VERSION}/$PKG_VERSION/g" $file
done

fakeroot dpkg-deb --build debmatic-lxc-host-$PKG_VERSION

cp debmatic-*.deb $CURRENT_DIR

echo "Please clean-up the work dir temp folder $WORK_DIR, e.g. by doing rm -R $WORK_DIR"

