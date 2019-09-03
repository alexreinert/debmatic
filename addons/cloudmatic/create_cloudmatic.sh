#!/bin/bash

ADDON_VERSION=0.9

PKG_BUILD=1

CURRENT_DIR=$(pwd)
WORK_DIR=$(mktemp -d)

PKG_VERSION=$ADDON_VERSION-$PKG_BUILD

cd $WORK_DIR

TARGET_DIR=$WORK_DIR/cloudmatic-$PKG_VERSION

mkdir -p $TARGET_DIR

cp -a $CURRENT_DIR/cloudmatic/* $TARGET_DIR 

for file in $TARGET_DIR/DEBIAN/*; do
  sed -i "s/{PKG_VERSION}/$PKG_VERSION/g" $file
done

cd $WORK_DIR

dpkg-deb --build cloudmatic-$PKG_VERSION

cp cloudmatic-*.deb $CURRENT_DIR

echo "Please clean-up the work dir temp folder $WORK_DIR, e.g. by doing rm -R $WORK_DIR"

