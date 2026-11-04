"""Exclude private-CoUI consumers when public CI has no CoUI read token."""

from pathlib import Path

PRIVATE_MEMBERS = {
    "packages/co_golden_gallery",
    "packages/co_example_ui",
    "packages/open_board/example",
    "packages/open_epub/example",
}


def without_coui_overrides(lines: list[str]) -> list[str]:
    """Pub resolves unused overrides too, so remove the private sources."""
    result = []
    inside = False
    skipping = False
    header = None
    for line in lines:
        if line.strip() == "dependency_overrides:":
            inside = True
            header = len(result)
            result.append(line)
            continue
        if inside and line and not line[0].isspace() and not line.startswith("#"):
            inside = False
            skipping = False
        if inside and line.startswith("  ") and not line.startswith("   "):
            name = line.strip().split(":", 1)[0]
            skipping = name in {"coui_core", "coui_flutter", "coui_web"}
        if not skipping:
            result.append(line)
    if header is not None:
        remaining = result[header + 1:]
        if not any(line.startswith("  ") and line.strip() for line in remaining):
            del result[header]
    return result


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
    pubspec.write_text("".join(without_coui_overrides(output)))
    print("Public CI excludes private CoUI consumers:", ", ".join(sorted(removed)))


if __name__ == "__main__":
    main()
