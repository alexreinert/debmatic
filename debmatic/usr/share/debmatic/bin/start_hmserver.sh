#!/bin/bash
JAVA_HOME=$(update-java-alternatives --jre-headless --list | grep "\\W\(108\|111\|211\|180\)[0-9]\+\\W" | tr -s " " | sort -k2 | tail -1 | cut -d" " -f3)

CLAZZPATH=$(find /opt/HMServer/ -type f -name "*.jar" | grep -v "HM\(IP\)\?Server.jar" | xargs echo | sed s/' '/':'/g)

if [ -z "$HM_HMIP_DEV" ]; then
  HMSERVER_BIN="HMServer"
  HMSERVER_ARGS="de.eq3.ccu.server.HMServer /etc/HMServer.conf"
else
  HMSERVER_DEV="/dev/mmd_hmip"
  if [[ "${HM_HMIP_DEV}" == "HMIP-RFUSB-TK" ]]; then
    HMSERVER_DEV="$HM_HMIP_DEVNODE"
  fi
  HMSERVER_BIN="HMIPServer"
  HMSERVER_ARGS="de.eq3.ccu.server.ip.HMIPServer /var/run/crRFD.conf /etc/HMServer.conf"
  sed "s|^Adapter\.1\.Port=.*$|Adapter.1.Port=${HMSERVER_DEV}|" /etc/crRFD.conf > /var/run/crRFD.conf
#  if [[ "${HM_HMIP_DEV}" != "RPI-RF-MOD" && "${HM_HMIP_DEV}" != "HMIP-RFUSB" ]]; then
  if [[ "${HM_HMIP_DEV}" != "RPI-RF-MOD" ]]; then
    sed -i "s|^Lan\.Routing\.Enabled=.*$|Lan.Routing.Enabled=false|" /var/run/crRFD.conf
    sed -i "s|^Adapter\.Local\.Device\.Enabled=.*$|Adapter.Local.Device.Enabled=false|" /var/run/crRFD.conf
  fi
fi

JAVA_HOME=$JAVA_HOME $JAVA_HOME/bin/java -Xmx128m -Dlog4j.configuration=file:///etc/config/log4j.xml -Dfile.encoding=ISO-8859-1 $JAVA_ARGS -Dgnu.io.rxtx.SerialPorts=$HMSERVER_DEV -cp ${CLAZZPATH}:/opt/HMServer/$HMSERVER_BIN.jar $HMSERVER_ARGS &
echo $! > /var/run/HMIPServer.pid

for i in {1..120}; do
  sleep 2

  if [ -e /var/status/HMServerStarted ]; then
    break
  fi
done

