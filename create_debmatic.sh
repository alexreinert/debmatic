#!/bin/bash

CCU_VERSION=3.41.11

OCCU_DOWNLOAD_URL="https://github.com/eq-3/occu/archive/$CCU_VERSION.tar.gz"

PKG_BUILD=1

CURRENT_DIR=$(pwd)
WORK_DIR=$(mktemp -d)

PKG_VERSION=$CCU_VERSION-$PKG_BUILD

cd $WORK_DIR

wget -O occu.tar.gz $OCCU_DOWNLOAD_URL
tar xzf occu.tar.gz
mv occu-$CCU_VERSION repo

cd repo
patch -l -p1 < $CURRENT_DIR/occu.patch

cd $WORK_DIR

declare -A architectures=(["armhf"]="arm-gnueabihf" ["arm64"]="arm-gnueabihf" ["amd64"]="X86_32_Debian_Wheezy")
for ARCH in "${!architectures[@]}"
do
  ARCH_SOURCE_DIR=${architectures[$ARCH]}

  TARGET_DIR=$WORK_DIR/debmatic-$PKG_VERSION-$ARCH

  mkdir -p $TARGET_DIR/bin
  cp -pR repo/WebUI/bin/* $TARGET_DIR/bin/
  cp -pR repo/$ARCH_SOURCE_DIR/packages-eQ-3/HS485D/bin/* $TARGET_DIR/bin/
  cp -pR repo/$ARCH_SOURCE_DIR/packages-eQ-3/RFD/bin/* $TARGET_DIR/bin/
  cp -pR repo/$ARCH_SOURCE_DIR/packages-eQ-3/WebUI/bin/* $TARGET_DIR/bin/
  cp -pR repo/$ARCH_SOURCE_DIR/packages-eQ-3/LinuxBasis/bin/* $TARGET_DIR/bin/

  mkdir -p $TARGET_DIR/lib/
  cp -pR repo/$ARCH_SOURCE_DIR/packages-eQ-3/HS485D/lib/* $TARGET_DIR/lib/
  cp -pR repo/$ARCH_SOURCE_DIR/packages-eQ-3/RFD/lib/* $TARGET_DIR/lib/
  cp -pR repo/$ARCH_SOURCE_DIR/packages-eQ-3/WebUI/lib/* $TARGET_DIR/lib/
  cp -pR repo/$ARCH_SOURCE_DIR/packages-eQ-3/LinuxBasis/lib/* $TARGET_DIR/lib/

  mkdir -p $TARGET_DIR/firmware
  cp -pR repo/firmware/* $TARGET_DIR/firmware/

  mkdir -p $TARGET_DIR/opt/HMServer
  cp -pR repo/HMserver/opt/HMServer/* $TARGET_DIR/opt/HMServer/

  mkdir -p $TARGET_DIR/opt/HmIP
  cp -pR repo/HMserver/opt/HmIP/* $TARGET_DIR/opt/HmIP/
  cp -pR repo/$ARCH_SOURCE_DIR/packages-eQ-3/RFD/opt/HmIP/* $TARGET_DIR/opt/HmIP/

  mkdir -p $TARGET_DIR/www
  cp -pR repo/WebUI/www/* $TARGET_DIR/www/
  cp -pR repo/$ARCH_SOURCE_DIR/packages-eQ-3/RFD/www/config/* $TARGET_DIR/www/config/

  for file in `find $TARGET_DIR/www -type l`; do
    target=`readlink $file | sed 's/^\/opt\/hm//g'`
    rm $file
    ln -s $target $file
  done

#  mkdir -p $TARGET_DIR/usr/share/debmatic/bin/lighttpd/lib
#  cp -p repo/$ARCH_SOURCE_DIR/packages/lighttpd/bin/* $TARGET_DIR/usr/share/debmatic/bin/lighttpd
#  cp -pR repo/$ARCH_SOURCE_DIR/packages/lighttpd/lib/* $TARGET_DIR/usr/share/debmatic/bin/lighttpd/lib

  cp -pR $CURRENT_DIR/debmatic/* $TARGET_DIR 

  echo "VERSION=$CCU_VERSION.$PKG_BUILD" > $TARGET_DIR/boot/VERSION

  cat > $TARGET_DIR/VERSION << EOF
VERSION=$CCU_VERSION.$PKG_BUILD
PRODUCT=debmatic
PLATFORM=$ARCH
EOF

  for file in $TARGET_DIR/DEBIAN/*; do
    DEPENDS="Pre-Depends: systemd, debconf (>= 0.5) | debconf-2.0, lighttpd, java8-runtime-headless | java8-runtime, pivccu-modules-dkms"
    if [ "$ARCH" == amd64 ]; then
      DEPENDS="$DEPENDS, libc6-i386, lib32stdc++6"
    fi

    sed -i "s/{PKG_VERSION}/$PKG_VERSION/g" $file
    sed -i "s/{PKG_ARCH}/$ARCH/g" $file
    sed -i "s/{CCU_VERSION}/$CCU_VERSION/g" $file
    sed -i "s/{DEPENDS}/$DEPENDS/g" $file
  done

  sed -i "s/{PKG_VERSION}/$CCU_VERSION.$PKG_BUILD/g" $TARGET_DIR/www/rega/pages/index.htm

  cd $WORK_DIR

  dpkg-deb --build debmatic-$PKG_VERSION-$ARCH
done

cp debmatic-*.deb $CURRENT_DIR

