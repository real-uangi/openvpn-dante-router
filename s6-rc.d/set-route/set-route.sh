#!/bin/bash

DEFAULT_IF=$(ip route show default | awk '{print $5}' | head -n1)

echo "default interface: $DEFAULT_IF"

IFS=',' read -ra NETS <<< "$LOCAL_NETS"

for net in "${NETS[@]}"; do

  echo "route $net via 172.17.0.1 dev $DEFAULT_IF"
  ip route replace "$net" dev "$DEFAULT_IF"

done