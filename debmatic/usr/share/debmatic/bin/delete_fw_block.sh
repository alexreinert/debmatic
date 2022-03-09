#!/bin/bash
if [[ $# -le 1 ]]; then
  echo "$0 <Table> <port> ... [port]"
  exit 1
fi

TABLENAME=$1
shift

if $(command -v nft > /dev/null); then
  nft delete table ip $TABLENAME
  nft delete table ip6 $TABLENAME
elif $(command -v iptables > /dev/null); then
  for port in "$@"; do
    iptables -D INPUT -p tcp ! -s 127.0.0.1 --dport $port -m comment --comment "$TABLENAME drop port $port" -j DROP
    ip6tables -D INPUT -p tcp ! -s ::1 --dport $port -m comment --comment "$TABLENAME drop port $port" -j DROP
  done
else
  echo "Neither iptables nor nft were found"
  exit 1
fi

