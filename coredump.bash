#!/bin/bash

# Config /etc/security/limits.conf or a /etc/security/limits.d/* file
# echo "* hard core 0" | sudo tee -a /etc/security/limits.conf
sudo grep -qE "^\* hard core 0" "/etc/security/limits.conf" || echo "* hard core 0" | sudo tee -a "/etc/security/limits.conf"

# Set params in  /etc/sysctl.conf or a file in /etc/sysctl.d/ ending in .conf
sudo grep -qE "^fs\.suid_dumpable\s*=\s*0" "/etc/sysctl.conf" || echo "fs.suid_dumpable = 0" | sudo tee -a "/etc/sysctl.conf"
sudo sysctl -w fs.suid_dumpable=0 # or sysctl -p

# If systemd-coredump installed:
if command -v systemd-coredump &>/dev/null; then
    sudo grep -q "^Storage=" /etc/systemd/coredump.conf && sudo sed -i "s/^Storage=.*/Storage=none/" /etc/systemd/coredump.conf || echo "Storage=none" | sudo tee -a /etc/systemd/coredump.conf
    sudo grep -q "^ProcessSizeMax=" /etc/systemd/coredump.conf && sudo sed -i "s/^ProcessSizeMax=.*/ProcessSizeMax=0/" /etc/systemd/coredump.conf || echo "ProcessSizeMax=0" | sudo tee -a /etc/systemd/coredump.conf
    sudo systemctl daemon-reload
fi


# # If systemd-coredump installed:
# if command -v systemd-coredump &>/dev/null; then
#     COREDUMP_CONF="/etc/systemd/coredump.conf"
#     [[ -f "$COREDUMP_CONF" ]] || touch "$COREDUMP_CONF"
#     sed -i "s/^Storage=.*/Storage=none/" "$COREDUMP_CONF" || echo "Storage=none" >> "$COREDUMP_CONF"
#     sed -i "s/^ProcessSizeMax=.*/ProcessSizeMax=0/" "$COREDUMP_CONF" || echo "ProcessSizeMax=0" >> "$COREDUMP_CONF"
#     systemctl daemon-reload
# fi