#!/usr/bin/env bash

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
