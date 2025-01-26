#!/usr/bin/env sh

: '
Author: Daniel Canencia García
Title: Linux Boxes Signal Entropy Calculator
Description: This script process all json files present in a directory
specified by the user, and calculates the entropy of every signal
present in any of those files

Usage: sh linid_entropy.sh --dir <json_files_directory> --format <table|json|csv>

Note: This script is intended to work with json files of the next type,
where every json category corresponds to an specific signal category
(e.g. hardware_signals)

    {
      "hardware_signals": {
          "Total Memory (RAM)": "3e062c9eebefc4741ce880025a24df5cbca47ca3",
          "Available Memory (RAM)": "67d3039486dc248b18bf463298259b1f77796f84",
          ....
      },
      "software_signals": {
          "Hostname": "354389048b872a533002b34d73f8c29fd09efc50",
          ....
      },
      "network_signals": {
          ....
      },
      "os_signals": {
          ....
      },
      ....
    }

'

# Check if jq is installed
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required but not installed"
    exit 1
fi

# Default arguments
output_format="csv"
input_dir=""

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            echo "Usage: $0 --dir <directory_with_json_files> --format <json|csv|table>"
            exit 1
            ;;
        --format)
            output_format="$2"
            shift 2
            ;;
        --dir)
            if [ ! -d "$2" ] || [ -z "$(ls "$2"/*.json 2>/dev/null)" ]; then
                echo "Directory does not exists: $1"
                echo "Usage: $0 <directory_with_json_files>"
                exit 1
            fi
            input_dir="${2%/}"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: $0 --dir <directory_with_json_files> --format <json|csv|table>"
    esac
done

