#!/bin/bash

CUXD_VERSION=2.2.0

ARCHIVE_TAG="c2bf69606f391b1a8c2d96ea3ee7db0040525534"

CUXD_DOWNLOAD_URL="https://github.com/jens-maus/cuxd/archive/$ARCHIVE_TAG.tar.gz"

PKG_BUILD=1

CURRENT_DIR=$(pwd)
WORK_DIR=$(mktemp -d)

PKG_VERSION=$CUXD_VERSION-$PKG_BUILD

cd $WORK_DIR

wget -O cuxd.tar.gz $CUXD_DOWNLOAD_URL
tar xzf cuxd.tar.gz
mv cuxd-$ARCHIVE_TAG repo

declare -A architectures=(["armhf"]="ccu3" ["arm64"]="ccu3" ["amd64"]="ccu_x86_32")
for ARCH in "${!architectures[@]}"
do
  ARCH_SOURCE_DIR=${architectures[$ARCH]}

  TARGET_DIR=$WORK_DIR/cuxd-$PKG_VERSION-$ARCH

  mkdir -p $TARGET_DIR/usr/local/addons/cuxd
  cp -a $WORK_DIR/repo/common/cuxd/* $TARGET_DIR/usr/local/addons/cuxd 
  cp -a $WORK_DIR/repo/$ARCH_SOURCE_DIR/cuxd/* $TARGET_DIR/usr/local/addons/cuxd 

  cp -a $CURRENT_DIR/cuxd/* $TARGET_DIR 

  for file in $TARGET_DIR/DEBIAN/*; do
    sed -i "s/{PKG_VERSION}/$PKG_VERSION/g" $file
    sed -i "s/{PKG_ARCH}/$ARCH/g" $file
  done

  cd $WORK_DIR

  dpkg-deb --build cuxd-$PKG_VERSION-$ARCH
done

cp cuxd-*.deb $CURRENT_DIR

echo "Please clean-up the work dir temp folder $WORK_DIR, e.g. by doing rm -R $WORK_DIR"

