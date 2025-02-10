## LIST OF ABBREVIATIONS
- IP: Internet Protocol
- GNU: GNU's not UNIX
- MAC: Media Access Control Address
- GDPR: General Data Protection Regulation
- CCPA: California Consumer Privacy Act
- OS: Operating System
- POSIX: Portable Operating System Interface
- IEEE SA: Institute of Electrical and Electronics Engineers Standards Association

## INTRODUCTION

### Motivation
In today's digital world, where people and digital systems behave as one, and which paths
are thereby intrinsically interconnected, identity is a term which might have been subverted, and
which definition might have been completely altered. A person's identity is no longer linked just to its
biometric values, such as its facial features, voice, eyes, name and surnames, or even its DNA,
and considerably more important, its fingerprint, or to the traditional methods mankind have used
to assure someones identity, namely a signature, an identifiable document (e.g., passport, DNI,
driving license) or an identification code, but to those technological devices with which it
communicates, search and exchange information, and presumably make use of to complete every day tasks.

In this context, the term fingerprint presents vast importance and different meanings. Originally,
the term fingerprint comes from the concatenation of the words finger and print, and it references
the impressions or marks made by someone's fingertips when these enter in contact with a medium
that leaves a trace on its surface.

Since ancient times, these fingerprints have been used as a method to verify someone's identity [1],
by documenting the traces a person's fingertips leave behing when entering in contact with another
object. Eventhough at first sight this may seem unrelated to how digital systems and devices
behave, the reality is every device is composed by vast amounts of information, some of which
may or may not be unique and may not be enough to differentiate itself from every other device
on the planet, such as an IP address, which is nothing more than a reference used by devices to
communicate with each other on a network, differentiating themselves from each other.

However if more than one characteristics are read from a device and stored as a whole, it might
be possible to uniquely identify a specific device with an elevated degree of reliability, such as
a traditional fingerprint is capable of uniquely identifying a specific person among all people on
the world with an unmeasurable probability of success.

If this is the case, just as it happens with biometric fingerprints, a device fingerprint, which is
nothing more than a unique representation or identifier of device that can uniquely identify itself
on a collection of devices (e.g. a network), may then be applied to a wide range of disciplines
that would use it as a reliable method of identification and source of information, to accomplish
its objectives.

Therefore, a device fingerprinting solution such as tuxid, could potentially be applied to other
areas of investigation or projects that could benefit from an unique or partial representation or
fingerprint of an accesible system. Several areas of interest for the use of tuxid might be, but
not limited to: [to be completed]

### Objectives (Hypothesis)
This chapter will define the target objectives of this paper, what current challenges will it focus on, what
foundational hypothesis does this paper stands on, what steps will be taken to compile meaningful and
representative results and how will these results be approach when presenting the findings to the reader.
It will also attempt to clear any doubts that may arise to the reader while reading the present document. 

Foremost, the first goal of this project is to design and develop a fingerprinting solution for GNU/Linux
systems, call tuxid, which generates a unique identification for the local system it is executed on,
meaning this solution could be referred to as a local device fingerprinting utility.

However, this paper aims, not only at providing a fingerprinting capability, but to research which characteristics
of a system and to which extend (e.g. establish a representative value within a percentage notation) can they
uniquely identify itself within a specific group. This characteristics of a system or device will be referred to
as system signals or device signals from now on.

The main hypothesis on which the present document is built on is the fact that a relatively small number of
signals (e.g. IP address, MAC address, device name) can potentially and with a high probability uniquely
identify a device. To illustrate this, the developed script will be tested on a relatively small number of
devices, eventhough they will be heterogeneous in nature, that is to say they will present different architectures,
GNU/Linux distributions, vendors, hardware and software capabilities.

Consequently, the percentage of uniqueness for each of the device signals taken into consideration will be
measured, which will demostrate how impactful would that specific signal be (compared to the rest of the
signals) when attempting to uniquely identify a GNU/Linux system. In simple words, the bigger the percentage
of uniqueness is, the lower is the posibility of encountering another device holding the same signal value as
the former.

[Testing: Explain the usage of web and android applications]

In summary, the objective of this project is to develop a device fingerprinting solution that
generates a unique identification of a GNU/Linux system based on all available signals present
on the system and taken into account by the tool, which in a high percentage of scenarios would
be able to successfully uniquely identify a GNU/Linux device.

Aditionally, the solution offered would be non-removable, persistent and resistant to evasion,
meaning the signals taken into account should not permit its modification by the user, the
device must continuously be able to be recognizable over time and the solution would withstand
any attempt aimed at spoofing the device's identity.

