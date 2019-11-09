#!/bin/bash

ADDON_VERSION=2.0.3

ARCHIVE_TAG="d71b4934a63e73544e2e4b412168da8ca8a85154"

ADDON_DOWNLOAD_URL="https://github.com/TomMajor/SmartHome/archive/$ARCHIVE_TAG.tar.gz"

PKG_BUILD=3

CURRENT_DIR=$(pwd)
WORK_DIR=$(mktemp -d)

PKG_VERSION=$ADDON_VERSION-$PKG_BUILD

cd $WORK_DIR

wget -O repo.tar.gz $ADDON_DOWNLOAD_URL
tar xzf repo.tar.gz
mv SmartHome-$ARCHIVE_TAG repo

TARGET_DIR=$WORK_DIR/hb-uni-sensor1-$PKG_VERSION

mkdir -p $TARGET_DIR/usr/local/addons/hb-uni-sensor1
cp -a $WORK_DIR/repo/HB-UNI-Sensor1/CCU_RM/src/addon/* $TARGET_DIR/usr/local/addons/hb-uni-sensor1

cp -a $CURRENT_DIR/hb-uni-sensor1/* $TARGET_DIR 

chmod +x $TARGET_DIR/usr/local/addons/hb-uni-sensor1/install
sed -i $TARGET_DIR/usr/local/addons/hb-uni-sensor1/install -e "s/^#\!\/bin\/sh$/#\!\/bin\/bash/"

chmod +x $TARGET_DIR/usr/local/addons/hb-uni-sensor1/uninstall
sed -i $TARGET_DIR/usr/local/addons/hb-uni-sensor1/uninstall -e "s/^#\!\/bin\/sh$/#\!\/bin\/bash/"

chmod +x $TARGET_DIR/usr/local/addons/hb-uni-sensor1/functions
sed -i $TARGET_DIR/usr/local/addons/hb-uni-sensor1/functions -e "s/^#\!\/bin\/sh$/#\!\/bin\/bash/"

chmod +x $TARGET_DIR/usr/local/addons/hb-uni-sensor1/params
sed -i $TARGET_DIR/usr/local/addons/hb-uni-sensor1/params -e "s/^#\!\/bin\/sh$/#\!\/bin\/bash/"

for file in $TARGET_DIR/DEBIAN/*; do
  sed -i "s/{PKG_VERSION}/$PKG_VERSION/g" $file
done

cd $WORK_DIR

dpkg-deb --build hb-uni-sensor1-$PKG_VERSION

cp hb-uni-sensor1-*.deb $CURRENT_DIR

echo "Please clean-up the work dir temp folder $WORK_DIR, e.g. by doing rm -R $WORK_DIR"

