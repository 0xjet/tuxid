# tuxid
A Linux fingerprinting tool

## Methodology

1. Collect a number of signals that collectively identify uniquely a Linux box. Those signals are typically unique serial numbers and other permanent artefacts. Follow this process:
    1. Run searches for terms like "linux id", "unique linux identifier", "uuid in linux", "device identifier linux", etc. Read system and developer forums where this topic is discussed
    2. For each identified signal, take note of the following features:
        1. It's estimated lifetime (e.g., volatile or permanent)
        2. If it's reseteable by the user
        3. Estimated entropy, or how unique it could be within a population (it could be useful in conjunction with other signals)
        4. Privileges required to obtain the signal
        5. Privileges required to reset the signal
        6. How to obtain the signal (command line, system call, etc)
    3. Once you have a small collection of signals, try to come up with a classification. For example, hardware signals, OS signals, network-related signals, etc. Using this taxonomy, organize your collection of signals into a catalog.
2. Build a tool that generates a unique fingerprint using available (possibly not all in your catalog) signals.
3. Evaluation:
    1. Run some tests on different devices: typical linux distros, Android phones, maybe some IoT device with a Linux-based ROM.
    2. Test it in the wild with voluntary participants to determine accuracy etc.

## Signal Catalog

### Hardware Signals
| **Signal**                            | **Estimated Lifetime**    | **User Resettable** 	| **Estimated Entropy**     | **Read Privileges** 	| **Reset Privileges** 	    | **Method**                                                                            |
|--------------------------------------	|--------------------	    |-----------------	    |-------------------	    |-----------------	    |------------------	        |-------------------------------------------------------------------------------------	|
| Device Model                         	| permanent             	| No               	    | Very Low (3–5 bits)       | local           	    | manufacturer    	        | cat /sys/devices/virtual/dmi/id/product_name                                        	|
| Device Vendor                        	| permanent          	    | No               	    | Very Low (3–5 bits)       | local           	    | manufacturer   	        | cat /sys/devices/virtual/dmi/id/sys_vendor                                          	|
| Main Board Product UUID              	| permanent          	    | No (bios?)     	    | High (128 bits)           | local root      	    | local root       	        | cat /sys/devices/virtual/dmi/id/product_uuid                                        	|
| Main Board Product Serial            	| permanent          	    | No               	    | Moderate (32–64 bits)     | local root      	    | manufacturer    	        | cat /sys/devices/virtual/dmi/id/board_serial                                        	|
| Storage Devices UUIDs                	| permanent           	    | Yes             	    | High (128 bits per UUID)  | local           	    | local           	        | ls /dev/disk/by-uuid                                                                	|
| Processor Model Name (CPU)           	| permanent          	    | No               	    | Low (~5 bits)             | local           	    | manufacturer              | cat /proc/cpuinfo  \| grep 'model name' \| cut -d':' -f2- \| uniq \| tr -d ' '        |
| Total Memory (RAM)                   	| permanent          	    | No              	    | Moderate (10–15 bits)     | local           	    | physical                  | cat /proc/meminfo \| grep "MemTotal: " \| cut -d':' -f2- \| tr -d ' '                 |
| Available Memory (RAM)               	| volatile           	    | Yes              	    | Moderate (10–15 bits)     | local           	    | local            	        | cat /proc/meminfo \| grep "MemFree: " \| cut -d':' -f2- \| tr -d ' '                	|
| Cached Memory (RAM)                  	| volatile           	    | Yes              	    | Moderate (10–15 bits)     | local           	    | local            	        | cat /proc/meminfo \| grep "^Cached: " \| cut -d':' -f2- \| tr -d ' '                	|
| Root Filesystem Total Disk Space     	| permanent          	    | Yes              	    | Moderate (10–15 bits)     | local                 | local root, physical      | df -h \| grep \\/$ \| tr -s ' ' \| cut -d' ' -f2                                      |

