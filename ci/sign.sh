#!/bin/bash
# Signs the target files with our release keys and makes the install package from them, as
# LineageOS's wiki (Signing Builds) has it. Run from the root of the Android tree, with the host tools
# on PATH and ANDROID_HOST_OUT set (envsetup.sh and breakfast do both).
# Usage: sign.sh <key dir> <target files> <signed target files> <install package>
#
# The key dir holds the keys and two lists: apexes.txt, the APEXes to sign, each with <apex>.pk8,
# .x509.pem and .pem; apex-apks.txt, the APKs inside APEXes, signed with releasekey. avb.pem signs
# vbmeta and the images it chains (boot, vbmeta_system, vbmeta_vendor) in place of AOSP's test key.

set -euo pipefail
K=$1; IN=$2; SIGNED=$3; PKG=$4

# -d maps AOSP's default keys to ours, all but nfc's.
args=(-o -d "$K" -k "build/make/target/product/security/nfc=$K/nfc")
while read -r a; do args+=(--extra_apks "$a.apk=$K/releasekey"); done < "$K/apex-apks.txt"
while read -r a; do
  args+=(--extra_apks "$a.apex=$K/$a" --extra_apex_payload_key "$a.apex=$K/$a.pem")
done < "$K/apexes.txt"
for p in vbmeta boot vbmeta_system vbmeta_vendor; do
  args+=("--avb_${p}_key" "$K/avb.pem" "--avb_${p}_algorithm" SHA256_RSA4096)
done
# Fails, before the signing, if anything in the images would keep a key from the source tree.
python3 "$(dirname "$0")/check-keys.py" "$K" "$IN" "$ANDROID_HOST_OUT/bin"
sign_target_files_apks -p "$ANDROID_HOST_OUT" "${args[@]}" "$IN" "$SIGNED"

# boot.img comes from the device's own boot image makefile, so the target files keep it in
# BOOTABLE_IMAGES and the tools reuse it as built, with the test key and test-keys fingerprint. Sign
# its footer again with what the signed misc_info gives boot.
misc() { unzip -p "$SIGNED" META/misc_info.txt | sed -n "s/^$1=//p"; }
read -ra footer <<< "$(misc avb_boot_add_hash_footer_args)"
work=$(mktemp -d)
unzip -q "$SIGNED" IMAGES/boot.img -d "$work"
avbtool erase_footer --image "$work/IMAGES/boot.img"
avbtool add_hash_footer --image "$work/IMAGES/boot.img" --partition_name boot \
  --partition_size "$(misc boot_size)" --algorithm "$(misc avb_boot_algorithm)" --key "$K/avb.pem" "${footer[@]}"
mkdir "$work/BOOTABLE_IMAGES" && cp "$work/IMAGES/boot.img" "$work/BOOTABLE_IMAGES/"
(cd "$work" && zip -q "$SIGNED" IMAGES/boot.img BOOTABLE_IMAGES/boot.img)
rm -rf "$work"

# And after it, that every signed AVB image carries our key.
want=$(avbtool extract_public_key --key "$K/avb.pem" --output /dev/stdout | sha1sum | cut -d' ' -f1)
for p in vbmeta boot vbmeta_system vbmeta_vendor; do
  img=$(mktemp)
  unzip -p "$SIGNED" "IMAGES/$p.img" > "$img"
  got=$(avbtool info_image --image "$img" | sed -n 's/^Public key (sha1): *//p')
  rm -f "$img"
  [ "$got" = "$want" ] || { echo "$p.img is not signed with avb.pem (public key $got)" >&2; exit 1; }
done

ota_from_target_files -p "$ANDROID_HOST_OUT" -k "$K/releasekey" --backup=true "$SIGNED" "$PKG"
