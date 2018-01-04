# Readme

## Overview

This is a fork of the GentooCNC overlay at https://sourceforge.net/projects/gentoocnc/
I wanted to be able to tweak some of the versions available, and use it via layman which currently isn't possible with the original repo.

## Setup via layman

To install the overlays using layman
```
layman -o https://raw.github.com//CNC-Nidehog/GentooCNC/master/repositories.xml -f -a GentooCNC
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

