#!/bin/bash

CCU_VERSION="3.75.6"

ARCHIVE_TAG="6af1ff84d7114c01e63f2b44225bac0edd9ce0b6"
OCCU_DOWNLOAD_URL="https://github.com/eq-3/occu/archive/$ARCHIVE_TAG.tar.gz"

CCU_DOWNLOAD_SPLASH_URL="https://www.eq-3.de/service/downloads.html"
CCU_DOWNLOAD_URL="https://www.eq-3.de/downloads/software/firmware/ccu3-firmware/ccu3-$CCU_VERSION.tgz"
CCU_DOWNLOAD_URL="https://homematic-ip.com/sites/default/files/downloads/ccu3-$CCU_VERSION.tgz"

JP_HB_DEVICES_ADDON_ARCHIVE_TAG="6.1"
JP_HB_DEVICES_ADDON_DOWNLOAD_URL="https://github.com/jp112sdl/JP-HB-Devices-addon/archive/$JP_HB_DEVICES_ADDON_ARCHIVE_TAG.tar.gz"

HB_TM_DEVICES_ADDON_ARCHIVE_TAG="ab7bdeba2c180d5b6fc453a010d4ee2b882a929d"
HB_TM_DEVICES_ADDON_DOWNLOAD_URL="https://github.com/TomMajor/SmartHome/archive/$HB_TM_DEVICES_ADDON_ARCHIVE_TAG.tar.gz"

PKG_BUILD=113

function throw {
  echo $1
  exit 1
}

function run {
  echo -n "$1 ... "
  shift
  ERR=`$* 2>&1` && RC=$? || RC=$?
  if [ $RC -eq 0 ]; then
    echo -e "\033[0;32mDone\033[0;0m"
  else
    echo -e "\033[1;91mFAILED\033[0;0m"
    echo "$ERR"
    exit 1
  fi
}

function add_device_to_devdb {
    DEVICE=$1
    IMG=$2
    DEVICE_IMG=${IMG}.png
    DEVICE_THUMB=${IMG}_thumb.png
    DEVDBINSERT="$DEVICE {{50 \/config\/img\/devices\/50\/$DEVICE_THUMB} {250 \/config\/img\/devices\/250\/$DEVICE_IMG}} "
    sed -i "s/\(array[[:space:]]*set[[:space:]]*DEV_PATHS[[:space:]]*{\)/\1$DEVDBINSERT/g" $WORK_DIR/ccu/www/config/devdescr/DEVDB.tcl || throw "Insert into DEVDB.tcl failed"
}

function apply_jp_patch {
  file="$1"
  patch -N -l -p3 -s --dry-run -r - --no-backup-if-mismatch -i $file
  if [ $? -eq 1 ]; then
    dos2unix $file
  fi
  patch -N -l -p3 -r - --no-backup-if-mismatch -i $file || throw "could not apply patch $file"
}

CURRENT_DIR=$(pwd)
WORK_DIR=$(mktemp -d)

PKG_VERSION=$CCU_VERSION-$PKG_BUILD

cd $WORK_DIR

function download_occu {
  run "Download OCCU package" wget -O occu.tar.gz $OCCU_DOWNLOAD_URL
  run "Extract OCCU package" tar xzf occu.tar.gz
  mv occu-$ARCHIVE_TAG repo
}
run "Download OCCU Github Repository" download_occu

cd $WORK_DIR/repo
run "Apply OCCU patches" patch -E -l -p1 < $CURRENT_DIR/occu.patch

function download_ccu_firmware {
  run "Get splash page" wget -O /dev/null --save-cookies=cookies.txt --keep-session-cookies $CCU_DOWNLOAD_SPLASH_URL
  run "Download firmware package" wget -O ccu3.tar.gz --load-cookies=cookies.txt --referer=$CCU_DOWNLOAD_SPLASH_URL $CCU_DOWNLOAD_URL
}
run "Download CCU3 firmware" download_ccu_firmware

