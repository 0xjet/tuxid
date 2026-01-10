import csv
import os
import subprocess
import sys
from io import StringIO

import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import matplotlib.lines as mlines
import numpy as np
import pandas as pd

signal_metadata = {
    # --- Hardware Signals ---
    "Device Model": {
        "user_resettable": "No",
        "read_privileges": "local",
    },
    "Device Vendor": {
        "user_resettable": "No",
        "read_privileges": "local",
    },
    "Main Board Product UUID": {
        "user_resettable": "No",
        "read_privileges": "local root",
    },
    "Main Board Product Serial": {
        "user_resettable": "No",
        "read_privileges": "local root",
    },
    "Storage Devices UUIDs": {
        "user_resettable": "Yes",
        "read_privileges": "local",
    },
    "Processor Model Name": {
        "user_resettable": "No",
        "read_privileges": "local",
    },
    "Total Memory (RAM)": {
        "user_resettable": "No",
        "read_privileges": "local",
    },
    "Total Disk Space": {
        "user_resettable": "Yes",
        "read_privileges": "local",
    },

    # --- Software Signals ---
    "Machine ID": {
        "user_resettable": "Yes",
        "read_privileges": "local",
    },
    "Device hostid": {
        "user_resettable": "Yes",
        "read_privileges": "local",
    },
    "Hostname": {
        "user_resettable": "Yes",
        "read_privileges": "local",
    },
    "Random Boot UUID": {
        "user_resettable": "No",
        "read_privileges": "local",
    },

    # --- Network-related Signals ---
    "Private IP Address": {
        "user_resettable": "Yes",
        "read_privileges": "local",
    },
    "Public IP Address": {
        "user_resettable": "Yes",
        "read_privileges": "local",
    },
    "MAC Address": {
        "user_resettable": "Yes",
        "read_privileges": "local",
    },
    "Main Network Interface": {
        "user_resettable": "No",
        "read_privileges": "local",
    },

    # --- OS Signals ---
    "OS Locale Settings": {
        "user_resettable": "Yes",
        "read_privileges": "local",
    },
    "Kernel Version": {
        "user_resettable": "No",
        "read_privileges": "local",
    },
    "OS Version": {
        "user_resettable": "No",
        "read_privileges": "local",
    },
    "Last Boot Time": {
        "user_resettable": "No",
        "read_privileges": "local",
    }
}

def run_tuxid_entropy_script(input_dir):
    """Run tuxid_entropy.sh and capture CSV output from stdout."""
    cmd = ["./tuxid_entropy.sh", "--dir", input_dir, "--format", "csv"]
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    return result.stdout

def process_csv(csv_data):
    """Process and augment CSV data with signal metadata."""
    input_io = StringIO(csv_data)
    reader = csv.DictReader(input_io)

    # Define new fieldnames (insert after 'Signal')
    original_fields = reader.fieldnames
    fieldnames = []
    for field in original_fields:
        fieldnames.append(field)
        if field == "Signal Name":
            fieldnames.extend(["user_resettable", "read_privileges"])

    # Write modified data to stdout or file
    output_io = StringIO()
    writer = csv.DictWriter(output_io, fieldnames=fieldnames)
    writer.writeheader()

    for row in reader:
        signal_name = row.get("Signal Name")
        metadata = signal_metadata.get(signal_name, {})
        row["user_resettable"] = metadata.get("user_resettable", "")
        row["read_privileges"] = metadata.get("read_privileges", "")
        writer.writerow(row)

    return output_io.getvalue()


