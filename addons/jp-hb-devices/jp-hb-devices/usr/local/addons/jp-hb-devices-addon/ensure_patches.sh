#!/bin/bash
ADDON_NAME=jp-hb-devices-addon

ADDON_DIR=/usr/local/addons/${ADDON_NAME}
PATCH_DIR=${ADDON_DIR}/patch
WWW_DIR=/etc/config/addons/www/${ADDON_NAME}
LOG_DIR=${ADDON_DIR}/log
GLOBAL_LOGFILE=$LOG_DIR/inst.log
GLOBAL_ERRFILE=$LOG_DIR/inst.err
PATCH_REVOKE_ERRFILE=$ADDON_DIR/log/revoke.err
FIRMWARE_DIR=/firmware/rftypes
CUSTOMIZED_FIRMWARE_DIR=${ADDON_DIR}/customized_firmware
RC_DIR=/usr/local/etc/config/rc.d
CK_FIRMWARE_FILE=${FIRMWARE_DIR}/hb-uni-sen-cap-moist.xml

PATCHVERSION=0
check_ccu_fw_version()
{
 model=`grep VERSION /boot/VERSION   | awk -F'[=.]' {'print $2'}`
 version=`grep VERSION /boot/VERSION | awk -F'[=.]' {'print $3'}`
 build=`grep VERSION /boot/VERSION   | awk -F'[=.]' {'print $4'}`

 if [ $model -ge 2 ] && [ $version -ge 45 ]; then
  PATCHVERSION=2
 else
  PATCHVERSION=1
 fi
 
 echo "Found firmware version $model.$version.$build - using patchversion $PATCHVERSION" | tee -a $GLOBAL_LOGFILE
}

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
  check_ccu_fw_version

  cd /www

  ########################	REVOKE  	######################
  echo "######## REVOKE COMMON APPLIED PATCHES ########" | tee -a $GLOBAL_LOGFILE
  patchsubdir=common
  for patchfile in `ls ${PATCH_DIR}/revoke/$patchsubdir/* | sort`; do 
    echo "### Rejecting $patchsubdir patch file $patchfile" | tee -a $GLOBAL_LOGFILE | tee -a $PATCH_REVOKE_ERRFILE
    patch --dry-run -R -s -f -p3 -i $patchfile && patch -R -p3 -i $patchfile >> $GLOBAL_LOGFILE 2>>$PATCH_REVOKE_ERRFILE
  done
        
  echo "######## REVOKE VERSION DEPENDEND PATCHES ########" | tee -a $GLOBAL_LOGFILE
  if [ $PATCHVERSION -le 1 ]; then
    patchsubdir=le_343
  else
    patchsubdir=ge_345
  fi
  for patchfile in `ls ${PATCH_DIR}/revoke/$patchsubdir/* | sort`; do 
    echo "### Rejecting $patchsubdir patch file $patchfile" | tee -a $GLOBAL_LOGFILE | tee -a $PATCH_REVOKE_ERRFILE
          patch --dry-run -R -s -f -p3 -i $patchfile && patch -R -p3 -i $patchfile >> $GLOBAL_LOGFILE 2>>$PATCH_REVOKE_ERRFILE
  done
        
  ########################	APPLY   	######################
  echo "######## APPLY COMMON PATCHES ########" | tee -a $GLOBAL_LOGFILE
  patchsubdir=common
  for patchfile in ${PATCH_DIR}/$patchsubdir/* ; do
    echo "### Applying $patchsubdir patch file $(basename $patchfile)" | tee -a $GLOBAL_LOGFILE | tee -a $GLOBAL_ERRFILE
    patch -N -p3 -i $patchfile >> $GLOBAL_LOGFILE 2>>$GLOBAL_ERRFILE
  done
        
  echo "######## APPLY VERSION DEPENDEND PATCHES ########" | tee -a $GLOBAL_LOGFILE
  if [ $PATCHVERSION -le 1 ]; then
    patchsubdir=le_343
  else
    patchsubdir=ge_345
  fi
      
  for patchfile in ${PATCH_DIR}/$patchsubdir/* ; do
    echo "Applying $patchsubdir patch file $(basename $patchfile)" | tee -a $GLOBAL_LOGFILE
    patch -N -p3 -i $patchfile >> $GLOBAL_LOGFILE 2>>$GLOBAL_ERRFILE
  done

  [[ -f ./config/ic_common.tcl.orig ]] && rm ./config/ic_common.tcl.orig
  [[ -f ./rega/esp/side.inc.orig ]] && rm ./rega/esp/side.inc.orig
  [[ -f ./rega/esp/functions.fn.orig ]] && rm ./rega/esp/functions.fn.orig
  [[ -f ./rega/pages/tabs/admin/views/programs.htm.orig ]] && rm ./rega/pages/tabs/admin/views/programs.htm.orig
  [[ -f ./rega/esp/datapointconfigurator.fn.orig ]] && rm ./rega/esp/datapointconfigurator.fn.orig
  [[ -f ./webui/webui.js.orig ]] && rm ./webui/webui.js.orig

  ### Create Symlink to include own js file
  echo "(Re-)Creating symlinks for jp_webui_inc.js..." | tee -a $GLOBAL_LOGFILE
  [[ ! -f /www/webui/js/extern/jp_webui_inc.js ]] && ln -s /usr/local/addons/jp-hb-devices-addon/js/jp_webui_inc.js /www/webui/js/extern/jp_webui_inc.js
 
  cd ${ADDON_DIR}
  echo "Running scripts..." | tee -a $GLOBAL_LOGFILE
  for f in ${ADDON_DIR}/install_* ; do echo "  - $(basename $f)"; ./$(basename $f) >> $GLOBAL_LOGFILE 2>>$GLOBAL_ERRFILE; done

  echo "Copying customized firmware files..." | tee -a $GLOBAL_LOGFILE
  if [ -d ${CUSTOMIZED_FIRMWARE_DIR} ]; then
    cp ${CUSTOMIZED_FIRMWARE_DIR}/* ${ADDON_DIR}${FIRMWARE_DIR}/
  fi

  echo "(Re-)Creating symlinks for firmware files..." | tee -a $GLOBAL_LOGFILE
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

