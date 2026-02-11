![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-linux-lightgrey)
![Shell](https://img.shields.io/badge/shell-POSIX-4EAA25)
![Version](https://img.shields.io/badge/version-1.0.0-orange)

# tuxid
A lightweight POSIX-compliant shell script that collects hardware, system, and network signals to generate a unique, reproducible fingerprint for a Linux machine.

## Overview

`tuxid` is a tool for performing local device fingerprinting on Linux and Linux-based systems. The fingerprint produced by `tuxid` is derived from multiple system, network, and hardware signals and can be used to re-identify the device at a subsequent time.

This [blog post](https://0xjet.github.io/3OHA/2026/02/12/post.html) describes the design of `tuxid`, the signal catalog, and an evaluation of the estimated entropy and stability of each signal.

---

## Features

* **Permission-Aware:** Automatically detects if it is running as `root` or a `local user`. Sensitive signals (like Main Board Serial or UUID) are only collected if sufficient permissions are available.
* **Customizable Hashing:** Supports any system hash utility (e.g., `sha256sum`, `md5sum`, `sha1sum`).
* **Output Modes:** Toggle between raw data visibility and privacy-focused hashed outputs.
* **Suite Support:** Allows the use of a specific software suite path to handle UNIX commands, ensuring compatibility in restricted or custom environments.
* **JSON Output:** Generates structured data ready for programmatic consumption.

---

## Requirements

* **Shell:** POSIX-compliant shell (`sh`, `bash`, `zsh`).
* **Utilities:** `sed`, `grep`, `tail`, `head`, `cut`, `paste`, `blkid`, `uniq`, `printf`.
* **Network:** `curl` or `nc` (netcat) for public IP retrieval.

---

## Usage

### Basic Syntax
```bash
sh tuxid.sh [OPTIONS]
```

### Options
* `--output <raw | private | both>`
    * `raw`: Shows the actual signal values.
    * `private`: (Default) Shows only the hashes of individual signals to protect privacy.
    * `both`: Displays both the raw value and the resulting hash for every signal.
* `--hash <command>`
    * Specify the hashing algorithm. Defaults to `sha1sum`. Commonly used: `sha256sum`, `md5sum`.
* `--suite <path>`
    * Path to the software suite to handle unix/linux commands (e.g., `/path/to/bin/`).

---

### Examples

1. Generate a privacy-focused fingerprint (default):

```bash
sh tuxid.sh --output private --hash sha256sum
```

2. Generate a full report showing raw data and hashes
```bash
sh tuxid.sh --output both
```

3. Run using a specific tool suite path
```bash
sh tuxid.sh --suite "/usr/local/custom_bin/"
```

---

## JSON Output Example

Example of a structured response in `private` mode:

```json
{
  "hardware_signals": {
    "Device Model": "722f47c36a...",
    "Device Vendor": "88e239a11c...",
    "Storage Devices UUIDs": "3b2a5c..."
  },
  "software_signals": {
    "Machine ID": "5d41402abc..."
  },
  "fingerprint_hash": {
    "hash_digest": "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3",
    "hash_algorithm": "sha1sum"
  }
}
```

