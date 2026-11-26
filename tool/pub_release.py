"""Validate or publish a committed package with only hosted dependencies."""

import argparse
import json
import re
import subprocess
import tempfile
import time
import urllib.error
import urllib.request
from contextlib import contextmanager
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SIBLINGS = {
    "co_demo_world": ("co_demo_prefs", "co_faker"),
    "co_example_ui": ("co_demo_prefs",),
    "open_epub": ("open_epub_engine",),
}
COUI_DEPENDENCIES = {
    "co_example_ui": ("coui_flutter",),
    "co_golden_gallery": ("coui_web",),
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


@contextmanager
def staged_package(path: str, pubspec: str):
    with tempfile.TemporaryDirectory(prefix="co-package-release-") as staging:
        subprocess.run(
            ["tar", "-xf", "-", "-C", staging],
            input=git("archive", "HEAD", path),
            check=True,
        )
        package = Path(staging) / path
        if pubspec_field(pubspec, "resolution") == "workspace":
            # Pub uses the override for resolution and excludes it from upload.
            (package / "pubspec_overrides.yaml").write_text("resolution:\n")
        yield package


@lru_cache(maxsize=None)
def hosted_package_exists(name: str) -> bool:
    url = f"https://pub.dev/api/packages/{name}"
    try:
        with urllib.request.urlopen(url, timeout=15):
            return True
    except urllib.error.HTTPError as error:
        if error.code == 404:
            return False
        raise


def check_all_packages(packages: dict[str, str]) -> int:
    files = set(git("ls-tree", "-r", "--name-only", "HEAD", "packages").decode().splitlines())
    paths = {
        file.removesuffix("/pubspec.yaml")
        for file in files
        if file.count("/") == 2 and file.endswith("/pubspec.yaml")
    }
    manifest = json.loads(git("show", "HEAD:.release-please-manifest.json"))
    if paths != set(packages.values()) or paths != set(manifest):
        raise SystemExit("The release config and version manifest must cover every top-level package.")

    passed = pending = failed = 0
    for name, path in sorted(packages.items()):
        pubspec = git("show", f"HEAD:{path}/pubspec.yaml").decode()
        if (
            pubspec_field(pubspec, "name") != name
            or pubspec_field(pubspec, "version") != manifest[path]
            or pubspec_field(pubspec, "publish_to") not in {"", "https://pub.dev"}
        ):
            print(f"{name}: name, version or publish_to disagrees with release config", flush=True)
            failed += 1
            continue
        required_files = {f"{path}/{file}" for file in ("LICENSE", "CHANGELOG.md", "README.md")}
        missing_files = required_files - files
        if missing_files:
            print(f"{name}: missing {', '.join(sorted(missing_files))}", flush=True)
            failed += 1
            continue

        prerequisites = (*SIBLINGS.get(name, ()), *COUI_DEPENDENCIES.get(name, ()))
        missing_packages = [dependency for dependency in prerequisites if not hosted_package_exists(dependency)]
        if missing_packages:
            print(f"{name}: waiting for {', '.join(missing_packages)} on pub.dev", flush=True)
            pending += 1
            continue

        with staged_package(path, pubspec) as package:
            result = subprocess.run(
                ["dart", "pub", "publish", "--dry-run"],
                cwd=package,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
            )
        if result.returncode:
            print(f"{name}: failed\n{result.stdout}", flush=True)
            failed += 1
        else:
            print(f"{name}: dry run passed", flush=True)
            passed += 1

    print(f"Archive checks: {passed} passed, {pending} waiting for dependencies, {failed} failed")
    return int(failed > 0)


def main() -> int:
    config = json.loads(git("show", "HEAD:release-please-config.json"))
    packages = {entry["component"]: path for path, entry in config["packages"].items()}

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("package", nargs="?", help="Package name, or the release tag with --tag")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--publish", action="store_true", help="Publish after pub's confirmation")
    mode.add_argument("--tag", action="store_true", help="Publish in the tagged OIDC workflow")
    mode.add_argument("--check-all", action="store_true", help="Check release metadata and run available dry runs")
    args = parser.parse_args()

    if args.check_all:
        if args.package:
            parser.error("--check-all checks every package")
        return check_all_packages(packages)
    if not args.package:
        parser.error("provide a package name or --check-all")

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
    with staged_package(path, pubspec) as package:
        publish = ["dart", "pub", "publish"]
        if args.publish:
            return subprocess.run(publish, cwd=package).returncode
        dry_run = subprocess.run([*publish, "--dry-run"], cwd=package).returncode
        if dry_run or not args.tag:
            return dry_run
        return subprocess.run([*publish, "--force"], cwd=package).returncode


if __name__ == "__main__":
    raise SystemExit(main())
