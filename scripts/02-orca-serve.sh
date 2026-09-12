#!/usr/bin/env bash
# Install Orca AppImage + systemd orca-serve (pairing = Tailscale IPv4).
# Optional: ORCA_APPIMAGE_URL=... 
set -euo pipefail
STACK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
URL="${ORCA_APPIMAGE_URL:-https://github.com/stablyai/orca/releases/latest/download/orca-linux.AppImage}"
TS_IP="$(tailscale ip -4)"
id -u orca >/dev/null

mkdir -p /opt/orca
TMP="$(mktemp /opt/orca/orca-linux.AppImage.XXXXXX)"
curl -fL "$URL" -o "$TMP"
chmod +x "$TMP"
mv -f "$TMP" /opt/orca/orca-linux.AppImage
/opt/orca/orca-linux.AppImage --version 2>/dev/null | head -1 > /opt/orca/VERSION || echo "unknown" > /opt/orca/VERSION

sed "s/PAIRING_ADDRESS/$TS_IP/g" "$STACK_ROOT/templates/orca-serve.service" \
  > /etc/systemd/system/orca-serve.service

systemctl daemon-reload
systemctl enable --now orca-serve
systemctl --no-pager --full status orca-serve | head -20
echo "Advertised pairing address: $TS_IP:6768"
echo "Pair from client over Tailscale; AppImage has no bind-host (UFW protects public)."
