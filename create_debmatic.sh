#!/bin/bash

CCU_VERSION="3.55.5"

ARCHIVE_TAG="9a466bd531d4027353bad7739e8cef7221d3aada"
OCCU_DOWNLOAD_URL="https://github.com/eq-3/occu/archive/$ARCHIVE_TAG.tar.gz"

CCU_DOWNLOAD_SPLASH_URL="https://www.eq-3.de/service/downloads.html"
CCU_DOWNLOAD_URL="https://www.eq-3.de/downloads/software/firmware/ccu3-firmware/ccu3-$CCU_VERSION.tgz"

JP_HB_DEVICES_ADDON_ARCHIVE_TAG="3.3"
JP_HB_DEVICES_ADDON_DOWNLOAD_URL="https://github.com/jp112sdl/JP-HB-Devices-addon/archive/$JP_HB_DEVICES_ADDON_ARCHIVE_TAG.tar.gz"

HB_TM_DEVICES_ADDON_ARCHIVE_TAG="4cc93d0b90ebfa0c1e55e14fb69dc6a8cffd8fc7"
HB_TM_DEVICES_ADDON_DOWNLOAD_URL="https://github.com/TomMajor/SmartHome/archive/$HB_TM_DEVICES_ADDON_ARCHIVE_TAG.tar.gz"

PKG_BUILD=62

CURRENT_DIR=$(pwd)
WORK_DIR=$(mktemp -d)

PKG_VERSION=$CCU_VERSION-$PKG_BUILD

cd $WORK_DIR

wget -O occu.tar.gz $OCCU_DOWNLOAD_URL
tar xzf occu.tar.gz
mv occu-$ARCHIVE_TAG repo

cd $WORK_DIR/repo
patch -l -p1 < $CURRENT_DIR/occu.patch
mv $WORK_DIR/repo/firmware/HmIP-RFUSB/hmip_coprocessor_update.eq3 $WORK_DIR/repo/firmware/HmIP-RFUSB/hmip_coprocessor_update-2.8.6.eq3

wget -O /dev/null --save-cookies=cookies.txt --keep-session-cookies $CCU_DOWNLOAD_SPLASH_URL
wget -O ccu3.tar.gz --load-cookies=cookies.txt --referer=$CCU_DOWNLOAD_SPLASH_URL $CCU_DOWNLOAD_URL

tar xzf ccu3.tar.gz

gunzip rootfs.ext4.gz

mkdir $WORK_DIR/image
mount -t ext4 -o loop,ro rootfs.ext4 $WORK_DIR/image

