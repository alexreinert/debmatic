#!/bin/bash

REGA_BIN_VERSION=NORMAL
if [ -e /etc/config/ReGaHssVersion ]; then
  REGA_BIN_VERSION=`cat /etc/config/ReGaHssVersion`
fi

case ${REGA_BIN_VERSION} in
  NORMAL)
    REGA_BIN_FILE=/bin/ReGaHss.normal
    ;;
  LEGACY)
    REGA_BIN_FILE=/bin/ReGaHss
    ;;
  COMMUNITY)
    REGA_BIN_FILE=/bin/ReGaHss.community
    ;;
  *)
    echo "Unsupported ReGaHss version: ${REGA_BIN_VERSION}" >&2
    exit 1
    ;;
esac

if [ ! -x "$REGA_BIN_FILE" ]; then
  echo "Requested ReGaHss binary is not installed: $REGA_BIN_FILE" >&2
  exit 1
fi

$REGA_BIN_FILE -f /etc/rega.conf -l $LOGLEVEL_REGA &
echo $! > /var/run/ReGaHss.pid

