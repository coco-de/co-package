#!/usr/bin/env python3
"""Checks co_faker's national phone formats with Google libphonenumber.

Usage (needs `pip install phonenumbers`):

    dart run tool/national_phone_formats.dart | python3 tool/verify_phone_formats.py

Countries with a range reserved for fiction (US/CA NANP 555-01xx, GB Ofcom,
DE Bundesnetzagentur, FR ARCEP) only need parseable, possible numbers. Every
other country must produce numbers that libphonenumber rejects for every
number type, so a generated value can never be an assigned number. Re-run
after updating `phonenumbers`: new allocations would surface here.
"""

import json
import random
import sys

import phonenumbers

RESERVED_FOR_FICTION = {"US", "CA", "GB", "DE", "FR"}
SAMPLES = 2000


def fill(template, rng):
    return "".join(str(rng.randint(0, 9)) if c == "#" else c for c in template)


def main():
    formats = json.load(sys.stdin)
    rng = random.Random(20261005)
    failures = []
    for item in formats:
        country = item["country"]
        for notation in ("national", "international"):
            template = item[notation]
            valid = 0
            for _ in range(SAMPLES):
                text = fill(template, rng)
                try:
                    number = phonenumbers.parse(text, country)
                except phonenumbers.NumberParseException as error:
                    failures.append(f"{country} {template}: parse {error}")
                    break
                if not phonenumbers.is_possible_number(number):
                    failures.append(f"{country} {template}: impossible {text}")
                    break
                if phonenumbers.is_valid_number(number):
                    valid += 1
            status = "reserved" if country in RESERVED_FOR_FICTION else "invalid"
            if status == "invalid" and valid:
                failures.append(
                    f"{country} {template}: {valid}/{SAMPLES} numbers are valid"
                )
            print(f"{country:2} {notation:13} {template:22} {status:8} "
                  f"valid {valid}/{SAMPLES}")
    print(f"phonenumbers {phonenumbers.__version__}")
    if failures:
        print("\n".join(failures), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
