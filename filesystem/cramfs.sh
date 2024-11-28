#!/usr/bin/env bash
{
	l_mname_cramfs="cramfs" # set module name
	l_mtype="fs" # set module type
	l_mpath="/lib/modules/**/kernel/$l_mtype"
	l_mpname_cramfs="$(tr '-' '_' <<< "$l_mname_cramfs")"
	l_mndir_cramfs="$(tr '-' '/' <<< "$l_mname_cramfs")"
	module_loadable_fix()
	{
		# If the module is currently loadable, add "install {MODULE_NAME} /bin/false" to a file in "/etc/modprobe.d"
		l_loadable_cramfs="$(modprobe -n -v "$l_mname_cramfs")"
		[ "$(wc -l <<< "$l_loadable_cramfs")" -gt "1" ] && l_loadable_cramfs="$(grep -P -- "(^\h*install|\b$l_mname_cramfs)\b" <<< "$l_loadable_cramfs")"
		if ! grep -Pq -- '^\h*install \/bin\/(true|false)' <<< "$l_loadable_cramfs"; then
		    echo -e "\n - setting module: \"$l_mname_cramfs\" to be not loadable"
		    echo -e "install $l_mname_cramfs /bin/false" >> /etc/modprobe.d/"$l_mpname_cramfs".conf
		fi
	}
	module_loaded_fix()
	{
		# If the module is currently loaded, unload the module
		if lsmod | grep "$l_mname_cramfs" > /dev/null 2>&1; then
		    echo -e "\n - unloading module \"$l_mname_cramfs\""
		    modprobe -r "$l_mname_cramfs"
		fi
	}
	module_deny_fix()
	{
		# If the module isn't deny listed, denylist the module
		if ! modprobe --showconfig | grep -Pq -- "^\h*blacklist\h+$l_mpname_cramfs\b"; then
		    echo -e "\n - deny listing \"$l_mname_cramfs\""
		    echo -e "blacklist $l_mname_cramfs" >> /etc/modprobe.d/"$l_mpname_cramfs".conf
		fi
	}
# Check if the module exists on the system
	for l_mdir in $l_mpath; do
		if [ -d "$l_mdir/$l_mndir_cramfs" ] && [ -n "$(ls -A $l_mdir/$l_mndir_cramfs)" ]; then
	        echo -e "\n - module: \"$l_mname_cramfs\" exists in \"$l_mdir\"\n - checking if disabled..."
	        module_deny_fix
	        if [ "$l_mdir" = "/lib/modules/$(uname -r)/kernel/$l_mtype" ]; then
	        	module_loadable_fix
	        	module_loaded_fix
	        fi
	    else
	        echo -e "\n - module: \"$l_mname_cramfs\" doesn't exist in \"$l_mdir\"\n"
		fi
	done
	echo -e "\n - remediation of module: \"$l_mname_cramfs\" complete\n"
}