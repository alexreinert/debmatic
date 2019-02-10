#!/bin/bash

RED_PIN=0
GREEN_PIN=0
BLUE_PIN=0

if [ "$HM_HMRF_DEV" == "RPI-RF-MOD" ]; then
  modprobe dummy_rx8130
  if [ -e "/sys/class/raw-uart/$HM_HOST_RAW_UART/red_gpio_pin" ]; then
    RED_PIN=`cat /sys/class/raw-uart/$HM_HOST_RAW_UART/red_gpio_pin`
    GREEN_PIN=`cat /sys/class/raw-uart/$HM_HOST_RAW_UART/green_gpio_pin`
    BLUE_PIN=`cat /sys/class/raw-uart/$HM_HOST_RAW_UART/blue_gpio_pin`
  fi
fi

modprobe ledtrig-default-on || true
modprobe ledtrig-timer || modprobe led_trigger_timer || true
modprobe rpi_rf_mod_led red_gpio_pin=$RED_PIN green_gpio_pin=$GREEN_PIN blue_gpio_pin=$BLUE_PIN || true

