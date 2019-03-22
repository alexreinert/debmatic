#!/bin/bash
ADDON_NAME=jp-hb-devices-addon

ADDON_DIR=/usr/local/addons/${ADDON_NAME}
WWW_DIR=/etc/config/addons/www/${ADDON_NAME}
LOGFILE=/var/log/$ADDON_NAME.log
ERRFILE=/var/log/$ADDON_NAME.err
FIRMWARE_DIR=/firmware/rftypes
CUSTOMIZED_FIRMWARE_DIR=${ADDON_DIR}/customized_firmware
RC_DIR=/usr/local/etc/config/rc.d
CK_FIRMWARE_FILE=${FIRMWARE_DIR}/hb-uni-sen-cap-moist.xml

if [ ! -f ${ADDON_DIR}/installed ] || [ ! -f ${CK_FIRMWARE_FILE} ]; then      
  cd ${ADDON_DIR}
  cp -ar www/* /www/
  chown root:root /www/config/img/devices/250/hb-*
  chmod 755 /www/config/img/devices/250/hb-*
  chown root:root /www/config/img/devices/50/hb-*
  chmod 755 /www/config/img/devices/50/hb-*
  chown root:root /www/ise/img/icons_hm_dis_ep_wm55/24/*
  chmod 755 /www/ise/img/icons_hm_dis_ep_wm55/24/*
  
  ### Patch some files ###
  cd /www

  patch --dry-run -R -s -f -p3 -i /usr/local/addons/jp-hb-devices-addon/patch/jp.patch && patch -R -p3 -i /usr/local/addons/jp-hb-devices-addon/patch/jp.patch 
  patch --dry-run -R -s -f -p3 -i /usr/local/addons/jp-hb-devices-addon/patch/hb-dis-ep-42bw.patch && patch -R -p3 -i /usr/local/addons/jp-hb-devices-addon/patch/hb-dis-ep-42bw.patch
  patch --dry-run -R -s -f -p3 -i /usr/local/addons/jp-hb-devices-addon/patch/hb-ou-mp3-led_side.inc.not_used.patch && patch -R -p3 -i /usr/local/addons/jp-hb-devices-addon/patch/hb-ou-mp3-led_side.inc.not_used.patch
  patch --dry-run -R -s -f -p3 -i /usr/local/addons/jp-hb-devices-addon/patch/hb-uni-sen-rfid-rc.patch && patch -R -p3 -i /usr/local/addons/jp-hb-devices-addon/patch/hb-uni-sen-rfid-rc.patch
  patch --dry-run -R -s -f -p3 -i /usr/local/addons/jp-hb-devices-addon/patch/programs_wrong_encodeStringStatusDisplay.patch && patch -R -p3 -i /usr/local/addons/jp-hb-devices-addon/patch/programs_wrong_encodeStringStatusDisplay.patch
  patch -N -p3 -i /usr/local/addons/jp-hb-devices-addon/patch/jp.patch 

  [[ -f ./config/ic_common.tcl.orig ]] && rm ./config/ic_common.tcl.orig
  [[ -f ./rega/esp/side.inc.orig ]] && rm ./rega/esp/side.inc.orig
  [[ -f ./rega/esp/functions.fn.orig ]] && rm ./rega/esp/functions.fn.orig
  [[ -f ./rega/pages/tabs/admin/views/programs.htm.orig ]] && rm ./rega/pages/tabs/admin/views/programs.htm.orig
  [[ -f ./rega/esp/datapointconfigurator.fn.orig ]] && rm ./rega/esp/datapointconfigurator.fn.orig
  [[ -f ./webui/webui.js.orig ]] && rm ./webui/webui.js.orig

  ### Create Symlink to include own js file
  ln -s /usr/local/addons/jp-hb-devices-addon/js/jp_webui_inc.js /www/webui/js/extern/jp_webui_inc.js
      
  cd ${ADDON_DIR}
  echo "Running scripts..."    
  for f in ${ADDON_DIR}/install_* ; do echo "  - $(basename $f)"; ./$(basename $f) > $LOGFILE 2>$ERRFILE; done

  echo "Copying customized firmware files..."
  if [ -d ${CUSTOMIZED_FIRMWARE_DIR} ]; then
    cp ${CUSTOMIZED_FIRMWARE_DIR}/* ${ADDON_DIR}${FIRMWARE_DIR}/
  fi

  echo "Creating symlinks for firmware files..."
  for f in ${ADDON_DIR}${FIRMWARE_DIR}/* ; do rm -f ${FIRMWARE_DIR}/$(basename $f); ln -s $f ${FIRMWARE_DIR}/$(basename $f); echo "  - $(basename $f)"; done

  touch ${ADDON_DIR}/installed
else
  echo "Checking for subsequent customized firmware files..."

  for f in ${ADDON_DIR}${FIRMWARE_DIR}/* ; do
  $(cmp -s ${CUSTOMIZED_FIRMWARE_DIR}/$(basename $f) $f)
    rc=$?
    if [ $rc -eq 1 ]; then
      echo "Difference detected for $(basename $f). Copying..."
      cp ${CUSTOMIZED_FIRMWARE_DIR}/$(basename $f) $f
    fi
  done
fi