def generate_visualization(csv_content, output_img_path="signal_entropy_chart.png"):
    df = pd.read_csv(StringIO(csv_content))

    # Set discrete x positions
    df = df.copy()

    # Map privilege to y-axis side (1 for privileged, -1 for non-privileged)
    df['y'] = df['user_resettable'].apply(lambda x: 1 if 'Yes' in x else -1)

    # Normalize entropy to reasonable radius scale based on figure size
    max_radius = 0.4  # max circle size (adjust as needed)
    df['radius'] = df['Entropy'] / df['Entropy'].max() * max_radius


    # Split by y (user resettable vs not)
    df_top = df[df['y'] == 1].copy()
    df_bottom = df[df['y'] == -1].copy()

    # Function to compute x-positions tightly
    def compute_x_positions(group_df):
        x_positions = []
        current_x = 0
        prev_radius = 0

        for radius in group_df['radius']:
            if x_positions:
                # Space based on previous + current radius, plus padding
                padding = 0.25
                if radius < 0.22:
                    padding = 0.5

                current_x += prev_radius + radius + padding
            x_positions.append(current_x)
            prev_radius = radius

        group_df['x'] = x_positions
        return group_df

    # Apply to each group
    df_top = compute_x_positions(df_top)
    df_bottom = compute_x_positions(df_bottom)
    # Combine the groups back
    df = pd.concat([df_top, df_bottom], ignore_index=True)


    # Map resettability to color
    color_map = {'local root': 'red', 'local': 'green'}
    df['color'] = df['read_privileges'].map(color_map).fillna('gray')

    # Plot
    fig, ax = plt.subplots(figsize=(1.2 * len(df), 6))  # Dynamic width

    for _, row in df.iterrows():
        jittered_x = row['x'] + np.random.uniform(-0.1, 0.1)  # slight jitter
        circle = mpatches.Circle((jittered_x, row['y']), row['radius'], color=row['color'], alpha=0.6)
        ax.add_patch(circle)
        ax.text(jittered_x, row['y'], row['Signal Name'], ha='center', va='center', fontsize=8, rotation=45)

    # Draw dividing line
    ax.axhline(0, color='black', linestyle='--')


    # Get the maximum x + radius for proper limits
    max_x = max(df['x'] + df['radius'])
    ax.set_xlim(-0.7, max_x+0.2)
    ax.set_ylim(-2, 2)

    ax.set_aspect('equal', 'box')
    ax.grid(False)
    plt.title("Entropy vs. Resettability and Privilege")

    # Axis labeling
    ax.set_xlabel("Signal Name", fontsize=12)
    ax.set_ylabel("User Resettability Privilege", fontsize=12)
    ax.set_xticks([])  # Hide x-ticks for cleanliness
    ax.set_yticks([-1, 1])
    ax.set_yticklabels(["Not User Resettable", "User Resettable"], rotation=90)
    for label in ax.get_yticklabels():
        label.set_verticalalignment('center')

    # Add legend
    red_patch = mpatches.Patch(color='red', label='Root Privileges')
    green_patch = mpatches.Patch(color='green', label='Local/User Privileges')
    #plt.legend(handles=[green_patch, red_patch], loc='upper center', ncol=2)


    # Legend for entropy (circle size)
    entropy_line = mlines.Line2D([], [], color='black', marker='o',
                                linestyle='None', markersize=10,
                                label='Circle size = Entropy (Normalized)')

    # Combine legends
    legend_handles = [red_patch, green_patch, entropy_line]
    ax.legend(handles=legend_handles, loc='upper center', ncol=3,
              frameon=True)

    plt.savefig(output_img_path)
    print(f"Graph saved to: {output_img_path}")

def main():
    if len(sys.argv) != 2:
        print("Usage: python tuxid_entropy.py <directory>")
        sys.exit(1)

    input_dir = sys.argv[1]
    if not os.path.isdir(input_dir):
        print(f"Error: {input_dir} is not a valid directory")
        sys.exit(1)

    try:
        raw_csv = run_tuxid_entropy_script(input_dir)
        extended_csv = process_csv(raw_csv)
        print(extended_csv)

        generate_visualization(extended_csv)
    except subprocess.CalledProcessError as e:
        print("Error running tuxid_entropy.sh:", e.stderr, file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()


