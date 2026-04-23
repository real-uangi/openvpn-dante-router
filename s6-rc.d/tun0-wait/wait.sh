#!/bin/bash

# 等待 tun0 设备就绪
while ! ip a show tun0 > /dev/null 2>&1; do
  echo "waiting for tun0..."
  sleep 1
done

echo "[wait-tun0] tun0 is ready."