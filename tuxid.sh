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

Usage: sh tuxid.sh --output {output_mode} --hash {hash_command}
Output Modes (default to private):
- raw       : only signal outputs are shown
- private   : only resulting hashes are shown
- both      : both signal outputs and hashes are shown
Hash Command: sha1sum, sha256sum, md5sum, etc

Suite (not used by default):
    - e.g. sh tuxid.sh --suite "/.../.../suite"
- --suite      : path to the software suite to handle unix/linux commands
'


#============================================================================
# check_root()
#
# Check script permissions
#============================================================================
check_root() {
    is_root=0

    # check if "id -u" output is numerical
    check_root1=$([ "$use_suite" -eq 1 ] \
        && echo "$suite_path id -u" 2>/dev/null \
        || echo "id -u" 2>/dev/null)
    if ! echo "$check_root1" | $suite_path grep -qE '^[0-9]+$' 2>/dev/null; then
        check_root1=-1
    fi
    # if "id -u" is unavailable attempt to read /root directory
    ls /root/ >/dev/null 2<&1 && check_root2=true || check_root2=false
    if [ "$check_root1" -eq 0 ] || "$check_root2"; then
        is_root=1
    fi
}


#============================================================================
# set_suite_env()
#
# Auxiliary function used to manage the suite environment.
# It prefixes every suite tool (defined in the $suite_tools variable)
# present in the command passed as argument, with the suite path
# defined by the user ($suite_path)
#
# Arguments:
#   $1 - The command to execute under the suite environment
#============================================================================
set_suite_env() {
    cmd=""

    # Disable globbing
    set -f
    # shellcheck disable=SC2086
    set -- $command
    # Enable globbing
    set +f
    for var; do
        flag=0
        for tool in $suite_tools; do
            if [ "$var" = "$tool" ]; then
                cmd="$cmd $suite_path $var"
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
# --suite argument is set, the command will be runned under
# the suite environment, meaning that all GNU/UNIX tools specified
# by the suite_tools variable
#
# Arguments:
#   $1 - The command to handle execution for
#============================================================================
handle_cmd() {
    command="$1"
    if [ "$use_suite" -eq 1 ]; then
        command=$(set_suite_env "$command")
    fi

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
            echo "Error: $hash failed"
            echo "Usage: --hash <sha1sum|sha256sum|md5sum|...>"
            echo "Error: $suite_path $hash_cmd command is unknown"
            exit 1
        fi
    fi

    # Append data to JSON
    case "$output_mode" in
        raw)
            json_output="$json_output\t\t\"$signal_name\": \"$result\",\n"
            ;;
        private)
            json_output="$json_output\t\t\"$signal_name\": \"$result_hash\",\n"
            ;;
        both)
            json_output="$json_output\t\t\"$signal_name\": {\n"
            json_output="$json_output\t\t\t\"raw\": \"$result\",\n"
            json_output="$json_output\t\t\t\"hash\": \"$result_hash\"\n"
            json_output="$json_output\t\t},\n"
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
    json_output="$json_output\t\"hardware_signals\": {\n"
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
        /proc/cpuinfo; } | uniq | sed 's/^[^:]*:[ \t]*//'" 0
    collect_signal "Total Memory (RAM)" "cat /proc/meminfo | grep '^MemTotal: ' | \
        cut -d':' -f2- | sed 's/ //g'" 0
    #
    # Total Disk Space:
    #   - df utility: use the bc tool to compute the sum of all partition sizes
    #   if available. If not, try to compute the sum directly.
    #   - /proc/partitions not used because it requires root permissions in some hosts.
    #
    collect_signal "Total Disk Space" "\
        ( df 2>/dev/null | sed '1d' | sed 's/\ \ */ /g' | cut -d' ' -f2 | paste -sd+ - | (bc || \$suite_path bc)) || \
        ( df 2>/dev/null | tail -n +2 | sed 's/\ \ */ /g' | cut -d' ' -f2 | { awk '{s+=\$1} END {print s}' 2>/dev/null || \
            \$suite_path awk '{s+=\$1} END {print s}' 2>/dev/null ; } ) || \
        (sum=0; for size in \
            \$( ( df -k 2>/dev/null || df 2>/dev/null ) | sed '1d' | sed 's/\ \ */ /g' | cut -d' ' -f2 ); \
        do sum=\$((sum+size)); done; echo \$sum)" 0

    # Fix formatting (remove last comma in the category)
    json_output="${json_output%???}"
    json_output="$json_output\n\t},\n"

    #
    # Collect SOFTWARE signals
    #
    json_output="$json_output\t\"software_signals\": {\n"
    collect_signal "Machine ID" "cat /etc/machine-id" 0
    collect_signal "Device hostid" "hostid" 0
    collect_signal "Hostname" "echo \${HOSTNAME:-$(hostname 2>/dev/null)}" 0
    collect_signal "Random Boot UUID" "cat /proc/sys/kernel/random/boot_id" 0

    # Fix formatting (remove last comma in the category)
    json_output="${json_output%???}"
    json_output="$json_output\n\t},\n"

    #
    # Collect NETWORK signals
    #
    json_output="$json_output\t\"network_signals\": {\n"
    # Obtain default interface
    default_iface=$( handle_cmd "ip route 2>/dev/null | grep default | tail -n 1 | cut -d' ' -f5" )
    # If no default route is found, find the first non-loopback interface
    # with an IP address
    if [ -z "$default_iface" ]; then
        default_iface=$( handle_cmd "ip route get 1.1.1.1 2>/dev/null | sed -n 's/.*dev \([^ ]*\).*/\1/p'" )
    fi

    # Private IP address
    #   - for public IP: query ipecho.net domain
    collect_signal "Private IP Address" "if [ -z \"\$( echo $default_iface | sed 's/[[:space:]]//g' )\" ]; \
        then echo ''; else ip addr show $default_iface | grep 'inet ' | cut -d' ' -f6 | cut -d'/' -f1 | \
        head -n 1; fi" 0
    collect_signal "Public IP Address" "if command -v curl >/dev/null 2>&1; then curl -s ifconfig.me; \
        else printf \"GET /ip HTTP/1.0\r\nHost: ifconfig.me\r\n\r\n\" | nc ifconfig.me 80 | tail -n1; fi" 0
    collect_signal "MAC Address" "([ -n \"$default_iface\" ] && ip link | grep -A 1 \" \$default_iface:\" | \
        tail -n 1 |  sed 's/\ \ */ /g' | cut -d' ' -f3 2>/dev/null) || \
        cat /sys/class/net/\$default_iface/address" 0
    collect_signal "Main Network Interface" "echo $default_iface" 0

    # Fix formatting (remove last comma in the category)
    json_output="${json_output%???}"
    json_output="$json_output\n\t},\n"

    #
    # Collect OS signals
    #
    json_output="$json_output\t\"os_signals\": {\n"
    collect_signal "OS Locale Settings" "echo $LANG" 0
    collect_signal "Kernel Version" "cat /proc/sys/kernel/osrelease" 0
    collect_signal "OS Version" "cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | sed 's/\"//g'" 0
    collect_signal "Last Boot Time" "grep btime /proc/stat | cut -d' ' -f2- 2>/dev/null" 0

    # Fix formatting (remove last comma in the category)
    json_output="${json_output%???}"
    json_output="$json_output\n\t},\n"

    # Generate final fingerprinting hash
    if [ -n "$fingerprint_data" ]; then
        fingerprint_hash=$(handle_cmd "printf \"%s\" \"$fingerprint_data\" | $hash_cmd | cut -d' ' -f1")
        # Add it to the JSON file
        json_output="$json_output\t\"fingerprint_hash\": {\n"
        json_output="$json_output\t\t\"hash_digest\": \"$fingerprint_hash\",\n"
        json_output="$json_output\t\t\"hash_algorithm\": \"$hash_cmd\"\n"
        json_output="$json_output\t}\n"
    else
        echo "Error: No valid signals collected."
    fi

    # Close JSON
    json_output="$json_output}\n"

    # Output JSON to standard output
    $suite_path printf "%b" "$json_output"
}

