#!/bin/bash
# Signs the target files with our release keys and makes the install package from them, as
# LineageOS's wiki (Signing Builds) has it. Run from the root of the Android tree, with the host tools
# on PATH and ANDROID_HOST_OUT set (envsetup.sh and breakfast do both).
# Usage: sign.sh <key dir> <target files> <signed target files> <install package>
#
# The key dir holds the keys and two lists: apexes.txt, the APEXes to sign, each with <apex>.pk8,
# .x509.pem and .pem; apex-apks.txt, the APKs inside APEXes, signed with releasekey.

set -euo pipefail
K=$1; IN=$2; SIGNED=$3; PKG=$4

# -d maps AOSP's default keys to ours, all but nfc's.
args=(-o -d "$K" -k "build/make/target/product/security/nfc=$K/nfc")
while read -r a; do args+=(--extra_apks "$a.apk=$K/releasekey"); done < "$K/apex-apks.txt"
while read -r a; do
  args+=(--extra_apks "$a.apex=$K/$a" --extra_apex_payload_key "$a.apex=$K/$a.pem")
done < "$K/apexes.txt"
# Fails, before the signing, if anything in the images would keep a key from the source tree.
python3 "$(dirname "$0")/check-keys.py" "$K" "$IN" "$ANDROID_HOST_OUT/bin"
sign_target_files_apks -p "$ANDROID_HOST_OUT" "${args[@]}" "$IN" "$SIGNED"

ota_from_target_files -p "$ANDROID_HOST_OUT" -k "$K/releasekey" --backup=true "$SIGNED" "$PKG"
