# Device Signal State Comparison: Availability and Permissions Across Multiple Devices
This document shows whether and under what circumstances the signals present in the
signal catalogue can or cannot be obtained from an Android device.

A total of 4 Android devices have been tested so far.

## Android Build Fingerprint
To define exactly which devices have been tested, you will find below a table showing the
build fingerprint (property: `ro.build.fingerprint`) for each device.

* OnePlus Nord CE 3 Lite 5G (CPH2465): OnePlus/CPH2465/OP5958L1:15/UKQ1.230924.001/T.R4T2.1bef304_1-5135:user/release-keys
* Samsung Galaxy Tab A7 Lite (SM-T220): samsung/gta7litewifieea/gta7litewifi:11/RP1A.200720.012/T220XXU1AVB2:user/release-keys
* Samsung Galaxy Tab A (SM-T290): samsung/gtowifieea/gtowifi:11/RP1A.200720.012/T290XXS5CWG5:user/release-keys
* Meizu 16Xs (M926H): meizu/meizu_16Xs/meizu16Xs:9/PKQ1.190302.001/1560830588:user/release-keys

## Signal Catalog
Three different cases are considered:
- SIGNAL_NOT_AVAILABLE: command(s)/file(s)/attribute(s) used to obtain the signal don't exist.
    * Typically this refers to files such as /etc/machine-id not being present on
    the device.
- SIGNAL_AVAILABLE: command(s)/file(s)/attribute(s) exists and can be accessed without needing
additional permissions.
    * In this case, the signal value can be obtained successfully.
- PERMISSION_DENIED: command(s)/file(s)/attribute(s) exists, but permissions block access.
    * i.e. the app doesn't have the necessary permissions, such as for GPS,
    network access, or other protected system features.


### Hardware Signals
| **Signal**                            | **OnePlus (CPH2465)** | **Samsung A7 Lite (SM-T220)** | **Samsung A (SM-T290)** | **Meizu (M926H)**       |
|----------------------	                |----------------       |---------------                |----------------         |--------------           |
| Device Model                         	| SIGNAL_NOT_AVAILABLE  | SIGNAL_NOT_AVAILABLE          | SIGNAL_NOT_AVAILABLE    | SIGNAL_NOT_AVAILABLE    |
| Device Vendor                        	| SIGNAL_NOT_AVAILABLE  | SIGNAL_NOT_AVAILABLE          | SIGNAL_NOT_AVAILABLE    | SIGNAL_NOT_AVAILABLE    |
| Main Board Product UUID              	| SIGNAL_NOT_AVAILABLE  | SIGNAL_NOT_AVAILABLE          | SIGNAL_NOT_AVAILABLE    | SIGNAL_NOT_AVAILABLE    |
| Main Board Product Serial            	| SIGNAL_NOT_AVAILABLE  | SIGNAL_NOT_AVAILABLE          | SIGNAL_NOT_AVAILABLE    | SIGNAL_NOT_AVAILABLE    |
| Storage Devices UUIDs                	| SIGNAL_NOT_AVAILABLE  | SIGNAL_NOT_AVAILABLE          | SIGNAL_NOT_AVAILABLE    | SIGNAL_NOT_AVAILABLE    |
| Processor Model Name (CPU)           	| SIGNAL_NOT_AVAILABLE  | SIGNAL_NOT_AVAILABLE          | SIGNAL_AVAILABLE        | SIGNAL_AVAILABLE        |
| Total Memory (RAM)                   	| SIGNAL_AVAILABLE      | SIGNAL_AVAILABLE              | SIGNAL_AVAILABLE        | SIGNAL_AVAILABLE        |
| Root Filesystem Total Disk Space     	| SIGNAL_AVAILABLE      | SIGNAL_AVAILABLE              | SIGNAL_AVAILABLE        | SIGNAL_AVAILABLE        |

### Software Signals
| **Signal**             | **OnePlus (CPH2465)** | **Samsung A7 Lite (SM-T220)** | **Samsung A (SM-T290)** | **Meizu (M926H)**      |
|----------------------	 |----------------       |---------------                |----------------         |------------------      |
| Machine-id             | SIGNAL_NOT_AVAILABLE  | SIGNAL_NOT_AVAILABLE          | SIGNAL_NOT_AVAILABLE    | SIGNAL_NOT_AVAILABLE   |
| Device hostid          | SIGNAL_NOT_AVAILABLE  | SIGNAL_NOT_AVAILABLE          | SIGNAL_NOT_AVAILABLE    | SIGNAL_NOT_AVAILABLE   |
| Hostname               | SIGNAL_AVAILABLE      | SIGNAL_AVAILABLE              | SIGNAL_AVAILABLE        | SIGNAL_AVAILABLE       |
| Random Boot UUID       | SIGNAL_AVAILABLE      | SIGNAL_AVAILABLE              | SIGNAL_AVAILABLE        | SIGNAL_AVAILABLE       |

### Network-related Signals
| **Signal**             | **OnePlus (CPH2465)** | **Samsung A7 Lite (SM-T220)** | **Samsung A (SM-T290)** | **Meizu (M926H)**      |
|----------------------	 |----------------       |---------------                |----------------         |------------------      |
| Private IP Address     | PERMISSION_DENIED (*) | PERMISSION_DENIED (*)         | PERMISSION_DENIED (*)   | SIGNAL_AVAILABLE       |
| MAC Address            | PERMISSION_DENIED (*) | PERMISSION_DENIED (*)         | PERMISSION_DENIED (*)   | SIGNAL_AVAILABLE       |
| Main Network Interface | PERMISSION_DENIED (*) | PERMISSION_DENIED (*)         | PERMISSION_DENIED (*)   | SIGNAL_AVAILABLE       |

* **(*)** Root Permissions needed
    * Error Message: `Error: Cannot bind netlink socket: Permission denied`

### Operating System (OS) Signals
| **Signal**            | **OnePlus (CPH2465)** | **Samsung A7 Lite (SM-T220)** | **Samsung A (SM-T290)** | **Meizu (M926H)**       |
|----------------------	|----------------       |---------------                |----------------         |------------------       |
| OS Locale Settings    | SIGNAL_NOT_AVAILABLE  | SIGNAL_NOT_AVAILABLE          | SIGNAL_NOT_AVAILABLE    | SIGNAL_NOT_AVAILABLE    |
| Kernel Version        | SIGNAL_NOT_AVAILABLE  | PERMISSION_DENIED             | SIGNAL_NOT_AVAILABLE    | PERMISSION_DENIED       |
| OS Version            | PERMISSION_DENIED     | SIGNAL_NOT_AVAILABLE          | SIGNAL_NOT_AVAILABLE    | SIGNAL_NOT_AVAILABLE    |
| Last boot time        | SIGNAL_AVAILABLE      | SIGNAL_AVAILABLE              | SIGNAL_AVAILABLE        | PERMISSION_DENIED       |


