#!/bin/bash
sed -i 's/^AccessFile/#AccessFile/' /etc/config/rfd.conf || true
sed -i 's/^ResetFile/#ResetFile/' /etc/config/rfd.conf || true

if [ ! -z "$HM_HMRF_DEV" ] && [ "$HM_HMRF_DEV" != "HM-CFG-USB-2" ]; then
  if ! grep -q "^Type = CCU2" /etc/config/rfd.conf; then
    echo "" >> /etc/config/rfd.conf
    echo "" >> /etc/config/rfd.conf
    echo "[Interface 0]" >> /etc/config/rfd.conf
    echo "Type = CCU2" >> /etc/config/rfd.conf
    echo "ComPortFile = /dev/mmd_bidcos" >> /etc/config/rfd.conf
  fi
  sed -i 's|^ComPortFile = .*$|ComPortFile = /dev/mmd_bidcos|' /etc/config/rfd.conf
  sed -i 's/^AccessFile/#AccessFile/' /etc/config/rfd.conf
  sed -i 's/^ResetFile/#ResetFile/' /etc/config/rfd.conf
  if ! grep -q "Improved Coprocessor Initialization" /etc/config/rfd.conf ; then
    sed -i 's/\[Interface 0\]/Improved\ Coprocessor\ Initialization\ =\ true\n\n&/' /etc/config/rfd.conf
  fi
else
  sed -i -En '1h;1!H;${;g;s/\n+\[Interface .\]\n([^\n]+\n)*Type = CCU2\n([^\n]+(\n|^))*//g;p;}' /etc/config/rfd.conf
fi

if [ "$HM_HMRF_DEV" == "HM-CFG-USB-2" ]; then
  if ! grep -q "^Name = HM-CFG-USB" /etc/config/rfd.conf; then
    for inum in {0..9}; do
      if ! grep "^\[Interface $inum\]" /etc/config/rfd.conf; then
        break
      fi
    done
    echo >> /etc/config/rfd.conf
    echo >> /etc/config/rfd.conf
    echo "[Interface $inum]" >> /etc/config/rfd.conf
    echo "Type = USB Interface" >> /etc/config/rfd.conf
    echo "Name = HM-CFG-USB" >> /etc/config/rfd.conf
    echo "Serial Number = $HM_HMRF_SERIAL" >> /etc/config/rfd.conf
    echo "Encryption Key =" >> /etc/config/rfd.conf
  fi
elif grep -q "^Name = HM-CFG-USB" /etc/config/rfd.conf; then
  sed -i -En '1h;1!H;${;g;s/\n+\[Interface .\]\n([^\n]+\n)*Name = HM-CFG-USB\n([^\n]+(\n|^))*//g;p;}' /etc/config/rfd.conf
fi

/bin/rfd -l $LOGLEVEL_RFD -f /etc/config/rfd.conf -d
/usr/share/debmatic/bin/create_pid_file /var/run/rfd.pid /bin/rfd

for i in {1..60}; do
  sleep 2

  if [ -e /var/status/rfd.status ] && [ "`cat /var/status/rfd.status`" == "`pidof /bin/rfd`" ]; then
    break
  fi
done

