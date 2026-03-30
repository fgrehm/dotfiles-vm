#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../.env"

SSH_PORT="${VM_SSH_PORT:-2222}"

if ! virsh domstate "$VM_NAME" 2>/dev/null | grep -q "running"; then
  echo "ERROR: VM '$VM_NAME' is not running."
  echo "  Start it with: make start"
  exit 1
fi

echo "Waiting for SSH on localhost:$SSH_PORT ..."

for i in $(seq 1 30); do
  if nc -z localhost "$SSH_PORT" 2>/dev/null; then
    break
  fi
  sleep 2
done

exec ssh -o StrictHostKeyChecking=accept-new -p "$SSH_PORT" "$VM_USER@localhost"
