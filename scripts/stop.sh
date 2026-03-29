#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../.env"

state=$(virsh domstate "$VM_NAME" 2>/dev/null || true)

if [[ "$state" != "running" ]]; then
  echo "VM '$VM_NAME' is not running (state: ${state:-unknown})."
  exit 0
fi

echo "Shutting down '$VM_NAME'..."
virsh shutdown "$VM_NAME"
echo "Done. Wait a moment for it to fully stop, then check with: virsh domstate $VM_NAME"
