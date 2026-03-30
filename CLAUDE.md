# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project does

Spins up a disposable Debian 13 (Trixie) VM with KDE Plasma for testing dotfiles. Uses QEMU/KVM + libvirt with a preseed for fully unattended install, and 9p virtio passthrough to mount the host dotfiles directory live inside the guest at `/mnt/dotfiles`.

## Usage

See README.md for setup and usage instructions.

## Common commands

```bash
make create                    # build VM from scratch
make start                     # start VM and open display
make stop                      # gracefully shut down
make ssh                       # SSH into running VM
make snapshot NAME=fresh-kde   # save VM state (VM must be stopped)
make revert NAME=fresh-kde     # restore VM state
make list                      # list snapshots
make destroy                   # delete VM and disk
```

`snapshot.sh` also supports `delete <name>` directly: `./scripts/snapshot.sh delete <name>`.

## Architecture

- `.env` (from `.env.example`) -- runtime config: VM name, credentials, resource sizes, optional local ISO path
- `preseed.cfg.tpl` -- Debian installer automation template; `create.sh` substitutes `__VM_NAME__`, `__VM_USER__`, `__VM_PASS__` with values from `.env` to produce `preseed.cfg` (generated, not committed)
- `scripts/create.sh` -- generates preseed, validates inputs, calls `virt-install` with UEFI + SPICE (QXL) + 9p filesystem share; uses `--noautoconsole` so it returns when the install finishes
- `scripts/start.sh` -- starts the VM and opens virt-viewer (detached) with `--wait --reconnect`
- `scripts/stop.sh` -- graceful shutdown via `virsh shutdown`
- `scripts/destroy.sh` -- prompts for confirmation, stops and undefines VM with `--remove-all-storage --nvram`
- `scripts/snapshot.sh` -- wraps `virsh snapshot-{create-as,revert,list,delete}`; uses `--disk-only` external snapshots for UEFI compatibility; overwrites existing snapshots with the same name; requires VM to be shut off
- `scripts/ssh.sh` -- polls `virsh domifaddr` for the VM IP then SSHes in

The 9p mount is wired up in the preseed `late_command`: it appends the fstab entry and loads the `9p`, `9pnet`, `9pnet_virtio` kernel modules at boot.

## Key constraints

- All scripts use `qemu:///session` (user-level libvirt, the default). QEMU runs as the current user, so no special permissions are needed for files under `$HOME`.
- Networking uses passt with port forwarding. SSH is via `localhost:$VM_SSH_PORT` (default 2222), not via bridge IP.
- VM disk is stored at `~/.local/share/libvirt/images/` (on `/home`, not `/`).
- `preseed.cfg` is generated at `make create` time and should not be committed (contains plaintext password from `.env`).
- `.env` contains credentials -- never commit it.
- Snapshots use `--disk-only` (external) because UEFI pflash firmware does not support internal snapshots without QCOW2 NVRAM. The VM must be shut off before snapshotting.
