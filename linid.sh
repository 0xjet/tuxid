#!/usr/bin/env bash

: '
Author: Daniel Canencia García
Title: Linux Boxes Fingerprinting Script
Description:
This script collects a set of hardware, software, network, and OS signals
to generate a unique fingerprint for a Linux machine. It supports three
modes (strict, moderate, relaxed) to control the level of signals included
in the fingerprint based on their volatility or reliability

Usage: ./linid.sh {mode}
Modes (default to strict):
- strict   : Includes only the permanent/non-volatile signals.
- moderate : Includes both strict and moderate (semi-volatile) signals
- relaxed  : Includes all signals, including non-permanent/volatile ones.
'

# Check if the script is running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script needs root privileges"
    exit 1
fi

# Global variables (edit as needed)
output_dir="signals"
json_file="$output_dir/fingerprint.json"
hash_file="$output_dir/fingerprint.out"

# Validate arguments
# mode (default to "strict")
mode_str="${1:-strict}"
# hash algorithm cmd (default to sha256)
hash_algo="${2:-sha256}"
# map modes to numeric values (strict: 1, moderate: 2, relaxed: 3)
case "$mode_str" in
    strict)
        mode=1
        ;;
    moderate)
        mode=2
        ;;
    relaxed)
        mode=3
        ;;
    *)
        echo "Usage: $0 {strict|moderate|relaxed}"
        # echo "Error: Invalid mode. Please use 'strict', 'moderate', or 'relaxed'."
        exit 1
        ;;
esac


# Initialization
# create output directory and json file
mkdir -p "$output_dir"
# data used for generating the hash
fingerprint_data=""
# create the JSON file
echo "{" > "$json_file"

# Add user specified arguments to the JSON file
echo "  \"arguments\": {" >> "$json_file"
echo "    \"mode\": \"$mode_str\"," >> "$json_file"
echo "    \"hash_algorithm\": \"$hash_algo\"" >> "$json_file"
echo -e "  },\n" >> "$json_file"

# Function to collect a signal, write it to a file, and prepare fingerprint data
collect_signal() {
    local signal_name="$1"
    local command="$2"
    local category="$3"
    # signal modes (strict, moderate, relaxed)
    local mode_check="$4"

    # check signal mode
    if (( $mode_check <= $mode )); then
        # Execute the command using eval to handle complex shell syntax
        local result
        result=$(eval "$command" 2>/dev/null)

        # If the result is empty or invalid, use "N/A" as the fallback
        if [[ -z "$result" ]]; then
            result="N/A"
        fi

        # Write the result to the JSON file under the appropriate category
        echo "          \"$signal_name\": \"$result\"," >> "$json_file"

        # Add the result to fingerprint_data if it's not "N/A"
        if [[ "$result" != "N/A" ]]; then
            fingerprint_data+="$result"
        fi
   fi
}

# Create the signals category in the JSON object
echo "  \"signals\": {" >> "$json_file"

