#!/bin/bash

CUXD_VERSION=2.4.1

PKG_BUILD=4

CURRENT_DIR=$(pwd)
WORK_DIR=$(mktemp -d)

PKG_VERSION=$CUXD_VERSION-$PKG_BUILD

cd $WORK_DIR

declare -A architectures=(["armhf"]="72330" ["arm64"]="72330" ["i386"]="72329" ["amd64"]="72329")

for ARCH in "${!architectures[@]}"
do
  ARCH_DOWNLOAD_URL="https://homematic-forum.de/forum/download/file.php?id=${architectures[$ARCH]}"

  mkdir -p $WORK_DIR/repo-$ARCH
  cd $WORK_DIR/repo-$ARCH
  wget -O cuxd.tar.gz $ARCH_DOWNLOAD_URL
  tar xzf cuxd.tar.gz

  TARGET_DIR=$WORK_DIR/cuxd-$PKG_VERSION-$ARCH

  mkdir -p $TARGET_DIR/usr/local/addons/cuxd
  cp -a $WORK_DIR/repo-$ARCH/cuxd_addon.cfg $TARGET_DIR/usr/local/addons/cuxd
  cp -a $WORK_DIR/repo-$ARCH/cuxd/* $TARGET_DIR/usr/local/addons/cuxd 

  cp -a $CURRENT_DIR/cuxd/* $TARGET_DIR 

  for file in $TARGET_DIR/DEBIAN/*; do
    DEPENDS="Pre-Depends: debmatic (>= 3.43.15-10)"
    if [ "$ARCH" == amd64 ]; then
      DEPENDS="$DEPENDS, libc6-i386 (>= 2.28)"
    fi
    if [ "$ARCH" == i386 ]; then
      DEPENDS="$DEPENDS, libc6 (>= 2.28)"
    fi

    sed -i "s/{PKG_VERSION}/$PKG_VERSION/g" $file
    sed -i "s/{PKG_ARCH}/$ARCH/g" $file
    sed -i "s/{DEPENDS}/$DEPENDS/g" $file
  done

  cd $WORK_DIR

  dpkg-deb --build cuxd-$PKG_VERSION-$ARCH
done

cp cuxd-*.deb $CURRENT_DIR

echo "Please clean-up the work dir temp folder $WORK_DIR, e.g. by doing rm -R $WORK_DIR"

