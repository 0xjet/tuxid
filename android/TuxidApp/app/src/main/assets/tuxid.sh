#!/usr/bin/env sh

: '
Author: Daniel Canencia García
Title: Linux Boxes Fingerprinting Script
Description:
This script collects a set of hardware, software, network, and OS signals
to generate a unique fingerprint for a Linux machine. It supports three
output modes (raw, private and both) and the number of signals taken
into account depends on the process available permissions (e.g. local/root
permissions)

Usage: sh tuxid.sh --output {output_mode} --hash-cmd {hash_command}
Output Modes (default to private):
- raw       : only signal outputs are shown
- private   : only resulting hashes are shown
- both      : both signal outputs and hashes are shown
Hash Command: sha1sum, sha256sum, md5sum, etc

Busybox Suite (not used by default):
    - e.g. sh tuxid.sh --busybox --busybox-path "/.../.../busybox"
- --busybox      : use the busybox suite to handle unix/linux commands
- --busybox-path : path to the busybox binary
'


#============================================================================
# check_root()
#
# Check script permissions
#============================================================================
check_root() {
    is_root=0

    # check if "id -u" output is numerical
    check_root1=$([ "$use_busybox" -eq 1 ] \
        && echo "$busybox_path id -u" 2>/dev/null \
        || echo "id -u" 2>/dev/null)
    if ! echo "$check_root1" | $busybox_path grep -qE '^[0-9]+$' 2>/dev/null; then
        check_root1=-1
    fi
    # if "id -u" is unavailable attempt to read /root directory
    ls /root/ >/dev/null 2<&1 && check_root2=true || check_root2=false
    if [ "$check_root1" -eq 0 ] || "$check_root2"; then
        is_root=1
    fi
}


#============================================================================
# set_busybox_env()
#
# Auxiliary function used to manage the busybox environment.
# It prefixes every busybox tool (defined in the $busybox_tools variable)
# present in the command passed as argument, with the busybox path
# defined by the user ($busybox_path)
#
# Arguments:
#   $1 - The command to execute under the busybox environment
#============================================================================
set_busybox_env() {
    cmd=""

    # Disable globbing
    set -f
    # shellcheck disable=SC2086
    set -- $command
    # Enable globbing
    set +f
    for var; do
        flag=0
        for tool in $busybox_tools; do
            if [ "$var" = "$tool" ]; then
                cmd="$cmd $busybox_path $var"
                flag=1
                break
            fi
        done

        if [ $flag -eq 0 ]; then
            cmd="$cmd $var"
        fi
    done

    echo "$cmd"
}

#============================================================================
# handle_cmd()
#
# Auxiliary function that handles command execution. If the
# --busybox argument is set, the command will be runned under
# the busybox environment, meaning that all GNU/UNIX tools specified
# by the busybox_tools variable
#
# Arguments:
#   $1 - The command to handle execution for
#============================================================================
handle_cmd() {
    command="$1"
    if [ "$use_busybox" -eq 1 ]; then
        command=$(set_busybox_env "$command")
    fi

    #echo "Command: '$command'\n"
    eval "$command" 2>/dev/null
}


#============================================================================
# collect_signal()
#
# Signal collection based on current process permissions.
# Arguments:
#   $1 - The command in charge of the signal collection process
#   $2 - Necessary permissions required to execute the command
#   (0: local user, 1: root)
#============================================================================
collect_signal() {
    signal_name="$1"
    command="$2"
    requires_root="$3"

    # Check permissions (abort if root privilege needed)
    if [ "$requires_root" -eq 1 ] && [ "$is_root" -eq 0 ]; then
        return
    fi

    # Execute command
    result=""
    result_hash=""
    result=$(handle_cmd "$command")
    #echo "Result: $command\n"

    # If the result is empty or invalid, use "N/A" as a fallback
    if [ -z "$result" ]; then
        result="N/A"
        result_hash="N/A"
        # Add N/A results to final hash
        # return
    # otherwise, compute the hash
    else
        result_hash=$(handle_cmd "printf \"%s\" \"$result\" | $hash_cmd")
        # Remove trailing '-'
        result_hash=${result_hash%% *}

        # Validate hash generated (maybe check syntax of hash using a regex expression)
        if [ ! "$result_hash" ] || [ -z "$result_hash" ]; then
            echo "Error: $hash_cmd failed"
            echo "Usage: --hash-cmd <sha1sum|sha256sum|md5sum|...>"
            echo "Error: $busybox_path $hash_cmd command is unknown"
            exit 1
        fi
    fi

    # Append data to JSON
    case "$output_mode" in
        raw)
            json_output="$json_output      \"$signal_name\": \"$result\",\n"
            ;;
        private)
            json_output="$json_output      \"$signal_name\": \"$result_hash\",\n"
            ;;
        both)
            json_output="$json_output      \"$signal_name\": {\n"
            json_output="$json_output           \"raw\": \"$result\",\n"
            json_output="$json_output           \"hash\": \"$result_hash\"\n"
            json_output="$json_output       },\n"
            ;;
    esac

    # Add valid results to fingerprint_data
    if [ -n "$result" ]; then
        fingerprint_data="$fingerprint_data$result"
        #if [ -z "$fingerprint_data ]; then
        #    fingerprint_data="$fingerprint_data,$result"
        #fi
    fi
}


