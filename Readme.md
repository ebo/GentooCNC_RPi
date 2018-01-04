# Readme

## Overview

This is a fork of the GentooCNC overlay at https://sourceforge.net/projects/gentoocnc/
I wanted to be able to tweak some of the versions available, and use it via layman which currently isn't possible with the original repo.

## Setup via layman

To install the overlays using layman
```
layman -o https://raw.github.com/CNC-Nidehog/GentooCNC/master/repositories.xml -f -a GentooCNC
emerge --sync
```


## Setup via Local overlays

  * [Gentoo Wiki](http://wiki.gentoo.org/wiki/Layman#Adding_custom_overlays)
  * [Local overlays](https://wiki.gentoo.org/wiki/Overlay/Local_overlay) should be managed via `/etc/portage/repos.conf/`.
  * To enable this overlay make sure you are using a recent Portage version (at least `2.2.14`)
  * Create a `/etc/portage/repos.conf/GentooCNC.conf` file containing:

```
[GentooCNC]
location = /usr/local/portage/GentooCNC
sync-type = git
sync-uri = https://github.com/CNC-Nidehog/GentooCNC.git
priority=9999
```

Afterwards, simply run `emerge --sync`, and Portage should then pull in all the ebuilds.


## Use Flags

There are two use flags to be aware of:

  * rtapi - builds LinuxCNC with hard-realtime suppport
  * simulator - build using POSIX threads, no realtime at all

If you're trying to get machinekit to emerge, then I'd recommend turning on the tk use flag globally
then looking at the example portage configuration files under exampleconfigs/ for unmasking packages and enabling use flags.
These are a copy from my own system under /etc/portage/
I've found that enabling as much as possible for the use flags for machinekit seems to increase the odds it will compile.

