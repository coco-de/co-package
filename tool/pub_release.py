"""Validate or publish a committed package with only hosted dependencies."""

import argparse
import json
import re
import subprocess
import tempfile
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SIBLINGS = {
    "co_demo_world": ("co_demo_prefs", "co_faker"),
    "co_example_ui": ("co_demo_prefs",),
    "open_epub": ("open_epub_engine",),
}


def git(*args: str) -> bytes:
    return subprocess.check_output(["git", *args], cwd=ROOT)


def pubspec_field(pubspec: str, field: str) -> str:
    match = re.search(rf"^{field}:[ \t]*([^\s#]+)", pubspec, re.MULTILINE)
    return match[1].strip("\"'") if match else ""


def wait_for_siblings(name: str, packages: dict[str, str]) -> None:
    tags = set(git("tag", "--points-at", "HEAD").decode().splitlines())
    pending = {}
    for sibling in SIBLINGS.get(name, ()):
        pubspec = git("show", f"HEAD:{packages[sibling]}/pubspec.yaml").decode()
        version = pubspec_field(pubspec, "version")
        if f"{sibling}-v{version}" in tags:
            pending[sibling] = version
    if pending:
        print(f"Waiting for same-commit dependencies on pub.dev: {pending}", flush=True)

    deadline = time.monotonic() + 20 * 60
    while pending:
        for sibling, version in list(pending.items()):
            url = f"https://pub.dev/api/packages/{sibling}/versions/{version}"
            try:
                with urllib.request.urlopen(url, timeout=10):
                    del pending[sibling]
            except OSError:
                pass
        if pending:
            if time.monotonic() >= deadline:
                raise SystemExit(f"Dependencies did not appear on pub.dev: {pending}")
            time.sleep(20)


def main() -> int:
    config = json.loads(git("show", "HEAD:release-please-config.json"))
    packages = {entry["component"]: path for path, entry in config["packages"].items()}

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("package", help="Package name, or the release tag with --tag")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--publish", action="store_true", help="Publish after pub's confirmation")
    mode.add_argument("--tag", action="store_true", help="Publish in the tagged OIDC workflow")
    args = parser.parse_args()

    name = args.package.partition("-v")[0] if args.tag else args.package
    if name not in packages:
        parser.error(f"Unknown package {name!r}. Choose from: {', '.join(sorted(packages))}")
    path = packages[name]
    pubspec = git("show", f"HEAD:{path}/pubspec.yaml").decode()
    version = pubspec_field(pubspec, "version")
    if pubspec_field(pubspec, "name") != name or not version:
        raise SystemExit(f"Invalid package name or version in HEAD:{path}/pubspec.yaml")
    if args.tag:
        expected = f"{name}-v{version}"
        tags = git("tag", "--points-at", "HEAD").decode().splitlines()
        if args.package != expected or expected not in tags:
            raise SystemExit(f"Expected tag {expected} at HEAD, got {args.package}")
        wait_for_siblings(name, packages)

    print(f"Preparing {name} {version} from HEAD", flush=True)
    with tempfile.TemporaryDirectory(prefix="co-package-release-") as staging:
        subprocess.run(
            ["tar", "-xf", "-", "-C", staging],
            input=git("archive", "HEAD", path),
            check=True,
        )
        package = Path(staging) / path
        if pubspec_field(pubspec, "resolution") == "workspace":
            # Pub excludes this file from the archive. The published pubspec keeps
            # its workspace declaration, while validation resolves from pub.dev.
            (package / "pubspec_overrides.yaml").write_text("resolution:\n")

        publish = ["dart", "pub", "publish"]
        if args.publish:
            return subprocess.run(publish, cwd=package).returncode
        dry_run = subprocess.run([*publish, "--dry-run"], cwd=package).returncode
        if dry_run or not args.tag:
            return dry_run
        return subprocess.run([*publish, "--force"], cwd=package).returncode


if __name__ == "__main__":
    raise SystemExit(main())
