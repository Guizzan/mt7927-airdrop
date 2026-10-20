#!/bin/bash
# Fetch drivers/net/wireless/mediatek/mt76 for KERNELVER (sparse git clone of
# the stable tree) and apply mt7925-awdl.patch. Run by DKMS in the build dir.
set -euo pipefail
kver=${1:?kernel version}
base=${kver%%-*}                       # 7.2.9-arch1-1 -> 7.2.9
tag=v${base%.0}                        # 7.3.0 -> v7.3
rm -rf ksrc
echo "mt7925-awdl: fetching mt76 for $tag"
git clone -q --depth 1 --filter=blob:none --sparse -b "$tag" \
    https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git ksrc 2>/dev/null
git -C ksrc sparse-checkout set drivers/net/wireless/mediatek/mt76
patch -p1 -d ksrc --forward --no-backup-if-mismatch < mt7925-awdl.patch
