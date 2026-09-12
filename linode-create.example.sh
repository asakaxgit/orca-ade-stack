#!/usr/bin/env bash
# Example: create next Orca ADE VPS on Linode with this cloud-init.
# Requires: LINODE_API_TOKEN, SSH_PUBKEY
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
LABEL="${LABEL:-orca-ade}"
REGION="${REGION:-jp-tyo-3}"
TYPE="${TYPE:-g6-standard-4}"
IMAGE="${IMAGE:-linode/ubuntu26.04}"
ROOT_PASS="$(openssl rand -base64 32)"

if [[ -z "${SSH_PUBKEY:-}" ]]; then
  echo "Set SSH_PUBKEY to your ed25519 public key line." >&2
  exit 1
fi
USERDATA="$(sed "s|REPLACE_WITH_YOUR_ED25519_PUBLIC_KEY|$SSH_PUBKEY|" "$ROOT/cloud-init.yaml")"

curl -sS -X POST \
  -H "Authorization: Bearer $LINODE_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg label "$LABEL" \
    --arg region "$REGION" \
    --arg type "$TYPE" \
    --arg image "$IMAGE" \
    --arg root_pass "$ROOT_PASS" \
    --arg userdata "$USERDATA" \
    '{label:$label,region:$region,type:$type,image:$image,root_pass:$root_pass,metadata:{user_data:($userdata|@base64)}}')" \
  https://api.linode.com/v4/linode/instances | jq '{id,label,status,ipv4,type}'

echo "After boot: copy this directory to the VPS as /root/orca-ade-stack"
echo "Then: TAILSCALE_AUTH_KEY=... /root/orca-ade-stack/scripts/01-tailscale-and-lockdown.sh"
