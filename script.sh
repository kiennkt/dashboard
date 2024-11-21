#!/bin/bash

# Check access logg
check_access_log(){
    echo "========== Check logs related about ssh and telnet =========="
    if [ -f /var/log/auth.log ]; then
        echo "Checking logs SSH/Telnet in /var/log/auth.log"
        sudo grep -iE 'ssh|telnet' /var/log/auth.log 2>/dev/null || echo "Not found logs in /var/log/auth.log."
    elif [ -f /var/log/secure ]; then
        echo "Checking logs SSH/Telnet in /var/log/secure"
        sudo grep -iE 'ssh|telnet' /var/log/secure 2>/dev/null || echo "Not found logs in /var/log/secure"
    else
        echo "Not found log directory in system !!!"
    fi
    echo "========== Check access logs completed =========="
}

# Get information system
get_infor_system(){
    echo "========== Get information system =========="
    echo "Host name: $(hostname)"
    echo "Kernel: $(uname -a)"
    ram_used=$(free -h | awk '/Mem/ {print $3}')
    ram_total=$(free -h | awk '/Mem/ {print $2}')
    cpu_used=$(top -bn1 | grep "%Cpu" | awk '{print $2 + $4 + $6}')
    cpu_cores=$(nproc)
    echo "RAM using: ${ram_used} / RAM total: ${ram_total}"
    echo "CPU using: ${cpu_used}% / CPU total: ${cpu_cores} cores"
    echo "=========== Get information system completed =========="
}

# List process running in VM
list_processes(){
    echo "========== List processes in VM =========="
    ps aux --sort=-%mem
    echo
    echo "========== List process completed =========="
}

# Check filewall còniguration
check_filewall_config(){
    echo "========== Check filewall configuration =========="
    # Check ufw installed or not, if installed->running or not -> if running -> show status
    if command -v ufw > /dev/null; then
        echo "ufw service is installed"
        if systemctl is-active --quiet ufw; then
            echo "ufw service is running"
            sudo ufw status verbose
        else
            echo "ufw service is not running"
        fi
    else 
        echo "ufw is not installed"
    fi
    echo
   
    # Check iptable installed or not if running -> show rules
    if command -v iptables > /dev/null; then
        echo "iptables services is running"
        echo "=== Show iptables rules ==="
        sudo iptables -L -n -v
    else 
        echo "iptables service is not running"
    fi
    echo

    # Check firewalld installed or not, if installed->running or not -> if running -> show config
    if command -v firewall-cmd >/dev/null; then
        echo "firewalld is installed"
        # Kiểm tra trạng thái của firewalld
        if systemctl is-active --quiet firewalld; then
            echo "firewalld service is running"
            echo "firewalld status:"
            sudo firewall-cmd --state
            echo "firewalld rules:"
            sudo firewall-cmd --list-all
        else
            echo "firewalld service is not running"
        fi
    else
        echo "firewalld is not installed"
    fi
    echo
    echo "========== Firewall configuration check completed ==========" 

}

# List exist account
list_exist_account(){
    echo "========== List exist account =========="
    
    echo "=== List account name ==="
    cat /etc/passwd | cut -d: -f1
    #grep "/bin/bash" /etc/passwd | cut -d: -f1
    echo

    echo "=== List detail account ==="
    cat /etc/passwd
    echo
    echo "==== List exist account completed ====="
}

# List exist files in /tmp, /var/tmp, /usr/tmp, /usr/bin directỏy
list_exist_files_in_directories(){
    echo "========== List exist files in /tmp, /var/tmp, /usr/tmp, /usr/bin directory =========="
    for dir in /tmp /var/tmp /usr/tmp /usr/bin; do
        if [ -d "$dir" ]; then
            echo "Exist files in $dir is:"
            ls -lh "$dir"
        else 
            echo "Non-exist file in $dir"
        echo
        fi
    done
    echo "========== List exist files completed =========="
}

## Call func
list_exist_files_in_directories
echo ""
list_exist_account
echo ""
check_filewall_config
echo ""
list_processes
echo ""
get_infor_system
echo ""
check_access_log
echo ""