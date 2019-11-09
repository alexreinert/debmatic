#!/bin/bash

ADDON_VERSION=2.11

ARCHIVE_TAG="$ADDON_VERSION"

ADDON_DOWNLOAD_URL="https://github.com/jp112sdl/JP-HB-Devices-addon/archive/$ARCHIVE_TAG.tar.gz"

PKG_BUILD=8

CURRENT_DIR=$(pwd)
WORK_DIR=$(mktemp -d)

PKG_VERSION=$ADDON_VERSION-$PKG_BUILD

cd $WORK_DIR

wget -O repo.tar.gz $ADDON_DOWNLOAD_URL
tar xzf repo.tar.gz
mv JP-HB-Devices-addon-$ARCHIVE_TAG repo

TARGET_DIR=$WORK_DIR/jp-hb-devices-$PKG_VERSION

mkdir -p $TARGET_DIR/usr/local/addons/jp-hb-devices-addon
cp -a $WORK_DIR/repo/src/addon/* $TARGET_DIR/usr/local/addons/jp-hb-devices-addon

cp -a $CURRENT_DIR/jp-hb-devices/* $TARGET_DIR 

for file in $TARGET_DIR/DEBIAN/*; do
  sed -i "s/{PKG_VERSION}/$PKG_VERSION/g" $file
done

cd $WORK_DIR

dpkg-deb --build jp-hb-devices-$PKG_VERSION

cp jp-hb-devices-*.deb $CURRENT_DIR

echo "Please clean-up the work dir temp folder $WORK_DIR, e.g. by doing rm -R $WORK_DIR"

