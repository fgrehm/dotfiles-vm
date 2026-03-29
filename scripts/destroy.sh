#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../.env"

if ! virsh dominfo "$VM_NAME" &>/dev/null; then
  echo "VM '$VM_NAME' does not exist. Nothing to destroy."
  exit 0
fi

echo "This will permanently delete VM '$VM_NAME' and its disk."
read -rp "Are you sure? [y/N] " confirm
if [[ "$confirm" != [yY] ]]; then
  echo "Aborted."
  exit 0
fi

# shut down if running
if virsh domstate "$VM_NAME" 2>/dev/null | grep -q "running"; then
  echo "Shutting down '$VM_NAME'..."
  virsh destroy "$VM_NAME" 2>/dev/null || true
fi

echo "Removing VM and storage..."
virsh undefine "$VM_NAME" --remove-all-storage --nvram --snapshots-metadata


echo "Done. VM '$VM_NAME' has been deleted."