#============================================================================
# main()
#============================================================================
main() {

    # Default parameter values
    output_mode="private"
    hash_cmd="sha1sum"
    use_suite=0
    suite_path=""
    json_output=""

    # Unix tools defined here will be executed under the suite environment
    suite_tools="sed grep tail head cut paste blkid uniq printf"

    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                echo "Usage: $0 [--output <raw|private|both> --hash <sha1sum|sha256sum|md5sum|...> --suite <.../.../suite>]"
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
            --suite)
                if [ "$1" = "--suite" ] && [ -n "$2" ] && [ "${2#??}" != "--" ]; then
                    suite_path="$2"
                    shift 2
                else
                    echo "Usage: --suite '/path/'"
                    exit 1
                fi

                # check if we already modified these variables
                if [ $use_suite -eq 0 ]; then
                    hash_cmd="$suite_path $hash_cmd"
                fi
                use_suite=1

                # Exit if provided path isn't recognized
                if [ ! -x "$(command -v "$suite_path")" ]; then
                    echo "Error: $suite_path not found on PATH"
                    echo "Try to set its path directly: --suite <suite_path>"
                    exit 1
                fi
                ;;
            *)
                echo "Unknown argument: $1"
                echo "Usage: $0 [--output <raw|private|both> --hash <sha1sum|sha256sum|md5sum|...> --suite <.../.../suite>]"
                exit 1
                ;;
        esac
    done

    get_fingerprint
}


main "$@"

