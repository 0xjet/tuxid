#import argparse
import subprocess
import pandas as pd
import matplotlib.pyplot as plt
import os, sys
import numpy as np

output_img_path = "entropy_vs_stability_chart.png"

def run_entropy_script(directory):
    """Run tuxid_entropy.sh and return a DataFrame."""
    result = subprocess.run(['./tuxid_entropy.sh', '--dir', directory, '--format', 'csv'],
                            capture_output=True, text=True, check=True)
    from io import StringIO
    return pd.read_csv(StringIO(result.stdout))

def run_stability_script(directory):
    """Run tuxid_stability.sh and return a DataFrame."""
    result = subprocess.run(['./tuxid_stability.sh', directory],
                            capture_output=True, text=True, check=True)
    from io import StringIO
    return pd.read_csv(StringIO(result.stdout))

def load_stability_data(path='stability_data.csv'):
    return pd.read_csv(path)

def generate_entropy_vs_stability_plot(entropy_df, stability_df):

    # Ensure clean, matching column names
    entropy_df.columns = entropy_df.columns.str.strip()
    stability_df.columns = stability_df.columns.str.strip()

    """
    print("Entropy DataFrame columns:", entropy_df.columns.tolist())
    print("Stability DataFrame columns:", stability_df.columns.tolist())
    print("\nEntropy Signals:\n", entropy_df['Signal Name'].tolist())
    print("\nStability Signals:\n", stability_df['Signal Name'].tolist())
    """

    # Merge on 'Signal Name'
    merged_df = pd.merge(entropy_df, stability_df, on='Signal Name', how='inner')
    #print("\nMerged DataFrame:\n", merged_df.head())


    # Plot
    fig, ax1 = plt.subplots(figsize=(14, 6))

    # Bar chart for entropy
    entropy_color = '#1f77b4'
    ax1.bar(merged_df['Signal Name'], merged_df['Entropy'], color=entropy_color, label='Entropy')
    ax1.set_ylabel('Normalized Entropy', color=entropy_color, fontweight='bold')
    ax1.tick_params(axis='y', labelcolor=entropy_color)
    merged_df['x'] = np.arange(len(merged_df))
    ax1.set_xticks(merged_df['x'])
    ax1.set_xticklabels(merged_df['Signal Name'], rotation=45, ha='right', fontsize=8)

    # Line plot for stability
    stability_color = 'darkred'
    ax2 = ax1.twinx()
    ax2.plot(merged_df['Signal Name'], merged_df['Stability'], color=stability_color, marker='o', label='Stability')
    ax2.set_ylabel('Stability (%)', color=stability_color, fontweight='bold')
    ax2.tick_params(axis='y', labelcolor=stability_color)

    # Make tick labels bold
    for label in ax1.get_xticklabels():
        label.set_fontweight('bold')
    for label in ax1.get_yticklabels():
        label.set_fontweight('bold')
    # If you're also using a secondary y-axis (like ax2), do this as well:
    for label in ax2.get_yticklabels():
        label.set_fontweight('bold')


    # Combine legends
    #bars_proxy = plt.Line2D([0], [0], marker='s', color='w', label='Entropy',
    #                        markerfacecolor=entropy_color, markersize=10)
    #line_proxy = plt.Line2D([0], [0], marker='o', color=stability_color, label='Stability')
    #plt.legend(handles=[bars_proxy, line_proxy], loc='upper left')

    # Combine legends
    handles, labels = ax1.get_legend_handles_labels()
    handles2, labels2 = ax2.get_legend_handles_labels()
    all_handles = handles + handles2
    all_labels = labels + labels2

    # Place legend centered below title
    fig.legend(all_handles, all_labels, loc='upper right',
               bbox_to_anchor=(0.95, 1), ncol=2, frameon=True)


    plt.title('Entropy vs Stability')
    plt.tight_layout()
    plt.savefig(output_img_path)
    print(f"Graph saved to: {output_img_path}")

def main():
    if len(sys.argv) != 2:
        print("Usage: python tuxid_stability.py <directory>")
        sys.exit(1)

    input_dir = sys.argv[1]
    if not os.path.isdir(input_dir):
        print(f"Error: {input_dir} is not a valid directory")
        sys.exit(1)

    #parser = argparse.ArgumentParser()
    #parser.add_argument('--dir', required=True, help='Target directory for entropy script')
    #args = parser.parse_args()

    entropy_df = run_entropy_script(input_dir)
    stability_df = load_stability_data()

    generate_entropy_vs_stability_plot(entropy_df, stability_df)

if __name__ == '__main__':
    main()

