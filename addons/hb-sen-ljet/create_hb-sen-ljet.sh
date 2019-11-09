#!/bin/bash

ADDON_VERSION=2.0.1

ARCHIVE_TAG="6db18d06f249d72ea396479f5156f21c862cb10e"

ADDON_DOWNLOAD_URL="https://github.com/TomMajor/SmartHome/archive/$ARCHIVE_TAG.tar.gz"

PKG_BUILD=3

CURRENT_DIR=$(pwd)
WORK_DIR=$(mktemp -d)

PKG_VERSION=$ADDON_VERSION-$PKG_BUILD

cd $WORK_DIR

wget -O repo.tar.gz $ADDON_DOWNLOAD_URL
tar xzf repo.tar.gz
mv SmartHome-$ARCHIVE_TAG repo

TARGET_DIR=$WORK_DIR/hb-sen-ljet-$PKG_VERSION

mkdir -p $TARGET_DIR/usr/local/addons/hb-sen-ljet
cp -a $WORK_DIR/repo/HB-SEN-LJet/CCU_RM/src/addon/* $TARGET_DIR/usr/local/addons/hb-sen-ljet

cp -a $CURRENT_DIR/hb-sen-ljet/* $TARGET_DIR 

chmod +x $TARGET_DIR/usr/local/addons/hb-sen-ljet/install
sed -i $TARGET_DIR/usr/local/addons/hb-sen-ljet/install -e "s/^#\!\/bin\/sh$/#\!\/bin\/bash/"

chmod +x $TARGET_DIR/usr/local/addons/hb-sen-ljet/uninstall
sed -i $TARGET_DIR/usr/local/addons/hb-sen-ljet/uninstall -e "s/^#\!\/bin\/sh$/#\!\/bin\/bash/"

chmod +x $TARGET_DIR/usr/local/addons/hb-sen-ljet/functions
sed -i $TARGET_DIR/usr/local/addons/hb-sen-ljet/functions -e "s/^#\!\/bin\/sh$/#\!\/bin\/bash/"

chmod +x $TARGET_DIR/usr/local/addons/hb-sen-ljet/params
sed -i $TARGET_DIR/usr/local/addons/hb-sen-ljet/params -e "s/^#\!\/bin\/sh$/#\!\/bin\/bash/"

for file in $TARGET_DIR/DEBIAN/*; do
  sed -i "s/{PKG_VERSION}/$PKG_VERSION/g" $file
done

cd $WORK_DIR

dpkg-deb --build hb-sen-ljet-$PKG_VERSION

cp hb-sen-ljet-*.deb $CURRENT_DIR

echo "Please clean-up the work dir temp folder $WORK_DIR, e.g. by doing rm -R $WORK_DIR"

