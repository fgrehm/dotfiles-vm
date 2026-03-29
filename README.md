# dotfiles-vm

Spin up a disposable Debian 13 (Trixie) VM with KDE Plasma to test dotfiles. Uses QEMU/KVM + libvirt with a preseed for fully unattended install and 9p passthrough to mount your dotfiles directly into the guest.

## Requirements

Debian 13 host with:

```bash
sudo apt install qemu-kvm libvirt-daemon-system \
  libvirt-clients virt-manager virt-viewer bridge-utils
sudo usermod -aG libvirt $USER
# log out and back in
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

## License

MIT. See [LICENSE](LICENSE).
