#!/bin/bash

# Make sure the script exits on any error
set -e

# Disabling cgroup v2 by appending to GRUB_CMDLINE_LINUX if not already present
if ! grep -q "systemd.unified_cgroup_hierarchy=false" /etc/default/grub; then
  sed -i 's/GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="\1 systemd.unified_cgroup_hierarchy=false"/' /etc/default/grub
fi
if ! grep -q "systemd.legacy_systemd_cgroup_controller=false" /etc/default/grub; then
  sed -i 's/GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="\1 systemd.legacy_systemd_cgroup_controller=false"/' /etc/default/grub
fi

update-grub

echo "Applying isolate recommendations..."

# Use sysctl for kernel parameters
cat <<EOF > /etc/sysctl.d/99-judgels.conf
kernel.randomize_va_space = 0
EOF

# Use systemd-tmpfiles to write to /sys on boot
cat <<EOF > /etc/tmpfiles.d/judgels-thp.conf
w /sys/kernel/mm/transparent_hugepage/enabled - - - - never
w /sys/kernel/mm/transparent_hugepage/defrag - - - - never
# Note: The 'khugepaged/defrag' path does not exist on all kernels, but writing to it should not cause an error.
w /sys/kernel/mm/transparent_hugepage/khugepaged/defrag - - - - 0
EOF

echo "Rebooting system to apply changes..."
reboot