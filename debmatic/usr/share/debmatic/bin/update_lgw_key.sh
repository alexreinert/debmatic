#!/bin/bash

for file in /etc/config/*.keychange
do
  SERIAL=$(grep Serial "$file" | sed s/Serial=//)
  IP=$(grep IP "$file" | sed s/IP=//)
  KEY=$(grep KEY "$file" | sed s/KEY=//)
  CURKEY=$(grep CURKEY "$file" | sed s/CURKEY=//)
  CLASS=$(grep Class "$file" | sed s/Class=//)

  if [ "$CLASS" == "Wired" ]; then
    CONFFILE=/etc/config/hs485d.conf
  elif [ "$CLASS" == "RF" ]; then
    CONFFILE=/etc/config/rfd.conf
  else
    exit 1 
  fi

  if [ "$IP" == "" ]; then
    eq3configcmd setlgwkey -s "$SERIAL" -c "$CURKEY" -n "$KEY" -f $CONFFILE -l 1	
  else
    eq3configcmd setlgwkey -s "$SERIAL" -h "$IP" -c "$CURKEY" -n "$KEY" -f $CONFFILE -l 1	
  fi

  if [ $? -eq 0 ]; then
    rm -f "$file"
  fi
done

