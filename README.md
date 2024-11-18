# linid
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

(Start working here.)

Signal 1: 

