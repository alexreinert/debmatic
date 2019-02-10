#!/bin/bash

if [ -z "$HM_HMIP_DEV" ]; then
  HMSERVER_BIN="HMServer"
  HMSERVER_ARGS="/etc/HMServer.conf"
else
  HMSERVER_BIN="HMIPServer"
  HMSERVER_ARGS="/var/run/crRFD.conf /etc/HMServer.conf"
  sed "s|^Adapter\.1\.Port=.*$|Adapter.1.Port=${HM_HMIP_DEVNODE}|" /etc/crRFD.conf > /var/run/crRFD.conf
fi

/usr/bin/java -Xmx128m -Dlog4j.configuration=file:///etc/config/log4j.xml -Dfile.encoding=ISO-8859-1 -Dgnu.io.rxtx.SerialPorts=$HM_HMIP_DEVNODE -jar /opt/HMServer/$HMSERVER_BIN.jar $HMSERVER_ARGS &
echo $! > /var/run/HMIPServer.pid

for i in {1..120}; do
  sleep 2

  if [ -e /var/status/HMServerStarted ]; then
    break
  fi
done

