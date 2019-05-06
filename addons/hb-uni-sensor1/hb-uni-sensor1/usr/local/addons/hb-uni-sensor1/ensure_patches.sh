#!/bin/bash
ADDON_NAME=hb-uni-sensor1

. /usr/local/addons/${ADDON_NAME}/params 2>/dev/null
. /usr/local/addons/${ADDON_NAME}/functions 2>/dev/null

ADDON_DIR=/usr/local/addons/${ADDON_NAME}
WWW_DIR=/etc/config/addons/www/${ADDON_NAME}
RC_DIR=/usr/local/etc/config/rc.d
CUSTOM_FIRMWARE_DIR=${ADDON_DIR}/custom_firmware

LOGFILE=$ADDON_DIR/inst.log
ERRFILE=$ADDON_DIR/inst.err

if [ ! -f ${ADDON_DIR}/installed ] || [ ! -f ${FIRMWARE_FILE} ]; then
  logToFile $LOGFILE "($1) Installing $ADDON_NAME $ADDON_VERSION"

  # Prepare
  #----------------------------------------------

  check_ccu_fw_version
  logToFile $LOGFILE "Found firmware version $FW_VERSION - using patchversion $PATCHVERSION"

  # Action
  #----------------------------------------------

  cd ${ADDON_DIR}

  # run AddOn spezific install script
  ./install >> $LOGFILE 2>>$ERRFILE

  # copy/overwrite default firmware with custom firmware files if they exist
  for file in ${CUSTOM_FIRMWARE_DIR}/*.xml ; do
    [ -f "$file" ] || continue    # processing für *.xml verhindern falls nichts gefunden, 'shopt -s nullglob' nicht verfügbar
    logToFile $LOGFILE "Copy custom firmware file: $(basename $file)"
    cp -f $file ${ADDON_DIR}${FIRMWARE_DIR}
  done

  # Unprepare
  #----------------------------------------------

  touch ${ADDON_DIR}/installed

  logToFile $LOGFILE "Installation done."
else
  # check for user updated custom firmware files
  for file in ${ADDON_DIR}${FIRMWARE_DIR}/*.xml ; do
    [ -f "$file" ] || continue    # processing für *.xml verhindern falls nichts gefunden, 'shopt -s nullglob' nicht verfügbar
    $(cmp -s ${CUSTOM_FIRMWARE_DIR}/$(basename $file) $file)
    rc=$?
    if [ $rc -eq 1 ]; then
      logToFile $LOGFILE "($1) Difference detected for custom firmware file: $(basename $file) => copying"
      cp -f ${CUSTOM_FIRMWARE_DIR}/$(basename $file) $file
    fi
  done
fi
