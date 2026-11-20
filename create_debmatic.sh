#!/bin/bash

CCU_VERSION="3.89.13"

OCCU_BASE_COMMIT="c56cc47a41b2a953815a8e4e2a2b7fb10d73e679"
OCCU_BASE_DOWNLOAD_URL="https://github.com/OpenCCU/OpenCCU-Base/archive/$OCCU_BASE_COMMIT.tar.gz"

JP_HB_DEVICES_ADDON_ARCHIVE_TAG="6.1"
JP_HB_DEVICES_ADDON_DOWNLOAD_URL="https://github.com/jp112sdl/JP-HB-Devices-addon/archive/$JP_HB_DEVICES_ADDON_ARCHIVE_TAG.tar.gz"

HB_TM_DEVICES_ADDON_ARCHIVE_TAG="ab7bdeba2c180d5b6fc453a010d4ee2b882a929d"
HB_TM_DEVICES_ADDON_DOWNLOAD_URL="https://github.com/TomMajor/SmartHome/archive/$HB_TM_DEVICES_ADDON_ARCHIVE_TAG.tar.gz"

PKG_BUILD=123

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
    sed -i "s/\(array[[:space:]]*set[[:space:]]*DEV_PATHS[[:space:]]*{\)/\1$DEVDBINSERT/g" $WORK_DIR/repo/www/config/devdescr/DEVDB.tcl || throw "Insert into DEVDB.tcl failed"
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
  run "Download OpenCCU-Base" wget -O openccu-base.tar.gz $OCCU_BASE_DOWNLOAD_URL
  run "Extract OpenCCU-Base" tar xzf openccu-base.tar.gz
  mv OpenCCU-Base-$OCCU_BASE_COMMIT repo
}
run "Download OpenCCU-Base source" download_occu

cd $WORK_DIR/repo
# These upstream files use CRLF, while debmatic.patch uses LF.
run "Normalize OpenCCU-Base patch targets to LF" dos2unix \
  www/api/methods/session/create.tcl \
  www/api/methods/session/login.tcl \
  www/api/methods/session/renew.tcl \
  www/rega/pages/tabs/startpage.htm \
  www/tcl/eq3/session.tcl
run "Apply debmatic patches" patch -E -l -p1 < $CURRENT_DIR/debmatic.patch

run "Add HmIP-RFUSB device to DEVDB" add_device_to_devdb "HmIP-RFUSB" "CCU3"

cd $WORK_DIR

function download_jp_addon {
  run "Download addon package" wget -O JP-HB-Devices-addon.tar.gz $JP_HB_DEVICES_ADDON_DOWNLOAD_URL
  run "Extract addon package" tar xzf JP-HB-Devices-addon.tar.gz
  mv JP-HB-Devices-addon-$JP_HB_DEVICES_ADDON_ARCHIVE_TAG JP-HB-Devices-addon
}
run "Download JP-HB-Devices-Addon" download_jp_addon

cd $WORK_DIR/repo/www

function add_global_page_hook {
  sed -i "\~</body>~i\    <script type=\"text/javascript\" src=\"/webui/js/extern/jp_webui_inc.js\"></script>" $WORK_DIR/repo/www/rega/pages/index.htm
}

