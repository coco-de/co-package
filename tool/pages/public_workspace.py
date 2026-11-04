"""Exclude private-CoUI consumers when public CI has no CoUI read token."""

from pathlib import Path

PRIVATE_MEMBERS = {
    "packages/co_golden_gallery",
    "packages/co_example_ui",
    "packages/open_board/example",
    "packages/open_epub/example",
}


def main() -> None:
    pubspec = Path("pubspec.yaml")
    removed = set()
    output = []
    for line in pubspec.read_text().splitlines(keepends=True):
        member = line.split("#", 1)[0].strip().removeprefix("- ").strip()
        if line.startswith("  - ") and member in PRIVATE_MEMBERS:
            removed.add(member)
        else:
            output.append(line)
    if removed != PRIVATE_MEMBERS:
        raise SystemExit(f"Unexpected workspace members: {PRIVATE_MEMBERS - removed}")
    pubspec.write_text("".join(output))
    print("Public CI excludes private CoUI consumers:", ", ".join(sorted(removed)))


if __name__ == "__main__":
    main()
