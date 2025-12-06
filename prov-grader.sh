#!/bin/bash

# Make sure the script exits on any error
set -e

# Disabling cgroup v2
sed -i 's|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX="systemd.unified_cgroup_hierarchy=false systemd.legacy_systemd_cgroup_controller=false"|' /etc/default/grub

update-grub

echo "Applying isolate recommendations..."
cat <<'EOF' > /etc/rc.local
#!/bin/bash

echo 0 > /proc/sys/kernel/randomize_va_space
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo 0 > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag
EOF

chmod +x /etc/rc.local

echo "Rebooting system to apply changes..."
reboot
