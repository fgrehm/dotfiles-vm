#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../.env"

usage() {
  echo "Usage: $0 <command> [name]"
  echo ""
  echo "Commands:"
  echo "  create <name>   Save current VM state as a named snapshot"
  echo "  revert <name>   Restore VM to a named snapshot"
  echo "  list            Show all snapshots"
  echo "  delete <name>   Delete a snapshot"
  echo ""
  echo "Examples:"
  echo "  $0 create fresh-kde"
  echo "  $0 revert fresh-kde"
  echo "  $0 list"
  exit 1
}

[[ $# -lt 1 ]] && usage

command="$1"
name="${2:-}"

case "$command" in
  create)
    [[ -z "$name" ]] && { echo "ERROR: snapshot name required."; usage; }
    # --disk-only creates an external snapshot, which works with UEFI (pflash)
    # firmware without requiring QCOW2 NVRAM. The VM must be shut off first.
    if virsh domstate "$VM_NAME" 2>/dev/null | grep -q "running"; then
      echo "ERROR: VM must be shut off before snapshotting."
      echo "  virsh shutdown $VM_NAME"
      exit 1
    fi
    if virsh snapshot-info "$VM_NAME" --snapshotname "$name" &>/dev/null; then
      echo "Snapshot '$name' already exists, replacing..."
      virsh snapshot-delete "$VM_NAME" --snapshotname "$name" > /dev/null
    fi
    echo "Creating snapshot '$name'..."
    virsh snapshot-create-as "$VM_NAME" --name "$name" --disk-only --atomic
    echo "Done. Revert anytime with: $0 revert $name"
    ;;
  revert)
    [[ -z "$name" ]] && { echo "ERROR: snapshot name required."; usage; }
    echo "Reverting to snapshot '$name'..."
    virsh snapshot-revert "$VM_NAME" "$name"
    echo "Done. VM is back to '$name' state."
    ;;
  list)
    virsh snapshot-list "$VM_NAME"
    ;;
  delete)
    [[ -z "$name" ]] && { echo "ERROR: snapshot name required."; usage; }
    echo "Deleting snapshot '$name'..."
    virsh snapshot-delete "$VM_NAME" --snapshotname "$name"
    echo "Done."
    ;;
  *)
    echo "ERROR: unknown command '$command'"
    usage
    ;;
esac