# Variables
signal_categories="hardware_signals|software_signals|network_signals|os_signals"
signal_separator='|'
signals_names=""
json_files=$(find "$input_dir"/*.json | tr '\n' '|')

# Function to calculate the normalized entropy value for a
# given signal, based on the Shannon Entropy Formula
#
# Arguments:
#   $1 - Complete list of signal hashes
#   $2 - Total number of hashes present in the list
calculate_normalized_entropy() {
    hashes="$1"
    total_hashes="$2"

    if [ "$total_hashes" -eq 0 ]; then
        echo 0; return;
    fi

    # Map unique number of hashes and its count
    # Example:
    #   - hashes = a b c a b c c d
    #   - hash_map = 2 a 2 b 3 c 1 d
    hash_map=""
    unset IFS
    for hash in $hashes; do
        # Count the occurrences of each hash
        count=$(echo "$hashes" | grep -c "$hash")
        # Add it to the hash map (avoid duplicates)
        if [ -z "$hash_map" ]; then
            hash_map="$count $hash|"
        fi
        if ! echo "$hash_map" | grep -q "$hash"; then
            hash_map="$hash_map$count $hash|"
        fi
    done
    # Remove the last newline character from hash_map
    hash_map=$(echo "$hash_map" | sed 's/|$//')

    # Shannon Entropy formula
    IFS=$signal_separator
    entropy=0
    # Now calculate entropy
    for line in $hash_map; do
        count=$(echo "$line" | cut -d' ' -f1)
        hash=$(echo "$line" | cut -d' ' -f2)

        # Skip empty lines
        if [ -z "$count" ] || [ -z "$hash" ]; then
            continue
        fi

        # p_i = (count of hash i) / (total number of hashes)
        p=$(echo "$count / $total_hashes" | bc -l)

        # p_i * log2(p_i)
        entropy=$(echo "$entropy + ($p * l($p) / l(2))" | bc -l)
    done

    # H(X) = - (p_i * log2(p_i))
    entropy=$(echo "-1 * $entropy" | bc -l)
    # H_max = log2(total number of hashes)
    max_entropy=$(echo "l($total_hashes) / l(2)" | bc -l)
    # H(X) = H(X) / H_max
    if [ "$max_entropy" = 0 ]; then
        normalized_entropy=0
    else
        normalized_entropy=$(echo "$entropy / $max_entropy" | bc -l)
    fi

    echo "$normalized_entropy"
}

# Aulixiary function that add signal names to the
# $signals_names array avoiding duplicates
#
# Arguments:
#   $1 - Signal name to insert
add_signal_name() {
    value="$1"
    # value already in the string
    if echo "$signals_names" | grep -q "$value"; then
        return
    fi

    # first value in string
    if [ -z "$signals_names" ]; then
        signals_names="$value"
    # next values
    else
        signals_names="$signals_names|$value"
    fi
}

# Main process: Extracts all hashes present in a JSON file
# group by signal names
IFS=$signal_separator
for category in $signal_categories; do

    # process each JSON file
    for json_file in $json_files; do
        signals=$(jq -r ".$category | keys[]" "$json_file" | tr '\n' '|' 2>/dev/null)

        for signal_name in $signals; do
            # add signal name to global variable
            add_signal_name "$signal_name"
            # obtain signal's hash
            signal_hash=$(jq -r ".${category}[\"${signal_name}\"]" "$json_file")
            if [ -n "$signal_hash" ] && [ "$signal_hash" != "N/A" ]; then
                # save hashes in global variable
                if [ -z "$signals_data" ]; then
                    signals_data="$signal_name $signal_hash"
                else
                    signals_data="$signals_data\n$signal_name $signal_hash"
                fi
            fi
        done
    done
done

# Present output data to the user based on the selected
# format defined by the input flag --format (either table,
# csv or json)
if [ "$output_format" = "table" ]; then
    echo "-------------------------------------------------------------------"
    echo "                         Signal Analysis"
    echo "-------------------------------------------------------------------"
    printf "\n%-24s | %-6s | %-6s | %-10s | %-10s\n" "Signal Name" "Total" "Unique" "Collisions" "Entropy"
    echo "-------------------------------------------------------------------"
    for signal_name in $signals_names; do
        hashes=$(echo "$signals_data" | grep "$signal_name" | sed -E "s/.* ([a-f0-9]{40})$/\1/")
        total_hashes=$(echo "$hashes" | wc -w)
        unique_hashes=$(echo "$hashes" | tr ' ' '\n' | sort | uniq | wc -l)
        collisions=$((total_hashes - unique_hashes))
        normalized_entropy=$(calculate_normalized_entropy "$hashes" "$total_hashes")
        printf "%-24s | %-6d | %-6d | %-10d | %-6.4f\n" "$signal_name" "$total_hashes" "$unique_hashes" "$collisions" "$normalized_entropy"
    done
    echo "-------------------------------------------------------------------"
elif [ "$output_format" = "csv" ]; then
    echo "Signal Name,Total,Unique,Collisions,Entropy"
    for signal_name in $signals_names; do
        hashes=$(echo "$signals_data" | grep "$signal_name" | sed -E "s/.* ([a-f0-9]{40})$/\1/")
        total_hashes=$(echo "$hashes" | wc -w)
        unique_hashes=$(echo "$hashes" | tr ' ' '\n' | sort | uniq | wc -l)
        collisions=$((total_hashes - unique_hashes))
        normalized_entropy=$(calculate_normalized_entropy "$hashes" "$total_hashes")
        printf "%s,%d,%d,%d,%.4f\n" "$signal_name" "$total_hashes" "$unique_hashes" "$collisions" "$normalized_entropy"
    done
elif [ "$output_format" = "json" ]; then
    printf "{\n   \"signals\": ["
    first_signal=true
    for signal_name in $signals_names; do
        hashes=$(echo "$signals_data" | grep "$signal_name" | sed -E "s/.* ([a-f0-9]{40})$/\1/")
        total_hashes=$(echo "$hashes" | wc -w)
        unique_hashes=$(echo "$hashes" | tr ' ' '\n' | sort | uniq | wc -l)
        collisions=$((total_hashes - unique_hashes))
        normalized_entropy=$(calculate_normalized_entropy "$hashes" "$total_hashes")
        [ "$first_signal" = true ] || echo ","
        first_signal=false
        printf "      {\n"
        printf "        \"name\": %s,\n" "$signal_name"
        printf "        \"total\": %d,\n" "$total_hashes"
        printf "        \"unique\": %d,\n" "$unique_hashes"
        printf "        \"collisions\": %d,\n" "$collisions"
        printf "        \"entropy\": %.4f,\n" "$normalized_entropy"
        printf "      }"
    done
    printf "\n    ]"
    echo "}"
fi

