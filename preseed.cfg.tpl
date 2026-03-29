# preseed.cfg.tpl — template, do not edit directly
# create.sh generates preseed.cfg from this + .env values

# Locale & keyboard
d-i debian-installer/locale string en_US.UTF-8
d-i keyboard-configuration/xkb-keymap select us

# Network
d-i netcfg/choose_interface select auto
d-i netcfg/get_hostname string __VM_NAME__
d-i netcfg/get_domain string localdomain

# Mirror
d-i mirror/country string manual
d-i mirror/http/hostname string deb.debian.org
d-i mirror/http/directory string /debian
d-i mirror/http/proxy string

# Clock
d-i clock-setup/utc boolean true
d-i time/zone string UTC

# Partitioning — single ext4 root, no LVM
d-i partman-auto/method string regular
d-i partman-auto/choose_recipe select atomic
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

# User account
# root-login=false should auto-add user to sudo, but we make it explicit
d-i passwd/root-login boolean false
d-i passwd/user-fullname string __VM_USER__
d-i passwd/username string __VM_USER__
d-i passwd/user-password password __VM_PASS__
d-i passwd/user-password-again password __VM_PASS__
d-i passwd/user-default-groups string sudo audio video plugdev netdev

# Package selection
tasksel tasksel/first multiselect standard, kde-desktop, ssh-server

# Extra packages
d-i pkgsel/include string \
  git vim curl rsync spice-vdagent \
  bash-completion htop

# No popularity-contest
popularity-contest popularity-contest/participate boolean false

# Grub
d-i grub-installer/only_debian boolean true
d-i grub-installer/bootdev string default

# Post-install: mount dotfiles via 9p, load kernel modules at boot
d-i preseed/late_command string \
  in-target mkdir -p /mnt/dotfiles; \
  echo "mount_dotfiles /mnt/dotfiles 9p trans=virtio,nofail 0 0" >> /target/etc/fstab; \
  echo "9p" >> /target/etc/modules-load.d/9p.conf; \
  echo "9pnet" >> /target/etc/modules-load.d/9p.conf; \
  echo "9pnet_virtio" >> /target/etc/modules-load.d/9p.conf

# Reboot when done
d-i finish-install/reboot_in_progress note
