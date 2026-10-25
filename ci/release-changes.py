#!/usr/bin/env python3
"""List what changed between two builds, from their manifest snapshots, for the release notes.

One line for each of our own repositories (github.com/Star-caorui) that changed between the two builds,
with GitHub's comparison of the two commits and how many commits it holds; for LineageOS and AOSP,
only how many repositories changed.

    ci/release-changes.py --old manifest-snapshot.xml [kernel-manifest-snapshot.xml] \\
        --new manifest-snapshot.xml [kernel-manifest-snapshot.xml]

The kernel sources' snapshot is optional on either side: builds before LineageOS's build_kernel took
the kernel prebuilt, from a repository in the main manifest. The counts come from GitHub's compare API
through the gh CLI, which needs GH_TOKEN.
"""

import argparse
import json
import subprocess
import sys
import urllib.parse
import xml.etree.ElementTree as ET

OURS = "https://github.com/Star-caorui/"
# repo resolves a relative fetch URL against the manifest repository's URL.
MANIFEST_URL = "https://github.com/LineageOS/android"


def projects(paths):
    """{repository URL: revision} of every project in the given snapshots."""
    found = {}
    for path in paths:
        root = ET.parse(path).getroot()
        remotes = {r.get("name"): r.get("fetch") for r in root.iter("remote")}
        default = root.find("default")
        default_remote = default.get("remote") if default is not None else None
        for p in root.iter("project"):
            fetch = remotes[p.get("remote") or default_remote]
            base = urllib.parse.urljoin(MANIFEST_URL + "/", fetch).rstrip("/") + "/"
            found[base + p.get("name")] = p.get("revision")
    return found


def compare(repo, old, new):
    """How many commits lead from old to new; None when GitHub cannot compare them as a
    fast-forward."""
    result = subprocess.run(
        ["gh", "api", f"repos/Star-caorui/{repo}/compare/{old}...{new}", "--jq", "[.status, .total_commits]"],
        capture_output=True, text=True)
    if result.returncode != 0:
        return None
    status, total = json.loads(result.stdout)
    return total if status in ("ahead", "identical") else None


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--old", nargs="+", required=True)
    parser.add_argument("--new", nargs="+", required=True)
    args = parser.parse_args()
    old, new = projects(args.old), projects(args.new)

    upstream = sum(1 for url in old.keys() | new.keys()
                   if not url.startswith(OURS) and old.get(url) != new.get(url))
    for url in sorted(u for u in old.keys() | new.keys() if u.startswith(OURS)):
        repo = url[len(OURS):]
        link = f"https://github.com/Star-caorui/{repo}"
        if url not in old:
            print(f"- **{repo}**: new in this build, at [`{new[url][:12]}`]({link}/commit/{new[url]})")
            continue
        if url not in new:
            print(f"- **{repo}**: no longer in the build")
            continue
        if old[url] == new[url]:
            continue
        compare_url = f"{link}/compare/{old[url]}...{new[url]}"
        total = compare(repo, old[url], new[url])
        if total is None:
            print(f"- **{repo}**: [`{old[url][:12]}...{new[url][:12]}`]({compare_url}), not a fast-forward")
        else:
            print(f"- **{repo}**: [{total} {'commit' if total == 1 else 'commits'}]({compare_url})")
    print(f"\nLineageOS and AOSP: {upstream} {'repository' if upstream == 1 else 'repositories'} changed.")


if __name__ == "__main__":
    sys.exit(main())