function add_hook_js_calls {
  echo "\n<%  if (action == \"servoOldVal\")     { Call(\"channels.fn::servoOldVal()\"); } %>" >> $WORK_DIR/repo/www/rega/esp/channels.htm
  echo "\n<%  if (action == \"fanOldVal\")     { Call(\"channels.fn::fanOldVal()\"); } %>" >> $WORK_DIR/repo/www/rega/esp/channels.htm
  echo "\n<%  if (action == \"airflapOldVal\")     { Call(\"channels.fn::airflapOldVal()\"); } %>" >> $WORK_DIR/repo/www/rega/esp/channels.htm
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

  run "Copy www data" cp -ar $WORK_DIR/JP-HB-Devices-addon/src/addon/www/* $WORK_DIR/repo/www/
  run "Copy jp_webui_inc.js" cp $WORK_DIR/JP-HB-Devices-addon/src/addon/www/webui/js/extern/jp_webui_inc.js $WORK_DIR/repo/www/webui/js/extern/
  run "Copy rftypes" cp $WORK_DIR/JP-HB-Devices-addon/src/addon/firmware/rftypes/* $WORK_DIR/repo/firmware/rftypes/

  run "Add scripts registration" add_global_page_hook

  mkdir -p $WORK_DIR/repo/www/config/easymodes/KEY/localization/de
  run "Add GENERIC KEY easymodes DE" cp $WORK_DIR/repo/www/config/easymodes/BLIND/localization/de/GENERIC.txt $WORK_DIR/repo/www/config/easymodes/KEY/localization/de/
  run "Add KEY easymodes DE" cp $WORK_DIR/repo/www/config/easymodes/BLIND/localization/de/KEY.txt $WORK_DIR/repo/www/config/easymodes/KEY/localization/de/
  mkdir -p $WORK_DIR/repo/www/config/easymodes/KEY/localization/en
  run "Add GENERIC KEY easymodes EN" cp $WORK_DIR/repo/www/config/easymodes/BLIND/localization/en/GENERIC.txt $WORK_DIR/repo/www/config/easymodes/KEY/localization/en/
  run "Add KEY easymodes EN" cp $WORK_DIR/repo/www/config/easymodes/BLIND/localization/en/KEY.txt $WORK_DIR/repo/www/config/easymodes/KEY/localization/en/

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

cd $WORK_DIR/repo/www

function apply_tm_addon {
  run "Copy www data" cp -ar $WORK_DIR/HB-TM-Devices-addon/HB-TM-Devices-AddOn/CCU_RM/src/addon/www/* $WORK_DIR/repo/www/
  run "Copy rftypes" cp $WORK_DIR/HB-TM-Devices-addon/HB-TM-Devices-AddOn/CCU_RM/src/addon/firmware/rftypes/* $WORK_DIR/repo/firmware/rftypes/

  for file in $WORK_DIR/HB-TM-Devices-addon/HB-TM-Devices-AddOn/CCU_RM/src/addon/install_*; do
    sed -i "s|/www/|$WORK_DIR/repo/www/|g" $file
    chmod +x $file
    basefile=`basename $file`
    run "Run installer $basefile" $file
  done
}
run "Apply HB-TM-Devices-Addon" apply_tm_addon

cd $WORK_DIR

declare -A architectures=(["armhf"]="arm-linux-gnueabihf" ["arm64"]="aarch64-linux-gnu" ["i386"]="i686-linux-gnu" ["amd64"]="x86_64-linux-gnu")

function build_arch_package {
  ARCH=$1

  ARCH_SOURCE_DIR=${architectures[$ARCH]}

  TARGET_DIR=$WORK_DIR/debmatic-$PKG_VERSION-$ARCH

  mkdir -p $TARGET_DIR/bin
  run "Copy HM scripts" cp -pR $WORK_DIR/repo/bin/hm_* $TARGET_DIR/bin/
  for file in $WORK_DIR/repo/bin/$ARCH_SOURCE_DIR/*; do
    binary=`basename $file`
    if [ "$binary" != ReGaHss ]; then
      run "Copy $binary binary" cp -pR $file $TARGET_DIR/bin/
    fi
  done
  run "Install upstream ReGaHss binary" install -m 0755 $WORK_DIR/repo/bin/$ARCH_SOURCE_DIR/ReGaHss $TARGET_DIR/bin/ReGaHss.normal

  mkdir -p $TARGET_DIR/usr/share/debmatic/lib
  run "Copy OCCU libraries" cp -pR $WORK_DIR/repo/lib/$ARCH_SOURCE_DIR/* $TARGET_DIR/usr/share/debmatic/lib/

  mkdir -p $TARGET_DIR/lib/
  mkdir -p $TARGET_DIR/usr/share/tcltk
  run "Copy Homematic Tcl package" cp -pR $WORK_DIR/repo/usr/lib/tcl8.2/homematic $TARGET_DIR/usr/share/tcltk/

  run "Copy firmware files" cp -pR $WORK_DIR/repo/firmware $TARGET_DIR/

  mkdir -p $TARGET_DIR/opt
  run "Copy HMServer files" cp -pR $WORK_DIR/repo/opt/HMServer $TARGET_DIR/opt/
  run "Copy HmIP files" cp -pR $WORK_DIR/repo/opt/HmIP $TARGET_DIR/opt/

  run "Copy www files" cp -pR $WORK_DIR/repo/www $TARGET_DIR/

  run "Copy debmatic files" cp -pR $CURRENT_DIR/debmatic/* $TARGET_DIR

  run "Enable WebUI backup helper" chmod +x $TARGET_DIR/usr/share/debmatic/bin/create_webui_backup.sh

  echo "VERSION=$CCU_VERSION.$PKG_BUILD" > $TARGET_DIR/usr/share/debmatic/VERSION

  cat > $TARGET_DIR/VERSION << EOF
VERSION=$CCU_VERSION.$PKG_BUILD
PRODUCT=debmatic
PLATFORM=$ARCH
EOF

  for file in $TARGET_DIR/DEBIAN/*; do
    LIBC_DEPENDS="libc6 (>= 2.29), libstdc++6"

    sed -i "s/{PKG_VERSION}/$PKG_VERSION/g" $file
    sed -i "s/{PKG_ARCH}/$ARCH/g" $file
    sed -i "s/{CCU_VERSION}/$CCU_VERSION/g" $file
    sed -i "s/{LIBC_DEPENDS}/$LIBC_DEPENDS/g" $file
  done

  sed -i "s/XXX-WEBUI-VERSION-XXX/$CCU_VERSION.$PKG_BUILD/g" $TARGET_DIR/www/rega/pages/index.htm
  sed -i "s/XXX-PRODUCT-XXX/debmatic/g" $TARGET_DIR/www/rega/pages/index.htm

  cd $WORK_DIR

  run "Create deb" dpkg-deb --root-owner-group --build -Zxz debmatic-$PKG_VERSION-$ARCH
}

for ARCH in "${!architectures[@]}"
do
  run "Build $ARCH package" build_arch_package $ARCH
done

run "Copy packages to local directory" cp debmatic-*.deb $CURRENT_DIR
run "Remove temporary files" rm -rf $WORK_DIR