#============================================================================
# get_fingerprint()
#
# Produces device ingerprint based on current process permissions
#============================================================================
get_fingerprint() {

    # check script permissions
    check_root

    # Initialize JSON
    json_output="{\n"

    #
    # Collect HARDWARE signals
    #
    json_output="$json_output  \"hardware_signals\": {\n"
    collect_signal "Device Model" "cat /sys/devices/virtual/dmi/id/product_name" 0
    collect_signal "Device Vendor" "cat /sys/devices/virtual/dmi/id/sys_vendor" 0
    collect_signal "Main Board Product UUID" "cat /sys/devices/virtual/dmi/id/product_uuid" 1
    collect_signal "Main Board Product Serial" "cat /sys/devices/virtual/dmi/id/board_serial" 1
    #
    # Test these three commands in order:
    #   - ls -A /dev/disk/by-uuid/
    #   - lsblk -o UUID
    #   - blkid
    #
    collect_signal "Storage Devices UUIDs" "(uuids=\$( ls -A /dev/disk/by-uuid/ 2>/dev/null ); \
        [ -z \"\$uuids\" ] && uuids=\$( lsblk -o UUID 2>/dev/null ); [ -z \"\$uuids\" ] && \
        uuids=\$( blkid 2>/dev/null | grep 'UUID=' | sed 's/.*UUID=\"\(.*\)\".*/\1/' ); \
        echo \"\$uuids\" | paste -sd '|')" 0
    collect_signal "Processor Model Name" "{ grep 'Processor' /proc/cpuinfo; grep 'model name' \
        /proc/cpuinfo; } | uniq | sed 's/^[^:]*:\s*//'" 0
    collect_signal "Total Memory (RAM)" "cat /proc/meminfo | grep '^MemTotal: ' | \
        cut -d':' -f2- | sed 's/ //g'" 0
    #
    # Total Disk Space:
    #   - df utility: use the bc tool to compute the sum of all partition sizes
    #   if available. If not, try to compute the sum directly.
    #   - /proc/partitions not used because it requires root permissions in some hosts.
    #
    #collect_signal "Total Disk Space" "( df 2>/dev/null | sed '1d' | sed 's/\ \ */ /g' | \
    #    cut -d' ' -f2 | paste -sd+ - | (bc || \$busybox_path bc) ) || \
    #    (sum=0; for size in \
    #        \$( ( df -k 2>/dev/null || df 2>/dev/null ) | sed '1d' | sed 's/\ \ */ /g'| \
    #              cut -d' ' -f2 ); \
    #    do sum=\$((sum+size)); done; echo \$sum)" 0
    collect_signal "Total Disk Space" "\
        ( df 2>/dev/null | sed '1d' | sed 's/\ \ */ /g' | cut -d' ' -f2 | paste -sd+ - | (bc || \$busybox_path bc)) || \
        ( df 2>/dev/null | tail -n +2 | sed 's/\ \ */ /g' | cut -d' ' -f2 | { awk '{s+=\$1} END {print s}' 2>/dev/null || \
            \$busybox_path awk '{s+=\$1} END {print s}' 2>/dev/null ; } ) || \
        (sum=0; for size in \
            \$( ( df -k 2>/dev/null || df 2>/dev/null ) | sed '1d' | sed 's/\ \ */ /g' | cut -d' ' -f2 ); \
        do sum=\$((sum+size)); done; echo \$sum)" 0

    #collect_signal "Total Disk Space" "df 2>/dev/null | sed '1d' | sed 's/\ \ */ /g' | \
    #    cut -d' ' -f2 | paste -sd+ - | (bc || $busybox_path bc)" 0
    #collect_signal "Total Disk Space" "sum=0; for size in \
    #    \$( { sed '1d' /proc/partitions 2>/dev/null | sed 's/\ \ */ /g' | cut -d' ' -f4; } || \
    #        { df 2>/dev/null | sed '1d' | sed 's/ \+/ /g' | cut -d' ' -f2; } ); \
    #    do sum=\$((sum+size)); done; echo \$sum" 0
    #collect_signal "Total Disk Space" "sum=0; for size in \
    #    \$( tail -n +2 /proc/partitions 2>/dev/null | sed 's/\ \ */ /g' | cut -d' ' -f4 ); \
    #    do sum=\$((sum+size)); done; [ \$sum -eq 0 ] && echo -n '' || echo \$sum" 0


    # Fix formatting (remove last comma in the category)
    json_output="${json_output%???}"
    json_output="$json_output\n  },\n"

    #
    # Collect SOFTWARE signals
    #
    json_output="$json_output  \"software_signals\": {\n"
    collect_signal "Machine ID" "cat /etc/machine-id" 0
    collect_signal "Device hostid" "hostid" 0
    collect_signal "Hostname" "echo \${HOSTNAME:-$(hostname 2>/dev/null)}" 0
    collect_signal "Random Boot UUID" "cat /proc/sys/kernel/random/boot_id" 0

    # Fix formatting (remove last comma in the category)
    json_output="${json_output%???}"
    json_output="$json_output\n  },\n"

    #
    # Collect NETWORK signals
    #
    json_output="$json_output  \"network_signals\": {\n"
    # Obtain default interface
    default_iface=$( handle_cmd "ip route 2>/dev/null | grep default | tail -n 1 | cut -d' ' -f5" )
    # If no default route is found, find the first non-loopback interface
    # with an IP address
    if [ -z "$default_iface" ]; then
        #default_iface=$( handle_cmd "ip link | grep 'state UP mode DEFAULT' | \
        #   grep 'BROADCAST,MULTICAST,UP,LOWER_UP' | cut -d' ' -f2 | sed 's/://g' | \
        #   head -n 1" )
        #default_iface=$( handle_cmd "ip link | grep 'state UP' | \
        #   grep 'BROADCAST,MULTICAST,UP,LOWER_UP' | cut -d' ' -f2 | \
        #   sed 's/://g' | head -n 1" )
        default_iface=$( handle_cmd "ip route get 8.8.8.8 2>/dev/null | sed -n 's/.*dev \([^ ]*\).*/\1/p'" )
    fi

    collect_signal "Private IP Address" "if [ -z \"\$( echo $default_iface | sed 's/[[:space:]]//g' )\" ]; \
        then echo ''; else ip addr show $default_iface | grep 'inet ' | cut -d' ' -f6 | cut -d'/' -f1 | \
        head -n 1; fi" 0
    # Query ipecho.net domain
    #collect_signal "Public IP Address" "( curl ipecho.net/plain 2>/dev/null ) || \
    #   ( printf \"GET /plain HTTP/1.1\\\r\\\nHost: ipecho.net\\\r\\\nConnection: close\\\r\\\n\\\r\\\n\" | \
    #     nc ipecho.net 80 | tail -n 1 )" 0
    # Root privileges needed to read file /sys/class/$iface/address
    #   - ip link can be executed w/o root privileges
    collect_signal "MAC Address" "([ -n \"$default_iface\" ] && ip link | grep -A 1 \" \$default_iface:\" | \
        tail -n 1 |  sed 's/\ \ */ /g' | cut -d' ' -f3 2>/dev/null) || \
        cat /sys/class/net/\$default_iface/address" 0
        #tail -n 1 |  sed 's/[[:space:]]\\+/ /g' | cut -d' ' -f3 2>/dev/null) || \
    #collect_signal "MAC Address" "(ip link 2>/dev/null | grep -A 1 \" \$default_iface:\" | tail -n 1 | \
    #    while read -r line; do echo \"\${line#\"\${line%%[![:space:]]*}\"}\"; done | \
    #    cut -d' ' -f2 2>/dev/null) || cat /sys/class/net/\$default_iface/address" 0
    collect_signal "Main Network Interface" "echo $default_iface" 0

    # Fix formatting (remove last comma in the category)
    json_output="${json_output%???}"
    json_output="$json_output\n  },\n"

    #
    # Collect OS signals
    #
    json_output="$json_output  \"os_signals\": {\n"
    collect_signal "OS Locale Settings" "echo $LANG" 0
    collect_signal "Kernel Version" "cat /proc/sys/kernel/osrelease" 0
    collect_signal "OS Version" "cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | sed 's/\"//g'" 0
    collect_signal "Last Boot Time" "grep btime /proc/stat | cut -d' ' -f2- 2>/dev/null" 0

    # Fix formatting (remove last comma in the category)
    json_output="${json_output%???}"
    json_output="$json_output\n  },\n"

    # Generate final fingerprinting hash
    if [ -n "$fingerprint_data" ]; then
        fingerprint_hash=$(handle_cmd "printf \"%s\" \"$fingerprint_data\" | $hash_cmd | cut -d' ' -f1")
        # Add it to the JSON file
        json_output="$json_output  \"fingerprint_hash\": {\n"
        json_output="$json_output      \"hash_digest\": \"$fingerprint_hash\",\n"
        json_output="$json_output      \"hash_algorithm\": \"$hash_cmd\"\n"
        json_output="$json_output  }\n"
    else
        echo "Error: No valid signals collected."
    fi

    # Close JSON
    json_output="$json_output}\n"

    # Output JSON to standard output
    $busybox_path printf "%b" "$json_output"
}