function extract_ccu_firmware {
  run "Extract firmware package" tar xzf ccu3.tar.gz
  run "Extract root fs" gunzip rootfs.ext4.gz

  mkdir $WORK_DIR/image
  run "Mount root fs" fuse2fs -o ro,fakeroot rootfs.ext4 $WORK_DIR/image

  mkdir $WORK_DIR/ccu
  run "Copy root fs contents" cp -pR $WORK_DIR/image/* $WORK_DIR/ccu/

  run "Umount root fs" umount $WORK_DIR/image
}
run "Extract CCU3 firmware" extract_ccu_firmware

cd $WORK_DIR/ccu
run "Patch CCU3 firmware" patch -E -l -p1 < $CURRENT_DIR/debmatic.patch

run "Add HmIP-RFUSB device to DEVDB" add_device_to_devdb "HmIP-RFUSB" "CCU3"

cd $WORK_DIR

function download_jp_addon {
  run "Download addon package" wget -O JP-HB-Devices-addon.tar.gz $JP_HB_DEVICES_ADDON_DOWNLOAD_URL
  run "Extract addon package" tar xzf JP-HB-Devices-addon.tar.gz
  mv JP-HB-Devices-addon-$JP_HB_DEVICES_ADDON_ARCHIVE_TAG JP-HB-Devices-addon
}
run "Download JP-HB-Devices-Addon" download_jp_addon

cd $WORK_DIR/ccu/www

function add_global_page_hook {
  sed -i "\~</body>~i\    <script type=\"text/javascript\" src=\"/webui/js/extern/jp_webui_inc.js\"></script>" $WORK_DIR/ccu/www/rega/pages/index.htm
}

function add_hook_js_calls {
  echo "\n<%  if (action == \"servoOldVal\")     { Call(\"channels.fn::servoOldVal()\"); } %>" >> $WORK_DIR/ccu/www/rega/esp/channels.htm
  echo "\n<%  if (action == \"fanOldVal\")     { Call(\"channels.fn::fanOldVal()\"); } %>" >> $WORK_DIR/ccu/www/rega/esp/channels.htm
  echo "\n<%  if (action == \"airflapOldVal\")     { Call(\"channels.fn::airflapOldVal()\"); } %>" >> $WORK_DIR/ccu/www/rega/esp/channels.htm
}

function apply_jp_addon {
  run "Remove header.htm patch" rm $WORK_DIR/JP-HB-Devices-addon/src/addon/patch/common/header.htm.patch
  run "Remove methods.conf patch" rm $WORK_DIR/JP-HB-Devices-addon/src/addon/patch/common/methods.conf.patch
  run "Remove getinfowebversion.tcl patch" rm $WORK_DIR/JP-HB-Devices-addon/src/addon/www/api/methods/jp/getinfowebversion.tcl
  run "Remove setinfowebversion.tcl patch" rm $WORK_DIR/JP-HB-Devices-addon/src/addon/www/api/methods/jp/setinfowebversion.tcl

  for file in $WORK_DIR/JP-HB-Devices-addon/src/addon/patch/common/*.patch; do
    basefile=`basename $file`
    run "Apply patch common/$basefile" apply_jp_patch $file
  done
  for file in $WORK_DIR/JP-HB-Devices-addon/src/addon/patch/ge_365/*.patch; do
    basefile=`basename $file`
    run "Apply patch ge_365/$basefile" apply_jp_patch $file
  done

  run "Copy www data" cp -ar $WORK_DIR/JP-HB-Devices-addon/src/addon/www/* $WORK_DIR/ccu/www/
  run "Copy jp_webui_inc.js" cp $WORK_DIR/JP-HB-Devices-addon/src/addon/www/webui/js/extern/jp_webui_inc.js $WORK_DIR/ccu/www/webui/js/extern/
  run "Copy rftypes" cp $WORK_DIR/JP-HB-Devices-addon/src/addon/firmware/rftypes/* $WORK_DIR/ccu/firmware/rftypes/

  run "Add scripts registration" add_global_page_hook

  mkdir -p $WORK_DIR/ccu/www/config/easymodes/KEY/localization/de
  run "Add GENERIC KEY easymodes DE" cp $WORK_DIR/ccu/www/config/easymodes/BLIND/localization/de/GENERIC.txt $WORK_DIR/ccu/www/config/easymodes/KEY/localization/de/
  run "Add KEY easymodes DE" cp $WORK_DIR/ccu/www/config/easymodes/BLIND/localization/de/KEY.txt $WORK_DIR/ccu/www/config/easymodes/KEY/localization/de/
  mkdir -p $WORK_DIR/ccu/www/config/easymodes/KEY/localization/en
  run "Add GENERIC KEY easymodes EN" cp $WORK_DIR/ccu/www/config/easymodes/BLIND/localization/en/GENERIC.txt $WORK_DIR/ccu/www/config/easymodes/KEY/localization/en/
  run "Add KEY easymodes EN" cp $WORK_DIR/ccu/www/config/easymodes/BLIND/localization/en/KEY.txt $WORK_DIR/ccu/www/config/easymodes/KEY/localization/en/

  run "Add JS hooks" add_hook_js_calls

  while IFS=";" read -r DEVICE IMG; do
    if case $DEVICE in "HB-"*) true;; *) false;; esac; then
      run "Add $DEVICE device to DEVDB" add_device_to_devdb "$DEVICE" "$IMG"
    fi
  done < $WORK_DIR/JP-HB-Devices-addon/src/addon/devdb.csv
}
run "Apply JP-HB-Devices-Addon" apply_jp_addon

cd $WORK_DIR

function download_tm_addon {
  run "Download addon package" wget -O HB-TM-Devices-addon.tar.gz $HB_TM_DEVICES_ADDON_DOWNLOAD_URL
  run "Extract addon package" tar xzf HB-TM-Devices-addon.tar.gz
  mv SmartHome-$HB_TM_DEVICES_ADDON_ARCHIVE_TAG HB-TM-Devices-addon
}
run "Download HB-TM-Devices-Addon" download_tm_addon

cd $WORK_DIR/ccu/www

function apply_tm_addon {
  run "Copy www data" cp -ar $WORK_DIR/HB-TM-Devices-addon/HB-TM-Devices-AddOn/CCU_RM/src/addon/www/* $WORK_DIR/ccu/www/
  run "Copy rftypes" cp $WORK_DIR/HB-TM-Devices-addon/HB-TM-Devices-AddOn/CCU_RM/src/addon/firmware/rftypes/* $WORK_DIR/ccu/firmware/rftypes/

  for file in $WORK_DIR/HB-TM-Devices-addon/HB-TM-Devices-AddOn/CCU_RM/src/addon/install_*; do
    sed -i "s|/www/|$WORK_DIR/ccu/www/|g" $file
    chmod +x $file
    basefile=`basename $file`
    run "Run installer $basefile" $file
  done
}
run "Apply HB-TM-Devices-Addon" apply_tm_addon

cd $WORK_DIR

declare -A architectures=(["armhf"]="arm-gnueabihf-gcc8" ["arm64"]="arm-gnueabihf-gcc8" ["i386"]="X86_32_GCC8" ["amd64"]="X86_32_GCC8")

function build_arch_package {
  ARCH=$1

  ARCH_SOURCE_DIR=${architectures[$ARCH]}

  TARGET_DIR=$WORK_DIR/debmatic-$PKG_VERSION-$ARCH

  mkdir -p $TARGET_DIR/bin
  run "Copy HM scripts" cp -pR $WORK_DIR/ccu/bin/hm_* $TARGET_DIR/bin/
  run "Copy HS485D binaries" cp -pR $WORK_DIR/repo/$ARCH_SOURCE_DIR/packages-eQ-3/HS485D/bin/* $TARGET_DIR/bin/
  run "Copy RFD binaries" cp -pR $WORK_DIR/repo/$ARCH_SOURCE_DIR/packages-eQ-3/RFD/bin/* $TARGET_DIR/bin/
  run "Copy WebUI binaries" cp -pR $WORK_DIR/repo/$ARCH_SOURCE_DIR/packages-eQ-3/WebUI/bin/* $TARGET_DIR/bin/
  run "Copy ReGaHss.community binaries" cp -pR $WORK_DIR/repo/$ARCH_SOURCE_DIR/packages-eQ-3/WebUI-Beta/bin/ReGaHss $TARGET_DIR/bin/ReGaHss.community
  run "Copy linux basic binaries" cp -pR $WORK_DIR/repo/$ARCH_SOURCE_DIR/packages-eQ-3/LinuxBasis/bin/* $TARGET_DIR/bin/

  mkdir -p $TARGET_DIR/usr/share/debmatic/lib/ld
  run "Copy HS485D libraries" cp -pR $WORK_DIR/repo/$ARCH_SOURCE_DIR/packages-eQ-3/HS485D/lib/* $TARGET_DIR/usr/share/debmatic/lib
  run "Copy RFD libraries" cp -pR $WORK_DIR/repo/$ARCH_SOURCE_DIR/packages-eQ-3/RFD/lib/* $TARGET_DIR/usr/share/debmatic/lib
  run "Copy WebUI libraries" cp -pR $WORK_DIR/repo/$ARCH_SOURCE_DIR/packages-eQ-3/WebUI/lib/* $TARGET_DIR/usr/share/debmatic/lib
  run "Copy linux basic libraries" cp -pR $WORK_DIR/repo/$ARCH_SOURCE_DIR/packages-eQ-3/LinuxBasis/lib/* $TARGET_DIR/usr/share/debmatic/lib

  mkdir -p $TARGET_DIR/lib/
  run "Copy tcl scripts" cp -pR $WORK_DIR/ccu/lib/*.tcl $TARGET_DIR/lib/

  if [ "$ARCH" == "amd64" ]; then
    mkdir $WORK_DIR/amd64
    run "Download libusb_i386.deb" wget -O libusb_i386.deb http://ftp.debian.org/debian/pool/main/libu/libusb-1.0/libusb-1.0-0_1.0.24-3_i386.deb
    run "Download libudev_i386.deb" wget -O libudev_i386.deb http://ftp.debian.org/debian/pool/main/s/systemd/libudev1_247.3-7+deb11u4_i386.deb
    for file in `ls *_i386.deb`; do
      run "Extract $file" dpkg -x $file $WORK_DIR/amd64
    done
    run "Copy lib files" cp -pR $WORK_DIR/amd64/usr/lib/i386-linux-gnu/* $TARGET_DIR/usr/share/debmatic/lib
  elif [ "$ARCH" == "arm64" ]; then
    mkdir $WORK_DIR/arm64
    run "Download libusb_armhf.deb" wget -O libusb_armhf.deb http://ftp.debian.org/debian/pool/main/libu/libusb-1.0/libusb-1.0-0_1.0.24-3_armhf.deb
    run "Download libudev_armhf.deb" wget -O libudev_armhf.deb http://ftp.debian.org/debian/pool/main/s/systemd/libudev1_247.3-7+deb11u4_armhf.deb
    run "Download libc_armhf.deb" wget -O libc_armhf.deb http://ftp.debian.org/debian/pool/main/g/glibc/libc6_2.31-13+deb11u5_armhf.deb
    run "Download libstdc++6_armhf.deb" wget -O libstdc++6_armhf.deb http://ftp.debian.org/debian/pool/main/g/gcc-10/libstdc++6_10.2.1-6_armhf.deb
    run "Download libgcc-s1_armhf.deb" wget -O libgcc-s1_armhf.deb http://ftp.debian.org/debian/pool/main/g/gcc-10/libgcc-s1_10.2.1-6_armhf.deb
    for file in `ls *_armhf.deb`; do
      run "Extract $file" dpkg -x $file $WORK_DIR/arm64
    done
    run "Copy lib files" cp -pR $WORK_DIR/arm64/usr/lib/arm-linux-gnueabihf/* $TARGET_DIR/usr/share/debmatic/lib
    for file in libc.so.6 libdl.so.2 libgcc_s.so.1 libm.so.6 libpthread.so.0 librt.so.1; do
      run "Copy lib $file" cp -pRL $WORK_DIR/arm64/lib/arm-linux-gnueabihf/$file $TARGET_DIR/usr/share/debmatic/lib
    done
    run "Copy lib ld-linux-armhf.so.3" cp -pRL $WORK_DIR/arm64/lib/arm-linux-gnueabihf/ld-linux-armhf.so.3 $TARGET_DIR/usr/share/debmatic/lib/ld/
  fi

  run "Copy firmware files" cp -pR $WORK_DIR/ccu/firmware $TARGET_DIR/
  run "Copy HM-MOD-RPI-PCB firmware files" cp -pR $WORK_DIR/repo/firmware/HM-MOD-UART $TARGET_DIR/firmware/
  mkdir -p $TARGET_DIR/firmware/HmIP-RFUSB
  run "Copy HmIP-RFUSB firmware files" cp -pR $WORK_DIR/repo/firmware/HmIP-RFUSB/dualcopro_update_blhmip-*.eq3 $TARGET_DIR/firmware/HmIP-RFUSB/

  mkdir -p $TARGET_DIR/opt
  run "Copy HmIPServer files" cp -pR $WORK_DIR/ccu/opt/HMServer $TARGET_DIR/opt/
  run "Copy HMServer files" cp -p $WORK_DIR/repo/HMserver/opt/HMServer/HMServer.jar $TARGET_DIR/opt/HMServer/
  run "Copy HmIP files" cp -pR $WORK_DIR/ccu/opt/HmIP $TARGET_DIR/opt/
  run "Copy hmip-copro-update.jar" cp -p $WORK_DIR/repo/HMServer-Beta/opt/HmIP/hmip-copro-update.jar $TARGET_DIR/opt/HmIP/

  run "Copy www files" cp -pR $WORK_DIR/ccu/www $TARGET_DIR/

  run "Copy debmatic files" cp -pR $CURRENT_DIR/debmatic/* $TARGET_DIR

  echo "VERSION=$CCU_VERSION.$PKG_BUILD" > $TARGET_DIR/usr/share/debmatic/VERSION

  cat > $TARGET_DIR/VERSION << EOF
VERSION=$CCU_VERSION.$PKG_BUILD
PRODUCT=debmatic
PLATFORM=$ARCH
EOF

  for file in $TARGET_DIR/DEBIAN/*; do
    if [ "$ARCH" == amd64 ]; then
      LIBC_DEPENDS="libc6-i386 (>= 2.29), lib32stdc++6"
    else
      LIBC_DEPENDS="libc6 (>= 2.29), libstdc++6"
    fi

    sed -i "s/{PKG_VERSION}/$PKG_VERSION/g" $file
    sed -i "s/{PKG_ARCH}/$ARCH/g" $file
    sed -i "s/{CCU_VERSION}/$CCU_VERSION/g" $file
    sed -i "s/{LIBC_DEPENDS}/$LIBC_DEPENDS/g" $file
  done

  sed -i "s/{PKG_VERSION}/$CCU_VERSION.$PKG_BUILD/g" $TARGET_DIR/www/rega/pages/index.htm

  cd $WORK_DIR

  run "Create deb" dpkg-deb --build -Zxz debmatic-$PKG_VERSION-$ARCH
}

for ARCH in "${!architectures[@]}"
do
  run "Build $ARCH package" build_arch_package $ARCH
done

run "Copy packages to local directory" cp debmatic-*.deb $CURRENT_DIR
run "Remove temporary files" rm -rf $WORK_DIR

