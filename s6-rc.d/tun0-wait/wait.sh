#!/bin/bash

# 等待 tun0 设备就绪
while ! ip a show tun0 > /dev/null 2>&1; do
  echo "waiting for tun0..."
  sleep 1
done

echo "[wait-tun0] tun0 is ready."

DEFAULT_IF=$(ip route show default | awk '{print $5}' | head -n1)

echo "default interface: $DEFAULT_IF"

IFS=',' read -ra NETS <<< "$LOCAL_NETS"

for net in "${NETS[@]}"; do

  ip route replace "$net" dev "$DEFAULT_IF"

done