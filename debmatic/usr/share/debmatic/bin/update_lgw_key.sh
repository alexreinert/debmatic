#!/bin/bash

for file in `ls /etc/config/*.keychange`
do
  SERIAL=`cat $file | grep Serial | sed s/Serial=//`
  IP=`cat $file | grep IP | sed s/IP=//`
  KEY=`cat $file | grep KEY | sed s/KEY=//`
  CURKEY=`cat $file | grep CURKEY | sed s/CURKEY=//`
  CLASS=`cat $file | grep Class | sed s/Class=//`

  if [ "$CLASS" == "Wired" ]; then
    CONFFILE=/etc/config/hs485d.conf
  elif [ "$CLASS" == "RF" ]; then
    CONFFILE=/etc/config/rfd.conf
  else
    exit 1 
  fi

  if [ "$IP" == "" ]; then
    eq3configcmd setlgwkey -s $SERIAL -c $CURKEY -n $KEY -f $CONFFILE -l 1	
  else
    eq3configcmd setlgwkey -s $SERIAL -h $IP -c $CURKEY -n $KEY -f $CONFFILE -l 1	
  fi

  if [ $? -eq 0 ]; then
    rm -f $file
  fi
done

