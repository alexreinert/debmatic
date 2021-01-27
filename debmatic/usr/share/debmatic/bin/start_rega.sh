#!/bin/bash

REGA_BIN_VERSION=NORMAL
if [ -e /etc/config/ReGaHssVersion ]; then
  REGA_BIN_VERSION=$(cat /etc/config/ReGaHssVersion)
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
esac

$REGA_BIN_FILE -f /etc/rega.conf -l "$LOGLEVEL_REGA" &
echo $! > /var/run/ReGaHss.pid

