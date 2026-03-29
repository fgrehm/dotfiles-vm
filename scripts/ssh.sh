#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../.env"

if ! virsh domstate "$VM_NAME" 2>/dev/null | grep -q "running"; then
  echo "ERROR: VM '$VM_NAME' is not running."
  echo "  Start it with: virsh start $VM_NAME"
  exit 1
fi

echo "Waiting for VM to get an IP address..."

for i in $(seq 1 30); do
  ip=$(virsh domifaddr "$VM_NAME" 2>/dev/null \
    | grep -oP '(\d{1,3}\.){3}\d{1,3}' \
    | head -1) || true
  [[ -n "$ip" ]] && break
  sleep 2
done

if [[ -z "${ip:-}" ]]; then
  echo "ERROR: Could not detect IP after 60 seconds."
  echo "  The VM may still be booting. Try again in a minute."
  exit 1
fi

echo "Connecting to $VM_USER@$ip ..."
exec ssh -o StrictHostKeyChecking=accept-new "$VM_USER@$ip"
