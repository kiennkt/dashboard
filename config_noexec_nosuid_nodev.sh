#!/usr/bin/env bash


echo "tmpfs /tmp tmpfs nosuid,nodev,noexec 0 0" | sudo tee -a /etc/fstab
sudo mount /tmp

echo "tmpfs /dev/shm tmpfs nosuid,nodev,noexec 0 0" | sudo tee -a /etc/fstab 
sudo mount -o remount /dev/shm

# echo "/dev/mapper/ubuntu--vg-ubuntu--lv /home/ ext4 nodev 0 0" | sudo tee -a /etc/fstab 
# sudo mount /home

# Verify `Defaults use_pty` is set. If not -> add to /etc/sudoers:

if sudo grep -q "^Defaults\s*use_pty" /etc/sudoers; then
    echo "Defaults use_pty is set"
else
    sudo sh -c 'echo "Defaults use_pty" | EDITOR="tee -a" visudo'
fi


sudo grep -q "account\s*requisite\s*pam_deny.so" /etc/pam.d/common-account || echo "account requisite pam_deny.so" | sudo tee -a /etc/pam.d/common-account

sudo grep -q "account\s*required\s*pam_faillock.so" /etc/pam.d/common-account || echo "account required pam_faillock.so" | sudo tee -a /etc/pam.d/common-account

# sudo echo "auth required pam_faillock.so onerr=fail audit silent deny=5 unlock_time=900" >> /etc/pam.d/common-auth

sudo grep -q "/^auth\s*required\s*pam_faillock.so" /etc/pam.d/common-auth && sudo sed -i "/^auth\s*required\s*pam_faillock.so/c\auth required pam_faillock.so onerr=fail audit silent deny=5 unlock_time=900" /etc/pam.d/common-auth || sudo echo "auth required pam_faillock.so onerr=fail audit silent deny=5 unlock_time=900" | sudo tee -a /etc/pam.d/common-auth