#============================================================================
# main()
#============================================================================
main() {

    # Default parameter values
    output_mode="private"
    hash_cmd="sha1sum"
    use_busybox=0
    busybox_path=""
    json_output=""

    # Unix tools defined here will be executed under the busybox environment
    #busybox_tools="sed grep tail head tr cut paste bc awk blkid uniq printf"
    #busybox_tools="sed grep tail head cut paste blkid uniq printf"
    busybox_tools="sed grep tail head cut paste blkid uniq nc printf"

    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                echo "Usage: $0 [--output <raw|private|both> --hash <sha1sum|sha256sum|md5sum|...> --busybox --busybox-path <.../.../busybox>]"
                exit 1
                ;;
            --output)
                if [ -n "$2" ] && [ "${2#??}" != "--" ] && \
                { [ "$2" = "raw" ] || [ "$2" = "private" ] || [ "$2" = "both" ]; } then
                    output_mode="$2"
                    shift 2
                else
                    echo "Usage: --output <raw|private|both>"
                    exit 1
                fi
                ;;
            --hash)
                if [ -n "$2" ] && [ "${2#??}" != "--" ]; then
                    hash_cmd="$2"
                    shift 2
                else
                    echo "Usage: --hash <sha1sum|sha256sum|md5sum|...>"
                    exit 1
                fi
                ;;
            --busybox|--busybox-path)
                if [ "$1" = "--busybox-path" ] && [ -n "$2" ] && [ "${2#??}" != "--" ]; then
                    busybox_path="$2"
                    shift 2
                else
                    busybox_path="busybox"
                    shift
                fi

                # check if we already modified these variables
                if [ $use_busybox -eq 0 ]; then
                    hash_cmd="$busybox_path $hash_cmd"
                fi
                use_busybox=1

                # Exit if provided path isn't recognized
                if [ ! -x "$(command -v "$busybox_path")" ]; then
                    echo "Error: $busybox_path not found on PATH"
                    echo "Usage: --busybox-path <busybox_path>"
                    exit 1
                fi
                ;;
            *)
                echo "Unknown argument: $1"
                echo "Usage: $0 [--output <raw|private|both> --hash-cmd <sha1sum|sha256sum|md5sum|...> --busybox --busybox-path <.../.../busybox>]"
                exit 1
                ;;
        esac
    done

    get_fingerprint
}


main "$@"

