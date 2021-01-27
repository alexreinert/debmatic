#!/bin/bash

cp /etc/config_templates/InterfacesList.xml /etc/config

if [[ -z "${HM_HMIP_DEV}" ]]; then
  sed -En '1h;1!H;${;g;s/\s*<ipc>\s*<name>HmIP-RF<\/name>(\s*<[^\/[^>]+>[^>]+>)*\s*<\/ipc>//g;p;}' -i /etc/config/InterfacesList.xml
fi

if [[ -z "${HM_HMRF_DEV}" ]] && ( [[ ! -f /etc/config/rfd.conf ]] || ! grep -E -q "^Type = (HMLGW2|Lan Interface)" /etc/config/rfd.conf ); then
  sed -En '1h;1!H;${;g;s/\s*<ipc>\s*<name>BidCos-RF<\/name>(\s*<[^\/[^>]+>[^>]+>)*\s*<\/ipc>//g;p;}' -i /etc/config/InterfacesList.xml
fi

if [ -e /etc/config/hs485d.conf ]; then
  /bin/hs485dLoader -l "${LOGLEVEL_HS485D}" -ds -dd /etc/config/hs485d.conf
fi

