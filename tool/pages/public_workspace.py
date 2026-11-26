"""Set up the public workspace and optionally run Melos verification scripts."""

import argparse
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("scripts", nargs="*", help="Optional Melos scripts to run, e.g. verify")
    args = parser.parse_args()

    subprocess.run(["dart", "pub", "get", "--no-example"], cwd=ROOT, check=True)
    for script in args.scripts:
        subprocess.run(
            ["dart", "run", "melos", "run", script, "--no-select"],
            cwd=ROOT,
            check=True,
        )


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as error:
        raise SystemExit(error.returncode) from None
