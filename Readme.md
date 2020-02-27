# Readme

## Overview

This is a fork of CNC-Nidehog's GentooCNC overlay
(https://github.com/CNC-Nidehog/GentooCNC) which itself was a fork of
an earlier SourceForge effort
(https://sourceforge.net/projects/gentoocnc/).  This fork is intended
to bring the original GentooCNC up to date, with a current emphasis on
supporting the Raspberry Pi ecosystem.

## Setup via layman

To install the overlays using layman
```
layman -o https://raw.github.com/ebo/GentooCNC_RPi/master/repositories.xml -f -a GentooCNC_RPi

emerge --sync
```


## Setup via Local overlays

  * [Gentoo Wiki](http://wiki.gentoo.org/wiki/Layman#Adding_custom_overlays)
  * [Local overlays](https://wiki.gentoo.org/wiki/Overlay/Local_overlay) should be managed via `/etc/portage/repos.conf/`.
  * To enable this overlay make sure you are using a recent Portage version (at least `2.2.14`)
  * Create a `/etc/portage/repos.conf/GentooCNC_RPi.conf` file containing:

```
[GentooCNC_RPi]
location = /usr/local/portage/GentooCNC_RPi
sync-type = git
sync-uri = https://github.com/ebo/GentooCNC_RPi.git
priority=9999
```

Afterwards, simply run `emerge --sync`, and Portage should then pull in all the ebuilds.


## Use Flags

There are two use flags to be aware of:

  * rtapi - builds LinuxCNC with hard-realtime support
  * simulator - build using POSIX threads, no realtime at all

If you're trying to get machinekit to emerge, then I'd recommend turning on the tk use flag globally
then looking at the example portage configuration files under exampleconfigs/ for unmasking packages and enabling use flags.
These are a copy from my own system under /etc/portage/
I've found that enabling as much as possible for the use flags for machinekit seems to increase the odds it will compile.

