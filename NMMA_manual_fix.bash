#!/usr/bin/env bash

# 1. Check configuration of filesystem và USB Storage

################## Begin Remedation #######################
# If the module is available in running kernel

## Create a file ending in .conf with install [modules] /bin/false in the /etc/modprobe.d/ directory
## Create a file ending in .conf with blacklist [modules] in the /etc/modprobe.d/ directory
## Unload module from kernel

# If available in ANY installed kernel:
## Create a file ending in .conf with blacklist [modules] in the /etc/modprobe.d/ directory

# If the kernel module is not available on the system or pre-compiled into the kernel:
## No remediation is necessary 

# [modules]: cramfs,freevxfs, jffs2, hfs, hfsplus, squashfs, udf
################# End Remedation ##########################

# Create a file ending in .conf with install [modules] /bin/false in the /etc/modprobe.d/ directory
module_loadable_fix() {
    local module_name="$1"
    local module_conf_name="$2"
    local loadable

    loadable="$(modprobe -n -v "$module_name")"
    [ "$(wc -l <<< "$loadable")" -gt "1" ] && loadable="$(grep -P -- "(^\h*install|\b$module_name)\b" <<< "$loadable")"
    if ! grep -Pq -- '^\h*install \/bin\/(true|false)' <<< "$loadable"; then
        echo -e "\n - setting module: \"$module_name\" to be not loadable"
        echo -e "install $module_name /bin/false" >> /etc/modprobe.d/"$module_conf_name".conf
    fi
}

# Unload module from kernel
module_loaded_fix() {
    local module_name="$1"

    if lsmod | grep "$module_name" > /dev/null 2>&1; then
        echo -e "\n - unloading module \"$module_name\""
        modprobe -r "$module_name"
    fi
}

# Create a file ending in .conf with blacklist [modules] in the /etc/modprobe.d/ directory
module_deny_fix() {
    local module_name="$1"
    local module_conf_name="$2"

    if ! modprobe --showconfig | grep -Pq -- "^\h*blacklist\h+$module_conf_name\b"; then
        echo -e "\n - deny listing \"$module_name\""
        echo -e "blacklist $module_name" >> /etc/modprobe.d/"$module_conf_name".conf
    fi
}

# Function to handle module
handle_module() {
    local module_name="$1"
    local module_type="fs"

    local module_path="/lib/modules/**/kernel/$module_type"
    local module_conf_name="$(tr '-' '_' <<< "$module_name")"
    local module_dir_name="$(tr '-' '/' <<< "$module_name")"

    for module_dir in $module_path; do
        if [ -d "$module_dir/$module_dir_name" ] && [ -n "$(ls -A "$module_dir/$module_dir_name")" ]; then
            echo -e "\n - module: \"$module_name\" exists in \"$module_dir\"\n - checking if disabled..."
            module_deny_fix "$module_name" "$module_conf_name"
            if [ "$module_dir" = "/lib/modules/$(uname -r)/kernel/$module_type" ]; then
                module_loadable_fix "$module_name" "$module_conf_name"
                module_loaded_fix "$module_name"
            fi
        else
            echo -e "\n - module: \"$module_name\" doesn't exist in \"$module_dir\"\n"
        fi
    done
    echo -e "\n - remediation of module: \"$module_name\" complete\n"
}

# Call handle_module Func
handle_module "cramfs"
handle_module "freevxfs"
handle_module "jffs2"
handle_module "hfs"
handle_module "hfsplus"
handle_module "udf"
handle_module "usb-storage"

# 2. Check configuration of /tmp
echo "tmpfs /tmp tmpfs nosuid,nodev,noexec 0 0" | sudo tee -a /etc/fstab
sudo mount /tmp

# 3. Check configuration of /dev/shm
echo "tmpfs /dev/shm tmpfs nosuid,nodev,noexec 0 0" | sudo tee -a /etc/fstab 
sudo mount -o remount /dev/shm

# 4. Check configuration of /home

# Mount /home with bind mount
if ! grep -q "/home" /etc/fstab; then
    echo "/home /home none bind,nodev 0 0" >> /etc/fstab
    echo "Added /home to /etc/fstab"
else
    echo "/home already exists in /etc/fstab"
fi
# Apply the mounts
mount -a

systemctl daemon-reload

# 5. Check permission boot loader
sudo chmod 600 /boot/grub/grub.cfg
sudo chown root:root /boot/grub/grub.cfg

# 6. Check configuration of coredump

# Config /etc/security/limits.conf or a /etc/security/limits.d/* file
# echo "* hard core 0" | sudo tee -a /etc/security/limits.conf
sudo grep -qE "^\* hard core 0" "/etc/security/limits.conf" || echo "* hard core 0" | sudo tee -a "/etc/security/limits.conf"

# Set params in  /etc/sysctl.conf or a file in /etc/sysctl.d/ ending in .conf
sudo grep -qE "^fs\.suid_dumpable\s*=\s*0" "/etc/sysctl.conf" || echo "fs.suid_dumpable = 0" | sudo tee -a "/etc/sysctl.conf"
sudo sysctl -w fs.suid_dumpable=0   #or sysctl -p

