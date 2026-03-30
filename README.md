# dotfiles-vm

Spin up a disposable Debian 13 (Trixie) VM with KDE Plasma to test dotfiles. Uses QEMU/KVM + libvirt with a preseed for fully unattended install and 9p passthrough to mount your dotfiles directly into the guest.

Runs entirely in userland (`qemu:///session`) with [passt](https://passt.top/) for networking. No root, no bridge setup, no permission headaches.

## Requirements

Debian 13 host with:

```bash
sudo apt install qemu-kvm libvirt-daemon-system \
  libvirt-clients virt-manager virt-viewer passt
```

If you don't want libvirtd running all the time, enable socket activation instead:

```bash
sudo systemctl disable libvirtd
sudo systemctl enable libvirtd.socket
```

## Setup

1. `cp .env.example .env`
2. Edit `.env` -- set `DOTFILES_PATH`, username, password, VM resources. Optionally set `ISO_PATH` to a local Debian ISO to skip the network download.
3. `make create` -- wait ~15 minutes

## Usage

```bash
make create                    # build the VM from scratch
make start                     # start VM and open display
make stop                      # gracefully shut down
make ssh                       # SSH into the running VM
make snapshot NAME=fresh-kde   # save VM state (VM must be stopped)
make revert NAME=fresh-kde     # restore VM state
make list                      # show all snapshots
make destroy                   # delete VM and disk
make help                      # show all targets
```

Your dotfiles are automatically mounted at `/mnt/dotfiles` inside the guest on every boot (configured via preseed). Just symlink or deploy from there as your dotfiles setup script expects.

## How it works

The `virt-install` command fetches the Debian installer (from a local ISO if `ISO_PATH` is set, otherwise over the network), injects `preseed.cfg` to automate the install (KDE Plasma + SSH + utilities), and sets up a 9p virtio filesystem share so your host dotfiles directory is live-mounted inside the guest. Snapshots via `virsh` let you test, break things, and revert in seconds.

The VM uses `qemu:///session` (user-level libvirt) so QEMU runs as your user and can access files under your home directory without any special permissions. Networking uses [passt](https://passt.top/) with port forwarding for SSH (`localhost:2222` by default, configurable via `VM_SSH_PORT` in `.env`).

## Troubleshooting

**`make ssh` hangs or times out:**
- Check that the VM is running: `virsh domstate $VM_NAME`
- Verify SSH is reachable: `ssh -p 2222 localhost` (or whatever `VM_SSH_PORT` is set to)
- Check that `sshd` is running inside the VM: open the SPICE display with `make start` and run `systemctl status ssh`
- Verify passt is working: `virsh dumpxml $VM_NAME | grep passt`

**VM won't start after editing:**
- Don't manually edit the XML. Destroy and recreate: `make destroy && make create`

**9p mount failing in the VM:**
- Verify the host path exists and is readable: `ls -la $DOTFILES_PATH`
- Check the kernel modules are loaded: `lsmod | grep 9p`

## License

MIT. See [LICENSE](LICENSE).
