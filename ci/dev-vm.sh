#!/bin/bash
# dev-vm.sh <data disk>: set up a long-lived build VM for trying changes without a CI run. Run as root
# on the VM, again after every boot (it skips what is done): it mounts the data disk at /work, installs
# the build dependencies, turns on swap, and on the first run syncs the source tree to /work/src and the
# kernel sources to its out-kernel/xiaomi_gold. On Google Cloud, with gcloud and the CI's service
# account, it starts from the bucket's source cache and ccache; elsewhere it syncs everything. It
# builds nothing.
#
# The data disk outlives the VM, so builds after the first are incremental. Build by hand afterwards:
#   cd /work/src && export SKIP_KERNEL_SYNC=1 USE_CCACHE=1 CCACHE_EXEC=/usr/bin/ccache CCACHE_DIR=/work/ccache
#   source build/envsetup.sh && breakfast gold userdebug && m target-files-package otatools
# and sign the target files as CI does, with the release keys on a RAM disk that is unmounted after:
#   bash ci/sign.sh /keys/gold <target files> signed.zip package.zip
# Test builds too are signed with them, so that the test unit takes the same updates as everyone.

set -euo pipefail
BUCKET=gold-build-ci-osaka
W=/work; SRC=$W/src
say() { echo "== $(date +%H:%M:%S) $*"; }

# The data disk, formatted the first time
DEV=$1
GCS=; command -v gcloud > /dev/null && gcloud storage ls gs://$BUCKET/ > /dev/null 2>&1 && GCS=1
mkdir -p $W
if ! mountpoint -q $W; then
  blkid $DEV > /dev/null || mkfs.ext4 -q -m 0 -E lazy_itable_init=0,lazy_journal_init=0 $DEV
  mount -o discard,defaults $DEV $W
fi

say "build dependencies"
if ! command -v repo > /dev/null; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -qq bc bison build-essential ccache curl flex g++-multilib gcc-multilib git git-lfs \
    gnupg gperf imagemagick protobuf-compiler python3-protobuf lib32readline-dev lib32z1-dev libdw-dev \
    libelf-dev lz4 libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool \
    squashfs-tools xsltproc zip zlib1g-dev python-is-python3 zstd age > /dev/null
  curl -sfo /usr/local/bin/repo https://storage.googleapis.com/git-repo-downloads/repo && chmod +x /usr/local/bin/repo
  git config --global user.name Betterr
  git config --global user.email 51264180+Star-caorui@users.noreply.github.com
  git config --global color.ui false
  git lfs install --system > /dev/null
fi

# On the boot disk, which is not on the SSD quota
SWAP=/swapfile
[ -f $SWAP ] || { fallocate -l 32G $SWAP && chmod 600 $SWAP && mkswap -q $SWAP; }
swapon --show | grep -q $SWAP || swapon $SWAP

# Marked only when both syncs went through, so a run that a fetch error stopped syncs again.
if [ ! -f $W/.synced ]; then
  say "sync"
  mkdir -p $SRC && cd $SRC
  # The newest .repo the bucket keeps, as ci/vm-build.sh uses it: then the fetch brings only what changed.
  if [ -n "$GCS" ] && [ ! -d .repo ]; then
    CACHE=$(gcloud storage ls gs://$BUCKET/repo-cache/ | sort | tail -1)
    mkdir .rc && gcloud storage cp "${CACHE}*" .rc/ --quiet
    (cd .rc && grep ' repo\.tar\.' SHA256SUMS | xargs -P $(nproc) -L 1 sh -c 'echo "$0  $1" | sha256sum -c --quiet -')
    cat .rc/repo.tar.* | tar -xf - && rm -rf .rc
  fi
  repo init -q -u https://github.com/LineageOS/android.git -b lineage-24.0 --git-lfs --depth=1
  [ -d .repo/local_manifests ] || git clone -q -b lineage-24.0 https://github.com/Star-caorui/local_manifests .repo/local_manifests
  # googlesource answers RESOURCE_EXHAUSTED to many fetches at once; a second, slower pass picks those up.
  repo sync -c -q -j$(nproc) --no-tags --no-clone-bundle --optimized-fetch --retry-fetches=5 --force-sync ||
    repo sync -c -q -j4 --no-tags --no-clone-bundle --optimized-fetch --retry-fetches=10 --force-sync
  device/xiaomi/gold/patches/apply.sh lineage

  say "kernel sources"
  # As ci/vm-build.sh does: the kernel tree gets its own .repo, or repo init finds the Android tree's.
  KT=out-kernel/xiaomi_gold
  mkdir -p $KT/.repo && touch $KT/.out-dir
  [ -d $KT/.repo/repo ] || cp -R .repo/repo $KT/.repo/repo
  (cd $KT && repo init -q -u https://github.com/Star-caorui/android_kernel_xiaomi_gold_manifest -b lineage-24.0 \
    --depth=1 --no-use-superproject && repo sync -q -c --no-tags --force-sync)
  touch $W/.synced
fi

if [ ! -d $W/ccache ]; then
  say "ccache"
  mkdir -p $W/ccache
  [ -z "$GCS" ] || gcloud storage rsync -r gs://$BUCKET/ccache-files $W/ccache --quiet || true
  CCACHE_DIR=$W/ccache ccache -M 30G > /dev/null
fi

say "ready: $(du -sh $SRC | cut -f1) source, $(df -h --output=avail $W | tail -1 | xargs) free"
