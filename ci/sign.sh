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

args=(-o -d "$K")
while read -r a; do args+=(--extra_apks "$a.apk=$K/releasekey"); done < "$K/apex-apks.txt"
while read -r a; do
  args+=(--extra_apks "$a.apex=$K/$a" --extra_apex_payload_key "$a.apex=$K/$a.pem")
done < "$K/apexes.txt"
sign_target_files_apks -p "$ANDROID_HOST_OUT" "${args[@]}" "$IN" "$SIGNED"

# Every APK and APEX is now signed with a key from the key dir, or was signed by its maker
# (PRESIGNED); anything still pointing elsewhere would be a test key the lists above missed.
left=$(unzip -p "$SIGNED" META/apkcerts.txt META/apexkeys.txt \
  | grep -v 'PRESIGNED' | grep -oE '(certificate|private_key|container_certificate|container_private_key)="[^"]*"' \
  | grep -v "=\"$K/" | grep -v '=""' || true)
if [ -n "$left" ]; then
  echo "Not signed with our keys:" >&2
  unzip -p "$SIGNED" META/apkcerts.txt META/apexkeys.txt | grep -v PRESIGNED | grep -v "=\"$K/" >&2
  exit 1
fi

ota_from_target_files -p "$ANDROID_HOST_OUT" -k "$K/releasekey" --backup=true "$SIGNED" "$PKG"
