#!/bin/bash

# Needs a folder containing a folder per device and in there different jsons
# for different boots (e.g. folder/device1/{boot1.json, boot2.json, ...})

# Usage: bash tuxid_stability.sh <directory_with_device_folders>

# Check if the directory is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <directory_with_device_folders>"
  exit 1
fi

# Input folder (directory containing device folders)
INPUT_DIR="$1"

# Define the categories to consider
categories=("hardware_signals" "software_signals" "network_signals" "os_signals")

# Initialize variables to store the results
declare -A stability
declare -A device_stability
declare -A signal_stability
declare -A signal_counts
declare -A signal_matches

# Iterate over all device folders in the given directory
for device_folder in "$INPUT_DIR"/*/; do
  # Extract device name (folder name)
  device_name=$(basename "$device_folder")

  declare -A per_device_signal_counts
  declare -A per_device_signal_values
  per_device_signal_counts=()  # Clear previous device data
  per_device_signal_values=()  # Clear previous device data

  #echo ${per_device_signal_values[@]}

  boot_count=0
  # Iterate over each boot (JSON file) in the device folder
  for json_file in "$device_folder"/*.json; do
    ((boot_count++))
    # Read the entire device JSON data
    if [ -f "$json_file" ]; then
        # Extract the JSON data from the device file
        device_data=$(cat "$json_file")

        # Iterate through each category in the JSON file
        for category in "${categories[@]}"; do
          # Extract the signals for the current category
          signals=$(echo "$device_data" | jq -r ".${category}")

          # Loop through each signal in the category (keeping order)
          while read -r signal; do
            # Properly quote the signal name to handle spaces
            signal_value=$(echo "$signals" | jq -r ".\"$signal\"")

            per_device_signal_counts["$signal"]=$boot_count
            if [ "$signal_value" != "N/A" ]; then
                # Initialize or count the signal matches
                #if [ -z "${device_stability[\"$signal\"]}" ]; then
                #  device_stability["$signal"]=1
                #elif [ "$signal_value" == "${device_stability[$signal]}" ]; then
                #  device_stability["$signal"]=$((device_stability["$signal"] + 1))
                #fi
                #echo ${device_stability["$signal"]}

                # Skip if value is empty
                #if [ -z "$signal_value" ] || [ "$signal_value" == "null" ]; then
                #  continue
                #fi

                # Track occurrences of this signal's values
                #per_device_signal_values["$signal,$signal_value"]=$((per_device_signal_values["$signal,$signal_value"] + 1))
                if [[ -v per_device_signal_values["$signal,$signal_value"] ]]; then
                    per_device_signal_values["$signal,$signal_value"]=$((per_device_signal_values["$signal,$signal_value"] + 1))
                else
                    per_device_signal_values["$signal,$signal_value"]=1
                fi
                #per_device_signal_counts["$signal"]=$boot_count
            fi

            if [[ ! " ${ordered_signals[*]} " =~ " $signal " ]]; then
                ordered_signals+=("$signal")  # Maintain order
            fi
          done < <(echo "$signals" | jq -r 'keys[]')
        done
    fi
  done

  # Calculate stability per signal for this device
  for signal in "${!per_device_signal_counts[@]}"; do
    total_boots="${per_device_signal_counts["$signal"]}"
    #echo $total_boots

    # Find most common value count for this signal
    max_occurrences=0
    for key in "${!per_device_signal_values[@]}"; do
      IFS=',' read -r key_signal key_value <<< "$key"
      if [[ "$key_signal" == "$signal" ]]; then
        if (( per_device_signal_values["$key"] > max_occurrences )); then
          max_occurrences=${per_device_signal_values["$key"]}
        fi
      fi
    done

    # if all signal values are "N/A" don't count it
    if [[ $max_occurrences -ne 0 ]];then
        #echo -n "Signal: "
        #echo $signal

        # Calculate stability (most frequent value occurrences / total boots)

        # Calculate stability as an integer count
        if (( total_boots > 0 )); then
            #stability=$((max_occurrences * 1000 / total_boots))
            stability=$((max_occurrences * 100 / total_boots))
        else
            stability=0
        fi

        # echo -n "Stability: "
        # echo -n $max_occurrences
        # echo -n " * 1000 / "
        # echo -n $total_boots
        # echo -n " = "
        # echo $stability

        # If signal already has stability tracked, increment count
        if [[ -v signal_stability["$signal"] ]]; then
          signal_stability["$signal"]=$((signal_stability["$signal"] + stability))
        else
          signal_stability["$signal"]=$stability
        fi

        # Count how many devices reported this signal
        if [[ -v signal_counts["$signal"] ]]; then
            signal_counts["$signal"]=$((signal_counts["$signal"] + 1))
        else
            signal_counts["$signal"]=1
        fi

    fi
  done

  # echo "FIN"
done

# Calculate average stability per signal (integer division)
declare -A final_stability
for signal in "${!signal_stability[@]}"; do
  total_devices="${signal_counts["$signal"]}"
  #echo -n "Total Devices: "
  #echo $total_devices

  # Avoid division by zero
  if [ "$total_devices" -eq 0 ]; then
    final_stability["$signal"]=1000
  else
    final_stability["$signal"]=$((signal_stability["$signal"] / total_devices))
  fi

  #echo -n "F: "
  #echo -n ${signal_stability["$signal"]}
  #echo -n " / "
  #echo $total_devices

  #echo -n "Signal: "
  #echo -n "$signal"
  #echo -n ", Matches: "
  #echo -n ${signal_counts["$signal"]}
  #echo -n ", Stability: "
  #echo -n ${final_stability["$signal"]}
  #echo ""
done


# Create data file for plotting
echo "Signal Name,Stability" > stability_data.csv
for signal in "${ordered_signals[@]}"; do
    if [[ -v final_stability["$signal"] ]]; then
      #stability_percent=$((final_stability["$signal"] / 10))
      stability_percent=$((final_stability["$signal"]))
      echo "$signal, $stability_percent" >> stability_data.csv
    fi
done

# Generate a bar chart using gnuplot
# gnuplot <<- EOF
#    set terminal png size 1000,600;
#    set output 'stability_chart.png';
#    set title 'Stability per Signal';
#    set xlabel 'Signal';
#    set ylabel 'Stability (%)';

    # Set the datafile separator as comma
#    set datafile separator ","

#    set xtics rotate by -45
#    set yrange [0:100];  # Ensures Y-axis always goes from 0 to 100
#    set grid
#    set boxwidth 0.9 relative # thickness
#    set style fill solid 0.70 # color intensity
#    set style line 1 lc rgb "black" # color profile
#    set lmargin at screen 0.12
#    set rmargin at screen 0.9

#    plot 'stability_data.csv' using 0:2:xticlabel(1) with boxes notitle linestyle 1;
#EOF

# Clean up
#rm stability_data.csv

#echo "Bar chart generated: stability_chart.png"

