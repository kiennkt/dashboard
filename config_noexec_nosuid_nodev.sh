#!/usr/bin/env bash


echo "tmpfs /tmp tmpfs nosuid,nodev,noexec 0 0" | sudo tee -a /etc/fstab
sudo mount /tmp

echo "tmpfs /dev/shm tmpfs nosuid,nodev,noexec 0 0" | sudo tee -a /etc/fstab 
sudo mount -o remount /dev/shm

# echo "/dev/mapper/ubuntu--vg-ubuntu--lv /home/ ext4 nodev 0 0" | sudo tee -a /etc/fstab 
# sudo mount /home