#!/usr/bin/env python3
"""Check that signing the target files with our key dir leaves nothing on a key from elsewhere.

    ci/check-keys.py <key dir> <target files> <host tools dir>

It works out the key sign_target_files_apks will use for every APK and APEX that is in the target
files, APKs inside APEXes included, with the mapping ci/sign.sh gives it: -d <key dir> (AOSP's
default keys to ours), -k for the nfc key, which -d leaves out, and the APEXes and APKs inside APEXes
the key dir's apexes.txt and apex-apks.txt list. It lists what would keep a key from the source
tree, which is public, and fails if there is any. Its makers' signatures (PRESIGNED) are left alone.
META/apkcerts.txt names every APK the source tree can build, so only what is in the images counts.
It reads no keys, so it can run before the signing.
"""

import pathlib
import re
import subprocess
import sys
import tempfile
import zipfile

DEFAULT_KEYS = "build/make/target/product/security/"
# What -d maps, and what ci/sign.sh adds with -k
MAPPED = {"testkey", "devkey", "media", "shared", "platform", "networkstack", "sdk_sandbox", "bluetooth", "nfc"}
SIGNED_BY_MAKER = ("PRESIGNED", "EXTERNAL")


def entries(text):
    return [dict(re.findall(r'(\w+)="([^"]*)"', line)) for line in text.splitlines() if "name=" in line]


def ours(cert):
    return cert.startswith(DEFAULT_KEYS) and cert[len(DEFAULT_KEYS):].removesuffix(".x509.pem") in MAPPED


def apks_in_apex(path, tools):
    if path.suffix == ".capex":
        apex = path.with_suffix(".apex")
        subprocess.run([f"{tools}/deapexer", "decompress", "--input", path, "--output", apex], check=True)
        path = apex
    listing = subprocess.run(
        [f"{tools}/deapexer", "--debugfs_path", f"{tools}/debugfs_static",
         "--fsckerofs_path", f"{tools}/fsck.erofs", "list", path],
        check=True, capture_output=True, text=True).stdout
    return {pathlib.PurePath(line).name for line in listing.split() if line.endswith(".apk")}


def main():
    key_dir, target_files, tools = sys.argv[1:4]
    key_dir = pathlib.Path(key_dir)
    extra_apks = {f"{name}.apk" for name in (key_dir / "apex-apks.txt").read_text().split()}
    extra_apexes = {f"{name}.apex" for name in (key_dir / "apexes.txt").read_text().split()}

    with zipfile.ZipFile(target_files) as tf, tempfile.TemporaryDirectory() as tmp:
        files = [n for n in tf.namelist() if not n.startswith(("META/", "IMAGES/", "OTA/"))]
        apks = {pathlib.PurePath(n).name for n in files if n.endswith(".apk")}
        apexes = [n for n in files if n.endswith((".apex", ".capex"))]
        for name in apexes:
            path = pathlib.Path(tf.extract(name, tmp))
            apks |= apks_in_apex(path, tools)
        apex_names = {pathlib.PurePath(n).with_suffix(".apex").name for n in apexes}
        apkcerts = {e["name"]: e for e in entries(tf.read("META/apkcerts.txt").decode())}
        apexkeys = {e["name"]: e for e in entries(tf.read("META/apexkeys.txt").decode())}

    left = []
    for name in sorted(apks):
        cert = apkcerts.get(name, {}).get("certificate", "")
        if name in extra_apks or cert in SIGNED_BY_MAKER or ours(cert):
            continue
        left.append(f"{name}: {cert or 'not in apkcerts.txt'}")
    for name in sorted(apex_names):
        entry = apexkeys.get(name, {})
        cert = entry.get("container_certificate", "")
        if name in extra_apexes or cert in SIGNED_BY_MAKER:
            continue
        left.append(f"{name}: container {cert or 'not in apexkeys.txt'}, payload {entry.get('private_key', '')}")

    print(f"{len(apks)} APKs and {len(apex_names)} APEXes in the target files")
    if left:
        print("Would keep a key from the source tree:", *left, sep="\n  ")
        sys.exit(1)


if __name__ == "__main__":
    main()
