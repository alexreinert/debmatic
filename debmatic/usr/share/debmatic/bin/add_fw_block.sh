#!/bin/bash
if [[ $# -le 1 ]]; then
  echo "$0 <Table> <port> ... [port]"
  exit 1
fi

TABLENAME=$1
shift

if $(command -v nft > /dev/null); then
  nft add table ip $TABLENAME
  nft add table ip6 $TABLENAME
  nft add chain ip $TABLENAME INPUT { type filter hook input priority 0 \; }
  nft add chain ip6 $TABLENAME INPUT { type filter hook input priority 0 \; }
  for port in "$@"; do
    nft insert rule ip $TABLENAME INPUT ip saddr != 127.0.0.1 tcp dport $port counter drop
    nft insert rule ip6 $TABLENAME INPUT ip6 saddr != ::1 tcp dport $port counter drop
  done
elif $(command -v iptables > /dev/null); then
  for port in "$@"; do
    iptables -I INPUT -p tcp ! -s 127.0.0.1 --dport $port -m comment --comment "$TABLENAME drop port $port" -j DROP
    ip6tables -I INPUT -p tcp ! -s ::1 --dport $port -m comment --comment "$TABLENAME drop port $port" -j DROP
  done
else
  echo "Neither iptables nor nft were found"
  exit 1
fi

