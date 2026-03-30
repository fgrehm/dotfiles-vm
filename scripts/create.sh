#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SCRIPT_DIR/.."

source "$REPO_DIR/.env"

TEMPLATE="$REPO_DIR/preseed.cfg.tpl"
PRESEED="$REPO_DIR/preseed.cfg"
SSH_PORT="${VM_SSH_PORT:-2222}"

if virsh dominfo "$VM_NAME" &>/dev/null; then
  echo "ERROR: VM '$VM_NAME' already exists."
  echo "  Run 'make destroy' first, or change VM_NAME in .env"
  exit 1
fi

if ! command -v passt &>/dev/null; then
  echo "ERROR: passt is not installed (needed for VM networking)."
  echo "  Install it with: sudo apt install passt"
  exit 1
fi

if [[ ! -d "$DOTFILES_PATH" ]]; then
  echo "ERROR: Dotfiles directory not found: $DOTFILES_PATH"
  echo "  Update DOTFILES_PATH in .env"
  exit 1
fi

if [[ ! -f "$TEMPLATE" ]]; then
  echo "ERROR: preseed.cfg.tpl not found at: $TEMPLATE"
  exit 1
fi

# generate preseed.cfg from template + .env values
echo "Generating preseed.cfg from template..."
sed \
  -e "s|__VM_NAME__|$VM_NAME|g" \
  -e "s|__VM_USER__|$VM_USER|g" \
  -e "s|__VM_PASS__|$VM_PASS|g" \
  "$TEMPLATE" > "$PRESEED"

# determine install source
LOCATION="${ISO_PATH:-https://deb.debian.org/debian/dists/trixie/main/installer-amd64/}"

if [[ -n "${ISO_PATH:-}" ]]; then
  if [[ ! -f "$ISO_PATH" ]]; then
    echo "ERROR: ISO not found: $ISO_PATH"
    echo "  Update ISO_PATH in .env or comment it out for network install."
    exit 1
  fi
  echo "Creating VM '$VM_NAME'..."
  echo "  Install source: $ISO_PATH (local ISO)"
else
  echo "Creating VM '$VM_NAME'..."
  echo "  Install source: network (deb.debian.org)"
fi
echo "  RAM: ${VM_RAM}MB | CPUs: $VM_CPUS | Disk: ${VM_DISK}GB"
echo "  Dotfiles mount: $DOTFILES_PATH -> /mnt/dotfiles (inside guest)"
echo "  This will take 10-15 minutes."
echo ""

virt-install \
  --name "$VM_NAME" \
  --ram "$VM_RAM" \
  --vcpus "$VM_CPUS" \
  --disk "size=$VM_DISK" \
  --location "$LOCATION" \
  --osinfo debian13 \
  --graphics spice,listen=none \
  --video qxl \
  --channel spicevmc \
  --channel unix,target_type=virtio,name=org.qemu.guest_agent.0 \
  --input type=tablet,bus=usb \
  --xml './devices/graphics[@type="spice"]/mouse/@mode=client' \
  --network "passt,portForward=127.0.0.1:$SSH_PORT:22" \
  --boot uefi \
  --noautoconsole \
  --initrd-inject "$PRESEED" \
  --extra-args "auto=true priority=critical preseed/file=/preseed.cfg" \
  --filesystem "source=$DOTFILES_PATH,target=mount_dotfiles,mode=mapped"

echo ""
echo "Install started. Opening display..."
virt-viewer --attach --cursor=local --wait --reconnect "$VM_NAME" >/dev/null 2>&1 &
disown
echo "  The VM will reboot when the install finishes."
echo "  SSH in:            make ssh"
echo "  Take a snapshot:   make snapshot NAME=fresh-kde"