# If systemd-coredump installed -> modify/add to /etc/systemd/coredump.conf:
if command -v systemd-coredump &>/dev/null; then
    sudo grep -q "^Storage=" /etc/systemd/coredump.conf && sudo sed -i "s/^Storage=.*/Storage=none/" /etc/systemd/coredump.conf || echo "Storage=none" | sudo tee -a /etc/systemd/coredump.conf
    sudo grep -q "^ProcessSizeMax=" /etc/systemd/coredump.conf && sudo sed -i "s/^ProcessSizeMax=.*/ProcessSizeMax=0/" /etc/systemd/coredump.conf || echo "ProcessSizeMax=0" | sudo tee -a /etc/systemd/coredump.conf
    sudo systemctl daemon-reload
fi

# 7. Check status of rsync server
sudo systemctl stop rsync.service
sudo systemctl mask rsync.service

# 8. Check configuration of IP forwarding
sudo grep -q "^net.ipv4.ip_forward\s*=" /etc/sysctl.conf && sudo sed -i "s/^net.ipv4.ip_forward\s*=.*/net.ipv4.ip_forward=0/" /etc/sysctl.conf || echo "net.ipv4.ip_forward=0" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf

# 9. Check configuration of ICMP redirects

sudo grep -q "^net.ipv4.conf.all.accept_redirects\s*=\s*0" /etc/sysctl.conf || sudo echo "net.ipv4.conf.all.accept_redirects = 0" >> /etc/sysctl.conf
sudo grep -q "^net.ipv4.conf.default.accept_redirects\s*=\s*0" /etc/sysctl.conf || sudo echo "net.ipv4.conf.default.accept_redirects = 0" >> /etc/sysctl.conf

sudo sysctl -p /etc/sysctl.conf

# 10. Check configuration of secure ICMP redirects
sudo grep -q "^net.ipv4.conf.all.secure_redirects\s*=\s*0" /etc/sysctl.conf || sudo echo "net.ipv4.conf.all.secure_redirects = 0" >> /etc/sysctl.conf
sudo grep -q "^net.ipv4.conf.default.secure_redirects\s*=\s*0" /etc/sysctl.conf || sudo echo "net.ipv4.conf.default.secure_redirects = 0" >> /etc/sysctl.conf

sudo sysctl -p /etc/sysctl.conf

# 11. Check configuration of journald compress large log files
echo "Compress=yes" >> /etc/systemd/journald.conf
sudo systemctl restart systemd-journald

# 12. Check configuration of journald write logfiles to persistent disk
echo "Storage=persistent" >> /etc/systemd/journald.conf 
sudo systemctl restart systemd-journald

# 13. Kiểm tra pty cho sudo commands
if sudo grep -q "^Defaults\s*use_pty" /etc/sudoers; then
    echo "Defaults use_pty is set"
else
    sudo sh -c 'echo "Defaults use_pty" | EDITOR="tee -a" visudo'
fi

# 14. Check configuration of sudo log file
echo "Defaults logfile=/var/log/sudo.log" >> /etc/sudoers

# 15. Kiểm tra phần quyền /etc/ssh/sshd_config
sudo chmod 600 /etc/ssh/sshd_config

# 16. Check configuration of SSH X11 forwarding
sudo sed -i "/^#*X11Forwarding/c\X11Forwarding no" /etc/ssh/sshd_config

# 17. Check configuration of SSH Idle Timeout Interval
sudo sed -i "/^#*ClientAliveInterval/c\ClientAliveInterval 300" /etc/ssh/sshd_config
sudo sed -i "/^#*ClientAliveCountMax/c\ClientAliveCountMax 3" /etc/ssh/sshd_config
sudo systemctl restart ssh
# 18. Check configuration of chính sách mật khẩu

# Setup to /etc/security/pwquality.conf
sudo sed -i "/^#*\s*minlen/c\minlen = 14" /etc/security/pwquality.conf
sudo sed -i "/^#*\s*minclass/c\minclass = 4" /etc/security/pwquality.conf

# Or setup to /etc/login.defs
sudo sed -i "/^#*PASS_MIN_LEN/c\PASS_MIN_LEN 14" /etc/login.defs

# 19. Check configuration of account lockout

sudo grep -q "account\s*requisite\s*pam_deny.so" /etc/pam.d/common-account || echo "account requisite pam_deny.so" | sudo tee -a /etc/pam.d/common-account
sudo grep -q "account\s*required\s*pam_faillock.so" /etc/pam.d/common-account || echo "account required pam_faillock.so" | sudo tee -a /etc/pam.d/common-account
sudo grep -q "^auth\s*required\s*pam_faillock.so" /etc/pam.d/common-auth && sudo sed -i "/^auth\s*required\s*pam_faillock.so/c\auth required pam_faillock.so onerr=fail audit silent deny=5 unlock_time=900" /etc/pam.d/common-auth || sudo echo "auth required pam_faillock.so onerr=fail audit silent deny=5 unlock_time=900" | sudo tee -a /etc/pam.d/common-auth

# 20. Check configuration of minimum day passwd
sudo sed -i "/^#*PASS_MIN_DAYS/c\PASS_MIN_DAYS   1" /etc/login.defs

# 21. Check configuration of maximum day passwd
sudo sed -i "/^#*PASS_MAX_DAYS/c\PASS_MAX_DAYS   365" /etc/login.defs