Ultimately, evidence gathered and conclusions taken might serve the purpose of supporting future
projects that depend on or make use of a device fingerprinting tool, irrespectively of their
target area of investigation (e.g. cross-device tracking, user identification, fraud prevention,
personalized advertising, analytics and user experience).

### Research Methodology
...

### Regulatory framework
As most cyber cybersecurity disciplines, fingerprinting a device may could potentially intrude into
privacy issues and therefore ensuring compliance with privacy regulations might be a requirement
when making use of a fingerprinting solution such as the one presented in the present paper.

For the reader's information, in the following section, the GDPR (General Data Protection Regulation)
privacy-concerning regulation [and CCPA (California Consumer Privacy Act)] will be discussed,
in terms of legal responsibilities and contractual obligations that may arise from the
distribution and usage of a fingerprintig tool like tuxid. It should also establish clear gudeilines on how and
on which aspects this tool does or does not falls under the scope of such regulations.

As a spefic remark, it should be understood that the fingeprinint solution presented in this
paper does not mean to comply with these regulations and that its purpose is merely academical.

#### GDPR
The General Data Protection Regulation aims to protect the right of the people to protect their
personal data [2, Recital 1, p. 1]. Its scope extends globally, and it applies to data process
from citizens of the European Union, regardless of where that data is being processed [2, Article 3, pp. 32-33].

In the context of the present paper, processing data from devices falls under the scope of the
GDPR, as it specifically states: "Natural persons may be associated with online identifiers provided by their devices, applications, tools and
protocol" [2, Recital 30, p. 6].

Moreover, GDPR recognizes that unique data values that may uniquely identify a device, and because of its association
with its owner, may also directly or indirectly uniquely identify a natural person: "This may leave
traces which, in particular when combined with unique identifiers and other information received
by the servers, may be used to create profiles of the natural persons and identify them" [2, Recital 30, p. 6].

For this reason, users of the fingerprinting solution designed in this paper, considered by the GDPR
as data controllers, are subjects to and must follow all the principles stated by the GDPR, the most
relevant of them being: principles in relation to the processing of personal data [2, Article 5, pp. 35-36],
specific conditions for consent [2, Article 7, 8, pp. 37-38], and the data treatment concept [2, Articles 5, 6, pp. 35-37].

As so, pseudoanymised data (e.g. hash digest) is also covert by the GDPR.  GDPR defines pseudoanymised
data as data that has been processed in an specific way in order for it not to be solely enough to
identify a person, and that any additional data that can be used in conjuction to successfully identify
that person is stored independently [2, Article 4(5), p. 33].

For this matter, and also taking into account that given that the fingerprinting solution introduced
in the present document offers the ability to obtain data from a device, in either raw or hashed formats,
and that the selection of the hash algorithm used to do so falls exclusively on the user of the solution,
this hashing process does not succesfully achieve pseudonymisation as understood by the GDPR,
as data collected is not kept apart in such a way that it cannot solely be used to identify individuals.

This is due to the nature of this solution, which is to uniquely identify a device, meaning that every hashed
signal value, serves the purpose of potentially identifying it, such as a fingerprint does.

In summary, in relation with the GDPR, the fingerprinting solution presented in this paper,
could be used to uniquely identify a device if done for legitimate purposes, as long as it
adheres to the data protection principles defined by the GDPR.

### Document Structure

## State of the Art
As it has been stated in previous sections, ...

### Related Work/Research Areas
- **Remote Device Fingerprinting**:
- **OS Fingerprinting**:
    * **Passive Fingerprinting**:
    * **Active Fingerprinting**:
    * **Advance Passing Fingerprinting**:
- **TCP/IP Fingerprinting**:
- **Browser Fingerprinting**:
- **Cross Device Tracking**:
- **Fraud Prevention**:
- **ProfilIoT**: some efforts have been made in an effort of identifying devices
leveraging network traffic analysis
- **Vulnerability Fingerprint**: VFDETECT and VULDEFF, VulDeePecker

## STANDARDS AND REQUIREMENTS
### Tools and Technologies
### POSIX Standards
Considering all of the requirements listed above, and in order to be compatible with the widest rage of
GNU/Linux devices, the script should follow common UNIX standards and technologies. Because of this matter,
it has been considered that the developed script should be implemented as a POSIX-compliant shell script.

A POSIX-compliant shell script refers to a script that follows POSIX standards and is expected to
be executed on a POSIX-compliant shell. In this context, POSIX (Portable Operating System Interface)
is a set of standards published by the IEEE SA (Institute of Electrical and Electronics Engineers
Standards Association), aimed at maintaining interoperability between operating systems.

