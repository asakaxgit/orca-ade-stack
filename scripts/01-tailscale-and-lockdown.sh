#!/usr/bin/env bash
# Join Tailscale, then lock SSH + UFW to Tailscale-only.
# Usage: TAILSCALE_AUTH_KEY=<tskey-auth-REPLACE> ./01-tailscale-and-lockdown.sh
#    or: ./01-tailscale-and-lockdown.sh /root/bootstrap-secrets/tailscale.key
set -euo pipefail
STACK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PUBLIC_IFACE="${PUBLIC_IFACE:-eth0}"
KEY="${TAILSCALE_AUTH_KEY:-}"
if [[ -z "$KEY" && "${1:-}" != "" && -f "$1" ]]; then
  KEY="$(tr -d ' \n' < "$1")"
fi
if [[ -z "$KEY" ]]; then
  echo "Set TAILSCALE_AUTH_KEY or pass a key file path." >&2
  exit 1
fi

command -v tailscale >/dev/null || { curl -fsSL https://tailscale.com/install.sh | sh; }

tailscale up --auth-key="$KEY" --hostname="$(hostname -s)" --accept-routes=false
TS_IP="$(tailscale ip -4)"
echo "Tailscale IPv4: $TS_IP"

install -d /etc/systemd/system/ssh.socket.d
sed "s/TAILSCALE_IPV4/$TS_IP/g" "$STACK_ROOT/templates/ssh.socket.override.conf" \
  > /etc/systemd/system/ssh.socket.d/override.conf

if ! grep -q "^ListenAddress $TS_IP" /etc/ssh/sshd_config 2>/dev/null; then
  cat > /etc/ssh/sshd_config.d/98-listen-tailscale.conf <<CFG
ListenAddress $TS_IP
ListenAddress 127.0.0.1
CFG
fi
install -m 0644 "$STACK_ROOT/templates/sshd-hardening.conf" /etc/ssh/sshd_config.d/99-hardening.conf
sshd -t

systemctl daemon-reload
systemctl restart ssh.socket || systemctl restart ssh

ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 41641/udp comment 'Tailscale'
ufw allow in on tailscale0
ufw allow in on tailscale0 to any port 22 proto tcp comment 'SSH Tailscale only'
ufw deny in on "$PUBLIC_IFACE" to any port 6768 proto tcp comment 'orca-serve not on public'
ufw deny in on "$PUBLIC_IFACE" to any port 22 proto tcp comment 'SSH not on public'
ufw --force enable

echo "Lockdown done. Verify NEW ssh session: ssh root@$TS_IP before closing this one."
echo "LISH / provider console remains break-glass."
