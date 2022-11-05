#!/bin/bash

ADDON_VERSION=1.3

PKG_BUILD=2

CURRENT_DIR=$(pwd)
WORK_DIR=$(mktemp -d)

PKG_VERSION=$ADDON_VERSION-$PKG_BUILD

umask 0022 # use root default umask (0022), instead of default user umask (0002)

cd $WORK_DIR

TARGET_DIR=$WORK_DIR/homematic-check-mk-$PKG_VERSION

mkdir -p $TARGET_DIR

cp -a $CURRENT_DIR/homematic-check-mk/* $TARGET_DIR 

for file in $TARGET_DIR/DEBIAN/*; do
  sed -i "s/{PKG_VERSION}/$PKG_VERSION/g" $file
done

cd $WORK_DIR

fakeroot dpkg-deb --build homematic-check-mk-$PKG_VERSION

cp homematic-check-mk-*.deb $CURRENT_DIR

echo "Please clean-up the work dir temp folder $WORK_DIR, e.g. by doing rm -R $WORK_DIR"