Specifically, the POSIX.1 standard, in its latest revision (POSIX.1-2024 [1]), specifies that
that all systems of the Unix family should provide an standard interface for the user to communicate
with system services and programs, that is to say, an standard shell [1]. The standard describes
this idea as follows: "POSIX.1-2024 defines a standard operating system interface and environment,
including a command interpreter (or 'shell'), and common utility programs to support applications
portability at the source code level" [1, vol. 1, ch. 2, p. 3].

Therefore, a POSIX-compliant shell script should comply, at least, with the "shell command language"
specifications listed in the POSIX.1-2024 standard [1, vol. 3, ch. 2, pp. 2472-2572]. Regarding this
shell or command interpreter, in all UNIX systems, a POSIX-compliant shell can be launched by making
use of the /bin/sh binary, which it is, typically, a symbolic link to either a modern POSIX-compliant
version of the Bourne Shell, such as dash (GNU/Linux), ash (busybox) or ksh, or a modified
version of a non POSIX-compliant shell (e.g., bash shell's POSIX mode [2]).

However, there are still slight variations between shells, even if they comply with the standard.
For this reason, in order to provide completeness, and to establish a common baseline for the project,
the developed script has been tested in all of these different shells: dash, ash, bash with POSIX mode
enabled (i.e., bash --posix), ksh93u+m and mksh.

It should be also noted that in order to verify the developed script attains to the POSIX.1
standard, the shellcheck[] static analysis tool has been leveraged to test the tuxid.sh script
for the presence of non POSIX-compliant features.

> `shellcheck --shell=sh tuxid.sh`

The POSIX.1 standard also defines common standard utilities for users to interact with the system.
This include several common UNIX command line utilities, such as cut, head, tail, grep and sed,
among others. Some of which will be used during the development phase of the scripts presented in
this paper.

#### Software requirements
In the next paragraph the list of UNIX command line utilities that will be used in the development
of each one of the scripts mentioned in this paper will be detailed. This list should establish the
requirements needed to run a script on a GNU/Linux system, given that these scripts are executed
under a POSIX-compliant command interpreter or shell, as detailed in the previous section.

The tuxid.sh script ...

On the other, the tuxid_entropy.sh script ...

* GNU/Linux tools used: `strace -f -e execve sh tuxid.sh 2>&1 |  awk -F'"' '/execve/ {print $2}' | sort -u`

#### Collection of signals
#### Entropy


## DESIGN AND DEVELOPMENT
The purpose of this paper is to develop a tool that uniquely identifies a GNU/Linux system or device,
regardless of its class (e.g., IoT devices, mobile phones, computers, firewalls, routers), hardware
capabilities, vendor, architecture (e.g. ARM, AMD64), GNU/Linux distribution (e.g. Debian, Ubuntu,
Fedora, Red Hat, Gentoo, Arch Linux) or even installed software, although some minimum requirements
should be meet.

### Bash Script
### Shannon Entropy
### Web Application
### Android Application
### Crowdsourcing

## Testing

## RESULTS
## CONCLUSIONS

## References
- Jr. Eric H. Holder, Laurie O. Robinson, and John H. Laub, THE FINGERPRINT SOURCEBOOK. Washington, DC, 2011. Accessed: Jan. 24, 2025. [Online]. Available: https://nij.ojp.gov/library/publications/fingerprint-sourcebook
- European Parliament and the Council of the European Union, “REGULATIONS REGULATION (EU) 2016/679 OF THE EUROPEAN PARLIAMENT AND OF THE COUNCIL of 27 April 2016 on the protection of natural persons with regard to the processing of personal data and on the free movement of such data, and repealing Directive 95/46/EC (General Data Protection Regulation),” Apr. 2016. Accessed: Jan. 28, 2025. [Online]. Available: https://eur-lex.europa.eu/
- California Privacy Protection Agency, “California Consumer Privacy Act Regulations,” Apr. 2024. Accessed: Jan. 28, 2025. [Online]. Available: https://cppa.ca.gov/regulations/pdf/cppa_regs.pdf
- 1003.1-2024 - IEEE/Open Group Standard for Information Technology--Portable Operating System Interface (POSIX) Base Specifications, Issue 8. IEEE, 2024.
- B. Fox and C. Ramey. “bash(1).” Debian Manpages. Accessed: Jan. 23, 2025. [Online]. Available: https://manpages.debian.org/bookworm/bash/bash.1.en.html

## ANEXES
