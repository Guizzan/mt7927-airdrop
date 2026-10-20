# mt7927-airdrop

AirDrop between Linux and iPhones/Macs on a **MediaTek MT7927** Wi-Fi card (also `mt7925e`), built on [omdrop-owl](https://github.com/t4t5/omdrop-owl) and [omdrop](https://github.com/netmojo-systems/omdrop-plugin).

Measured on MT7927 (kernel 7.2.9): iPhone → PC **~7 MB/s**, Mac → PC **~10 MB/s**, PC → iPhone ~1.6 MB/s. Upstream omdrop-owl on this card: a few kB/s.

## What's fixed

- **Driver (`mt7925e`)**: the sniffer was never told its channel when an AP or station owned it, so the card heard nothing (or never ACKed). Adds a debugfs hook to start a firmware RX Block Ack session for an AWDL peer.
- **OWL**: runs a hook on ADDBA that adds the peer as a station on a hidden AP and starts the hardware Block Ack; advertises 2-stream HT and VHT like a Mac does (the peer then sends VHT MCS 9, 80 MHz).
- **omdrop-owl helper**: hidden-AP cell can be VHT80; channel, strategy and extra OWL arguments are configurable.
- **Receiver**: asks before accepting (Accept/Decline notification).
- **App**: `airdrop-app`, a GTK window to pick files and a nearby device. Plus a Files (Nautilus) "Send with AirDrop" menu item.

## Install (Arch)

```sh
cd packaging/mt7925-awdl-dkms && makepkg -si
cd ../omdrop-owl-mt7927 && makepkg -si      # replaces omdrop-owl
git clone https://github.com/netmojo-systems/omdrop-plugin ~/.local/share/omdrop-plugin
git -C ~/.local/share/omdrop-plugin apply "$PWD/../../patches/airdrop-serve-confirm.patch"
~/.local/share/omdrop-plugin/bin/omdrop setup
```

Set a regulatory domain (5 GHz is needed), e.g. `WIRELESS_REGDOM="US"` in `/etc/conf.d/wireless-regdom`, then reboot. The DKMS module fetches the matching mt76 source from kernel.org on each kernel update; if that fails the stock driver stays.

## Use

Open **AirDrop** (`airdrop-app`), drop or choose files, pick a device, Send. The other device must have AirDrop set to **Everyone**. Received files go to `~/Downloads` (set `download_dir` in `~/.config/airdrop/config.toml`); `confirm = false` there accepts without asking.

`extras/ml4w-statusbar` adds a drop-target icon to the ML4W Quickshell bar.

## Licenses

Driver patch: BSD-3-Clause-Clear (as mt76). OWL patch: GPL-3.0-or-later. omdrop patches: as upstream. App and tools: GPL-3.0-or-later.