mkdir $WORK_DIR/ccu
cp -pR $WORK_DIR/image/* $WORK_DIR/ccu/

umount $WORK_DIR/image

cd $WORK_DIR/ccu
patch -l -p1 < $CURRENT_DIR/debmatic.patch

cd $WORK_DIR
wget -O JP-HB-Devices-addon.tar.gz $JP_HB_DEVICES_ADDON_DOWNLOAD_URL
tar xzf JP-HB-Devices-addon.tar.gz
mv JP-HB-Devices-addon-$JP_HB_DEVICES_ADDON_ARCHIVE_TAG JP-HB-Devices-addon

cd $WORK_DIR/ccu/www

for file in $WORK_DIR/JP-HB-Devices-addon/src/addon/patch/common/*.patch; do
  patch -N -l -p3 -s --dry-run -r - --no-backup-if-mismatch -i $file
  if [ $? -eq 1 ]; then
    dos2unix $file
  fi
  patch -N -l -p3 -r - --no-backup-if-mismatch -i $file
done
for file in $WORK_DIR/JP-HB-Devices-addon/src/addon/patch/ge_345/*.patch; do
  patch -N -l -p3 -s --dry-run -r - --no-backup-if-mismatch -i $file
  if [ $? -eq 1 ]; then
    dos2unix $file
  fi
  patch -N -l -p3 -r - --no-backup-if-mismatch -i $file
done

cp -ar $WORK_DIR/JP-HB-Devices-addon/src/addon/www/* $WORK_DIR/ccu/www/
cp $WORK_DIR/JP-HB-Devices-addon/src/addon/js/jp_webui_inc.js $WORK_DIR/ccu/www/webui/js/extern/
cp $WORK_DIR/JP-HB-Devices-addon/src/addon/firmware/rftypes/* $WORK_DIR/ccu/firmware/rftypes/

for file in $WORK_DIR/JP-HB-Devices-addon/src/addon/install_*; do
  sed -i "s|/www/|$WORK_DIR/ccu/www/|g" $file
  chmod +x $file
  $file
done

cd $WORK_DIR
wget -O HB-TM-Devices-addon.tar.gz $HB_TM_DEVICES_ADDON_DOWNLOAD_URL
tar xzf HB-TM-Devices-addon.tar.gz
mv SmartHome-$HB_TM_DEVICES_ADDON_ARCHIVE_TAG HB-TM-Devices-addon

cd $WORK_DIR/ccu/www

cp -ar $WORK_DIR/HB-TM-Devices-addon/HB-TM-Devices-AddOn/CCU_RM/src/addon/www/* $WORK_DIR/ccu/www/
cp $WORK_DIR/HB-TM-Devices-addon/HB-TM-Devices-AddOn/CCU_RM/src/addon/firmware/rftypes/* $WORK_DIR/ccu/firmware/rftypes/

for file in $WORK_DIR/HB-TM-Devices-addon/HB-TM-Devices-AddOn/CCU_RM/src/addon/install_*; do
  sed -i "s|/www/|$WORK_DIR/ccu/www/|g" $file
  chmod +x $file
  $file
done

cd $WORK_DIR

declare -A architectures=(["armhf"]="arm-gnueabihf" ["arm64"]="arm-gnueabihf" ["i386"]="X86_32_Debian_Wheezy" ["amd64"]="X86_32_Debian_Wheezy")
for ARCH in "${!architectures[@]}"
do
  ARCH_SOURCE_DIR=${architectures[$ARCH]}

  TARGET_DIR=$WORK_DIR/debmatic-$PKG_VERSION-$ARCH

  mkdir -p $TARGET_DIR/bin
  cp -pR $WORK_DIR/ccu/bin/hm_* $TARGET_DIR/bin/
  cp -pR $WORK_DIR/repo/$ARCH_SOURCE_DIR/packages-eQ-3/HS485D/bin/* $TARGET_DIR/bin/
  cp -pR $WORK_DIR/repo/$ARCH_SOURCE_DIR/packages-eQ-3/RFD/bin/* $TARGET_DIR/bin/
  cp -pR $WORK_DIR/repo/$ARCH_SOURCE_DIR/packages-eQ-3/WebUI/bin/* $TARGET_DIR/bin/
  cp -pR $WORK_DIR/repo/$ARCH_SOURCE_DIR/packages-eQ-3/LinuxBasis/bin/* $TARGET_DIR/bin/

  mkdir -p $TARGET_DIR/lib/debmatic
  cp -pR $WORK_DIR/repo/$ARCH_SOURCE_DIR/packages-eQ-3/HS485D/lib/* $TARGET_DIR/lib/
  cp -pR $WORK_DIR/repo/$ARCH_SOURCE_DIR/packages-eQ-3/RFD/lib/* $TARGET_DIR/lib/
  cp -pR $WORK_DIR/repo/$ARCH_SOURCE_DIR/packages-eQ-3/WebUI/lib/* $TARGET_DIR/lib/
  cp -pR $WORK_DIR/repo/$ARCH_SOURCE_DIR/packages-eQ-3/LinuxBasis/lib/* $TARGET_DIR/lib/

  if [ "$ARCH" == "arm64" ]; then
    for file in avrprog crypttool eq3configcmd eq3configd eq3-uds-services hs485d hs485dLoader hss_led multimacd ReGaHss.community ReGaHss.normal rfd SetInterfaceClock ssdpd tclsh; do
      cp $WORK_DIR/ccu/bin/$file $TARGET_DIR/bin/
    done

    for file in ld-linux-armhf.so.3 libelvutils.so libeq3config.so libeq3udss.so libhsscomm.so libLanDeviceUtils.so libtcl8.2.so libUnifiedLanComm.so libxmlparser.so libXmlRpc.so tclrega.so tclrpc.so tclticks.so libc.so.6 libdl.so.2 libgcc_s.so.1 libm.so.6 libpthread.so.0 librt.so.1 libstdc++.so.6; do
      cp $WORK_DIR/ccu/lib/$file $TARGET_DIR/lib/ || cp $WORK_DIR/ccu/usr/lib/$file $TARGET_DIR/lib/
    done

    wget -O $TARGET_DIR/lib/liblockdev.so.1 https://github.com/NeuronRobotics/nrjavaserial/raw/master/src/main/c/cross-compile-libs/ARM_64/liblockdev.so
    mkdir -p $TARGET_DIR/usr/share/debmatic/lib
    wget -O $TARGET_DIR/usr/share/debmatic/lib/libNRJavaSerialv8.so https://github.com/NeuronRobotics/nrjavaserial/raw/master/src/main/c/resources/native/linux/ARM_64/libNRJavaSerialv8.so
  fi

  cp -pR $WORK_DIR/ccu/firmware $TARGET_DIR/
  cp -pR $WORK_DIR/repo/firmware/HM-MOD-UART $TARGET_DIR/firmware/
  cp -pR $WORK_DIR/repo/firmware/HmIP-RFUSB $TARGET_DIR/firmware/

  mkdir -p $TARGET_DIR/opt
  cp -pR $WORK_DIR/ccu/opt/HMServer $TARGET_DIR/opt/
  cp -p $WORK_DIR/repo/HMserver/opt/HMServer/HMServer.jar $TARGET_DIR/opt/HMServer/
  cp -pR $WORK_DIR/ccu/opt/HmIP $TARGET_DIR/opt/

  cp -pR $WORK_DIR/ccu/www $TARGET_DIR/

#  mkdir -p $TARGET_DIR/usr/share/debmatic/bin/lighttpd/lib
#  cp -p repo/$ARCH_SOURCE_DIR/packages/lighttpd/bin/* $TARGET_DIR/usr/share/debmatic/bin/lighttpd
#  cp -pR repo/$ARCH_SOURCE_DIR/packages/lighttpd/lib/* $TARGET_DIR/usr/share/debmatic/bin/lighttpd/lib

  cp -pR $CURRENT_DIR/debmatic/* $TARGET_DIR 

  echo "VERSION=$CCU_VERSION.$PKG_BUILD" > $TARGET_DIR/usr/share/debmatic/VERSION

  cat > $TARGET_DIR/VERSION << EOF
VERSION=$CCU_VERSION.$PKG_BUILD
PRODUCT=debmatic
PLATFORM=$ARCH
EOF

  for file in $TARGET_DIR/DEBIAN/*; do
    DEPENDS="Pre-Depends: detect-radio-module, wait-sysfs-notify, systemd, debconf (>= 0.5) | debconf-2.0, lighttpd, java8-runtime-headless | java8-runtime, ipcalc, net-tools, rsync"
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

echo "Please clean-up the work dir temp folder $WORK_DIR, e.g. by doing rm -R $WORK_DIR"

