#!/usr/bin/env python3
"""List what changed between two builds, from their manifest snapshots, for the release notes.

Every commit in our own repositories (github.com/Star-caorui) between the two builds, oldest first,
under the repository's name; for LineageOS and AOSP, only how many repositories changed.

    ci/release-changes.py --old manifest-snapshot.xml [kernel-manifest-snapshot.xml] \\
        --new manifest-snapshot.xml [kernel-manifest-snapshot.xml]

The kernel sources' snapshot is optional on either side: builds before LineageOS's build_kernel took
the kernel prebuilt, from a repository in the main manifest. Commits come from GitHub's compare API
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
    """The commits from old to new, oldest first, and how many more there are than GitHub listed;
    None when GitHub cannot compare them."""
    result = subprocess.run(
        ["gh", "api", f"repos/Star-caorui/{repo}/compare/{old}...{new}"],
        capture_output=True, text=True)
    if result.returncode != 0:
        return None
    data = json.loads(result.stdout)
    if data.get("status") not in ("ahead", "identical"):
        return None
    commits = [c for c in data["commits"] if len(c["parents"]) < 2]
    # The API lists at most 250 commits.
    return commits, data["total_commits"] - len(data["commits"])


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
            print(f"**{repo}**: new in this build, at [`{new[url][:12]}`]({link}/commit/{new[url]})\n")
            continue
        if url not in new:
            print(f"**{repo}**: no longer in the build\n")
            continue
        if old[url] == new[url]:
            continue
        compared = compare(repo, old[url], new[url])
        if compared is None:
            print(f"**{repo}**: [`{old[url][:12]}` to `{new[url][:12]}`]"
                  f"({link}/compare/{old[url]}...{new[url]}), not a fast-forward\n")
            continue
        commits, more = compared
        print(f"**{repo}**\n")
        for c in commits:
            subject = c["commit"]["message"].splitlines()[0]
            print(f"- {subject} ([`{c['sha'][:12]}`]({link}/commit/{c['sha']}))")
        if more:
            print(f"- and [{more} more]({link}/compare/{old[url]}...{new[url]})")
        print()
    print(f"LineageOS and AOSP: {upstream} {'repository' if upstream == 1 else 'repositories'} changed.")


if __name__ == "__main__":
    sys.exit(main())