# Collect Hardware Signals
echo "Collecting Hardware Signals..."
echo "      \"hardware_signals\": {" >> "$json_file"
# Strict: Permanent/non-volatile signals
collect_signal "Device Model" "cat /sys/devices/virtual/dmi/id/product_name" "hardware_signals" "1"
collect_signal "Device Vendor" "cat /sys/devices/virtual/dmi/id/sys_vendor" "hardware_signals" "1"
collect_signal "Main Board Product UUID" "cat /sys/devices/virtual/dmi/id/product_uuid" "hardware_signals" "1"
collect_signal "Main Board Product Serial" "cat /sys/devices/virtual/dmi/id/board_serial" "hardware_signals" "1"
#collect_signal "Storage Devices UUIDs" "lsblk -no UUID | grep -v '^$' | tr '\n' '|' | sed 's/|$//'" "hardware_signals" "1"
# UUIDs of active partitions currently mounted on the system
collect_signal "Storage Devices UUIDs" \
        "lsblk -no UUID,MOUNTPOINT | grep -E '[^[:space:]]' |
            while IFS=' ' read -r uuid mountpoint; do \
                if [[ -n \"\$uuid\" && -n \"\$mountpoint\" ]]; then
                    echo -n \"\$uuid|\";
                fi; \
            done |
         sed 's/|$//'" "hardware_signals" "1"
collect_signal "Processor Model Name" "cat /proc/cpuinfo | grep 'model name' | cut -d':' -f2- | uniq | tr -d ' '" "hardware_signals" "1"
collect_signal "Total Memory (RAM)" "cat /proc/meminfo | grep 'MemTotal: ' | cut -d':' -f2- | tr -d ' '" "hardware_signals" "1"
collect_signal "Root Filesystem Total Disk Space" "df -h | grep /$ | tr -s ' ' | cut -d' ' -f2" "hardware_signals" "1"
# total disk space that is currently mount on (belongs to the current linux system)
collect_signal "Total Disk Space" "df -h --total --output=size | tail -n 1 | tr -d ' '" "hardware_signals" "1"
# Moderate: Include semi-volatile signals
collect_signal "Used Disk Space" "df -h --total --output=used | tail -n 1 | tr -d ' '" "hardware_signals" "2"
collect_signal "Available Disk Space" "df -h --total --output=avail | tail -n 1 | tr -d ' '" "hardware_signals" "2"
# Relaxed: Include volatile signals
collect_signal "AC Power State" "grep '(Charging\|Discharging)' /sys/class/power_supply/BAT0/status" "hardware_signals" "3"
collect_signal "Available Memory (RAM)" "cat /proc/meminfo | grep 'MemFree: ' | cut -d':' -f2- | tr -d ' '" "hardware_signals" "3"
collect_signal "Cached Memory (RAM)" "cat /proc/meminfo | grep '^Cached: ' | cut -d':' -f2- | tr -d ' '" "hardware_signals" "3"
# Remove last comma in the category (fix formatting)
sed -i '$ s/,$//' "$json_file"
echo -e "      },\n" >> "$json_file"

# Collect Software Signals
echo "Collecting Software Signals..."
echo "      \"software_signals\": {" >> "$json_file"
# Strict: Permanent/non-volatile signals
collect_signal "machine-id" "cat /etc/machine-id" "software_signals" "1"
# Moderate: Include semi-volatile signals
collect_signal "device hostid" "hostid" "software_signals" "2"
collect_signal "hostname" "hostname" "software_signals" "2"
collect_signal "Linux session ID" "cat /proc/self/sessionid" "software_signals" "2"
collect_signal "Linux user ID" "id -u" "software_signals" "2"
# Relaxed: Include volatile signals
collect_signal "random boot UUID" "cat /proc/sys/kernel/random/boot_id" "software_signals" "3"
# Remove last comma in the category (fix formatting)
sed -i '$ s/,$//' "$json_file"
echo -e "      },\n" >> "$json_file"

# Collect Network-related Signals
echo "Collecting Network-related Signals..."
echo "      \"network_signals\": {" >> "$json_file"
iface=$(route | grep default | tr -s ' ' | cut -d' ' -f8)
# Strict: Permanent/non-volatile signals
collect_signal "MAC Address" "cat /sys/class/net/$iface/address" "network_signals" "1"
# Moderate: Include semi-volatile signals
collect_signal "IP Address" "ip route get 1.0.0.0 | head -n 1 | cut -d' ' -f7" "network_signals" "2"
collect_signal "Main Network Interface" "echo $iface" "network_signals" "2"
# Remove last comma in the category (fix formatting)
sed -i '$ s/,$//' "$json_file"
echo -e "      },\n" >> "$json_file"

# Collect Operating System (OS) Signals
echo "Collecting OS Signals..."
echo "      \"os_signals\": {" >> "$json_file"
# Strict: Permanent/non-volatile signals
collect_signal "OS Locale Settings" "cat /etc/locale.conf | grep '^LANG=' | cut -d'=' -f2-" "os_signals" "1"
collect_signal "Kernel Version" "cat /proc/version | cut -d' ' -f3" "os_signals" "1"
collect_signal "OS Version" "cat /etc/os-release | grep '^PRETTY_NAME=' | cut -d'\"' -f2" "os_signals" "1"
# Remove last comma in the category (fix formatting)
sed -i '$ s/,$//' "$json_file"
echo -e "      }" >> "$json_file"

# Close the signals category
echo -e "  },\n" >> "$json_file"

# Collection completed
echo -e "Signal collection completed!\n"

# Generate the machine fingerprint hash
echo "Generating machine fingerprint..."
if [[ -n "$fingerprint_data" ]]; then
    fingerprint_hash=$(echo -n "$fingerprint_data" | $hash_algo"sum" | cut -d' ' -f1)
    # Add it to the JSON file
    echo "  \"fingerprint_hash\": {" >> "$json_file"
    echo "    \"hash_digest\": \"$fingerprint_hash\"," >> "$json_file"
    echo "    \"algorithm\": \"$hash_algo\"" >> "$json_file"
    echo "  }" >> "$json_file"

    # Add hash to a separe file
    echo -e "$fingerprint_hash" > "$hash_file"
    echo "Machine Fingerprint (hash digest): $fingerprint_hash"
else
    echo "No valid signals collected for fingerprinting."
fi

# close the JSON object
echo -e "}" >> "$json_file"

echo -e "\nOutput directory: $output_dir"

