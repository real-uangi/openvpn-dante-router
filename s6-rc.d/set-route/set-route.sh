#!/bin/bash
set -euo pipefail

trim_spaces() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

DEFAULT_IF="$(ip -4 route show default | awk '
  $1 == "default" {
    dev = ""
    for (i = 1; i <= NF; i++) {
      if ($i == "dev" && i < NF) {
        dev = $(i + 1)
      }
    }
    if (dev != "" && dev != "tun0") {
      print dev
      exit
    }
  }
')"

DEFAULT_GW="$(ip -4 route show default | awk '
  $1 == "default" {
    dev = ""
    via = ""
    for (i = 1; i <= NF; i++) {
      if ($i == "dev" && i < NF) {
        dev = $(i + 1)
      }
      if ($i == "via" && i < NF) {
        via = $(i + 1)
      }
    }
    if (dev != "" && dev != "tun0") {
      print via
      exit
    }
  }
')"

if [ -z "$DEFAULT_IF" ]; then
  echo "[set-route] failed to resolve non-tun0 default interface" >&2
  exit 1
fi

if [ -n "$DEFAULT_GW" ]; then
  echo "[set-route] using default route via $DEFAULT_GW dev $DEFAULT_IF"
else
  echo "[set-route] using default route dev $DEFAULT_IF (no gateway)"
fi

DEFAULT_LOCAL_NETS='10.0.0.0/8,172.16.0.0/12,192.168.0.0/16'
EFFECTIVE_LOCAL_NETS="${LOCAL_NETS:-}"
if [ -z "${EFFECTIVE_LOCAL_NETS//[[:space:]]/}" ]; then
  EFFECTIVE_LOCAL_NETS="$DEFAULT_LOCAL_NETS"
  echo "[set-route] LOCAL_NETS is empty, fallback to default: $EFFECTIVE_LOCAL_NETS"
else
  echo "[set-route] LOCAL_NETS: $EFFECTIVE_LOCAL_NETS"
fi

IFS=',' read -r -a NETS <<< "$EFFECTIVE_LOCAL_NETS"

for raw_net in "${NETS[@]}"; do
  net="$(trim_spaces "$raw_net")"
  if [ -z "$net" ]; then
    continue
  fi

  if [ -n "$DEFAULT_GW" ]; then
    echo "[set-route] route $net via $DEFAULT_GW dev $DEFAULT_IF"
    ip route replace "$net" via "$DEFAULT_GW" dev "$DEFAULT_IF"
  else
    echo "[set-route] route $net dev $DEFAULT_IF"
    ip route replace "$net" dev "$DEFAULT_IF"
  fi
done
