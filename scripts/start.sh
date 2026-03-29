#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../.env"

state=$(virsh domstate "$VM_NAME" 2>/dev/null || true)

if [[ "$state" == "running" ]]; then
  echo "VM '$VM_NAME' is already running."
  exit 0
fi

echo "Starting '$VM_NAME'..."
virsh start "$VM_NAME"
virt-viewer --attach --cursor=local --wait --reconnect "$VM_NAME" > /dev/null 2>&1 &
disown
