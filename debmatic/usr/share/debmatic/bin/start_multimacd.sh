#!/bin/bash
sysctl -w kernel.sched_rt_runtime_us=-1 || true
modprobe -q eq3_char_loop || true

if [ ! -e /dev/eq3loop ]; then
  mknod /dev/eq3loop c `cat /sys/devices/virtual/eq3loop/eq3loop/dev | tr ':' ' '`
fi

sed "s|^Coprocessor Device Path = .*$|Coprocessor Device Path = ${HM_HOST_GPIO_UART}|" /etc/multimacd.conf > /var/run/multimacd.conf
/bin/multimacd -l 5 -f /var/run/multimacd.conf -d
/usr/share/debmatic/bin/create_pid_file /var/run/multimacd.pid /bin/multimacd

for i in {1..10}; do
  sleep 2

  if [ -e /var/status/multimacd.status ] && [ "`cat /var/status/multimacd.status`" == "`pidof /bin/multimacd`" ]; then
    break
  fi
done

for dev in mmd_bidcos mmd_hmip; do
  for i in {1..10}; do
    if [ -e /sys/devices/virtual/eq3loop/$dev/dev ]; then
      if [ ! -e /dev/$dev ]; then
        mknod /dev/$dev c `cat /sys/devices/virtual/eq3loop/$dev/dev | tr ':' ' '`
      fi
      break
    fi

    sleep 1
  done
done

