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
| **Signal**                            | **Estimated Lifetime**    | **User Resettable** 	| **Field Length (in bits)**                | **Read Privileges** 	| **Reset Privileges** 	    | **Method**                                                                            |
|--------------------------------------	|--------------------	    |-----------------	    |-------------------	                    |-----------------	    |------------------	        |-------------------------------------------------------------------------------------	|
| Device Model                         	| permanent             	| No               	    | 3–5 bits                                  | local           	    | manufacturer    	        | cat /sys/devices/virtual/dmi/id/product_name                                        	|
| Device Vendor                        	| permanent          	    | No               	    | 3–5 bits                                  | local           	    | manufacturer   	        | cat /sys/devices/virtual/dmi/id/sys_vendor                                          	|
| Main Board Product UUID              	| permanent          	    | No            	    | 128 bits                                  | local root      	    | local root       	        | cat /sys/devices/virtual/dmi/id/product_uuid                                        	|
| Main Board Product Serial            	| permanent          	    | No               	    | 32–64 bits                                | local root      	    | manufacturer    	        | cat /sys/devices/virtual/dmi/id/board_serial                                        	|
| Storage Devices UUIDs                	| permanent           	    | Yes             	    | 128 bits per UUID                         | local           	    | local           	        | ls -A /dev/disk/by-uuid/ \|\| lsblk -o UUID \|\| blkid \| grep 'UUID='                |
| Processor Model Name (CPU)           	| permanent          	    | No               	    | 5 bits                                    | local           	    | manufacturer              | { grep 'Processor' /proc/cpuinfo; grep 'model name' /proc/cpuinfo; } | uniq           |
| Total Memory (RAM)                   	| permanent          	    | No              	    | depends on hw (16GB (in kB): 24 bits)     | local           	    | physical                  | cat /proc/meminfo \| grep "^MemTotal: " \| cut -d':' -f2- \| tr -d ' '                |
| Root Filesystem Total Disk Space     	| permanent          	    | Yes              	    | depends on hw (5TB (in kB): 42 bits)      | local                 | local root, physical      | df \| tail -n +2 \| tr -s ' ' \| cut -d' ' -f2 \| awk '{s+=\$1} END {print s}'        |

### Software Signals
| **Signal**        | **Estimated Lifetime**    | **User Resettable** 	| **Field length (in bits)**            | **Read Privileges**   | **Reset Privileges** 	                    | **Method**                            |
|---------------    |--------------------	    |-----------------	    |-------------------	                |-----------------	    |------------------	                        |---------------------------------      |
| Machine-id        | Permanent (until reset)   | Yes                   | 128 bits                              | local                 | local root                                | cat /etc/machine-id                   |
| Device hostid     | Permanent (until reset)   | Yes                   | 32 bits                               | local                 | local root                                | hostid                                |
| Hostname          | Permanent (until reset)   | Yes                   | 8-2024 bits (1-253 chars)             | local                 | local (temporary), local root (permanent) | echo $HOSTNAME \|\| hostname          |
| Random Boot UUID  | Volatile (per boot)       | No                    | 128 bits                              | local                 | not resettable (generated at boot)        | cat /proc/sys/kernel/random/boot_id   |

### Network-related Signals
| **Signal**                | **Estimated Lifetime**                            | **User Resettable** 	| **Field Length (in bits)** 	                | **Read Privileges** 	| **Reset Privileges** 	               | **Method**        |
|----------------------     |---------------------------------------------	    |-----------------	    |------------------------------------	        |-----------------	    |------------------	                   |---------------    |
| IP Address                | Volatile (Dynamic IP) or Permanent (Static IP)    | Yes                   | 32 bits (IPv4), 128 bits (IPv6)               | local                 | local (Dynamic), local root (Static) | ip addr show $iface \| grep 'inet ' |
| MAC Address               | Permanent                                         | Yes                   | 24 bits                                       | local / local root    | local root                           | ip link \| grep -A 1 " $iface:" \|\| cat /sys/class/net/$iface/address |
| Main Network Interface    | Permanent                                         | No                    | 16-504 bits (Gen. 16(lo)-120(enp3s0) bits)    | local                 | local root                           | echo $iface |

### Operating System (OS) Signals
| **Signal**            | **Estimated Lifetime**    | **User Resettable** 	| **Field Length (in bits)**                                | **Read Privileges** 	| **Reset Privileges** 	                        | **Method**            |
|---------------------- |-----------------------    |-----------------	    |------------------	                                        |---------------        |---------------------                          |---------------        |
| OS Locale Settings    | Volatile                  | Yes                   | variable (Gen. 40-128 w/o modifiers, e.g. en_US.UTF-8)    | local                 | local (per session), local root (system-wide) | cat /etc/locale.conf \| grep "^LANG=" |
| Kernel Version        | Permanent                 | No (updatable)        | variable (Gen. 160-400 bits, e.g. 5.4.0-42-generic)       | local                 | local root (by update)                        | cat /proc/sys/kernel/osrelease    |
| OS Version            | Permanent                 | No (updatable)        | variable (Gen. 160-800 bits, e.g. Ubuntu 20.04.3 LTS)     | local                 | local root (by update)                        | cat /etc/os-release \| grep "^PRETTY_NAME="   |
| Last boot time        | Volatile                  | No (updatable)        | 152 bits                                                  | local                 | local root (by reboot)                        | grep btime /proc/stat (also uptime -s, who -m) |

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
* https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html
* https://man7.org/linux/man-pages/man5/proc_stat.5.html

