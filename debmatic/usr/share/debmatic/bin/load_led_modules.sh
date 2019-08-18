#!/bin/bash

RED_PIN=0
GREEN_PIN=0
BLUE_PIN=0

if [ "$HM_HMRF_DEV" == "RPI-RF-MOD" ]; then
  if [ -e "/sys/module/generic_raw_uart/parameters/load_dummy_rx8130_module" ]; then
    echo 1 > /sys/module/generic_raw_uart/parameters/load_dummy_rx8130_module
  else
    modprobe dummy_rx8130
  fi

  if [ -e "/sys/class/raw-uart/$HM_HOST_RAW_UART/red_gpio_pin" ]; then
    RED_PIN=`cat /sys/class/raw-uart/$HM_HOST_RAW_UART/red_gpio_pin`
    GREEN_PIN=`cat /sys/class/raw-uart/$HM_HOST_RAW_UART/green_gpio_pin`
    BLUE_PIN=`cat /sys/class/raw-uart/$HM_HOST_RAW_UART/blue_gpio_pin`
  fi
fi

modprobe -q ledtrig-default-on || true
modprobe -q ledtrig-timer || modprobe -q led_trigger_timer || true

if [ -w "/sys/module/rpi_rf_mod_led/parameters/red_gpio_pin" ]; then
  echo "$RED_PIN" > /sys/module/rpi_rf_mod_led/parameters/red_gpio_pin
  echo "$GREEN_PIN" > /sys/module/rpi_rf_mod_led/parameters/green_gpio_pin
  echo "$BLUE_PIN" > /sys/module/rpi_rf_mod_led/parameters/blue_gpio_pin
else
  modprobe rpi_rf_mod_led red_gpio_pin=$RED_PIN green_gpio_pin=$GREEN_PIN blue_gpio_pin=$BLUE_PIN || true
fi