### Software Signals
| **Signal**        | **Estimated Lifetime**    | **User Resettable** 	| **Estimated Entropy** | **Read Privileges**   | **Reset Privileges** 	                    | **Method**                            |
|---------------    |--------------------	    |-----------------	    |-------------------	|-----------------	    |------------------	                        |---------------------------------      |
| machine-id        | Permanent (until reset)   | Yes                   | High (128 bits)       | User                  | local root                                | cat /etc/machine-id                   |
| device hostid     | Permanent (until reset)   | Yes                   | Low (32 bits)         | User                  | local root                                | hostid                                |
| hostname          | Permanent (until reset)   | Yes                   | Low (user choice)     | User                  | local (temporary), local root (permanent) | hostname                              |
| random boot UUID  | Volatile (per boot)       | No                    | High (128 bits)       | User                  | not resettable (generated at boot)        | cat /proc/sys/kernel/random/boot_id   |

### Network-related Signals
| **Signal**                | **Estimated Lifetime**                            | **User Resettable** 	| **Estimated Entropy** 	            | **Read Privileges** 	| **Reset Privileges** 	    | **Method**        |
|----------------------     |---------------------------------------------	    |-----------------	    |------------------------------------	|-----------------	    |------------------	        |---------------    |
| IP Address                | Volatile (Dynamic IP) or Permanent (Static IP)    | Yes                   | Medium (32 bits IPv4, 128 bits IPv6)  | User                  | local (Dynamic), local root (Static) | ip route get 1.0.0.0 \| head -n 1 \| cut -d' ' -f7 |
| MAC Address               | Permanent                                         | Yes                   | Low (24 bits)                         | User                  | local root    | cat /sys/class/net/$iface/address |
| Main Network Interface    | Permanent                                         | No                    | Low (6-10 bits; predictable)          | User                  | local root    | route \| grep default \| tr -s ' ' \| cut -d' ' -f8   |

### Operating System (OS) Signals
| **Signal**            | **Estimated Lifetime**    | **User Resettable** 	| **Estimated Entropy** | **Read Privileges** 	| **Reset Privileges** 	                        | **Method**            |
|---------------------- |-----------------------    |-----------------	    |------------------	    |---------------        |---------------------                          |---------------        |
| OS Locale Settings    | Volatile                  | Yes                   | Low (5–10 bits)       | local                 | local (per session), local root (system-wide) | cat /etc/locale.conf \| grep "^LANG=" \| cut -d'=' -f2-    |
| Kernel Version        | Permanent                 | No (updatable)        | Low (10–15 bits)      | local                 | local root (by update)                        | cat /proc/version \| cut -d' ' -f3 |
| OS Version            | Permanent                 | No (updatable)        | Low (10–15 bits)      | local                 | local root (by update)                        | cat /etc/os-release \| grep "^PRETTY_NAME=" \| cut -d'"' -f2   |
| Last boot time        | Volatile                  | No (updatable)        | Low (10–15 bits)      | local                 | local root (by reboot)                        | uptime -s (many others)  |

## References

(Write all references and links you use)

* http://0pointer.de/blog/projects/ids.html
* https://gist.github.com/bencord0/7690953
* https://stackoverflow.com/questions/328936/getting-a-unique-id-from-a-unix-like-system/344656#344656
* https://www.ibm.com/docs/en/aix/7.1?topic=h-hostid-command
* https://www.makeuseof.com/serial-number-linux-pc-how-to-find/
* https://unix.stackexchange.com/questions/14961/how-to-find-out-which-interface-am-i-using-for-connecting-to-the-internet
* https://www.oreilly.com/library/view/virtual-private-networks/1565925297/ch01s05.html
* https://docs.oracle.com/cd/E26921_01/html/E25809/spmonitor-6.html
* https://www.sciencedirect.com/topics/engineering/shannon-entropy
* https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.entropy.html
* https://www.cybrary.it/blog/beginners-guide-entropy
* https://cs.stackexchange.com/questions/117217/in-information-theory-why-is-the-entropy-measured-in-units-of-bits
* https://medium.com/@sp00ky/bits-of-security-understanding-password-entropy-cb083888f57e
* https://askubuntu.com/questions/659953/what-is-ubuntus-automatic-uid-generation-behavior

