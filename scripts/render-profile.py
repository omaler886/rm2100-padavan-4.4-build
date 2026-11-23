#!/usr/bin/env python3
"""Render an upstream RM2100.config with common + variant overrides."""

from __future__ import annotations

import re
import sys
from pathlib import Path

KEY_RE = re.compile(r"^(CONFIG_[A-Z0-9_]+)=(.*)$")


def read_profile(path: Path) -> dict[str, str]:
    """Return CONFIG_* assignments from a simple key=value profile."""
    values: dict[str, str] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        match = KEY_RE.match(line)
        if not match:
            raise ValueError(f"{path}: invalid line: {raw_line!r}")
        values[match.group(1)] = match.group(2)
    return values


def render(base: Path, common: Path, variant: Path, output: Path) -> None:
    """Replace existing CONFIG_* keys and append missing ones."""
    values = read_profile(common)
    values.update(read_profile(variant))
    seen: set[str] = set()
    rendered: list[str] = []

    for raw_line in base.read_text(encoding="utf-8").splitlines():
        match = KEY_RE.match(raw_line)
        if match and match.group(1) in values:
            key = match.group(1)
            rendered.append(f"{key}={values[key]}")
            seen.add(key)
        else:
            rendered.append(raw_line)

    for key, value in values.items():
        if key not in seen:
            rendered.append(f"{key}={value}")

    output.write_text("\n".join(rendered) + "\n", encoding="utf-8")


def main(argv: list[str]) -> int:
    if len(argv) != 5:
        print(
            "usage: render-profile.py BASE COMMON VARIANT OUTPUT",
            file=sys.stderr,
        )
        return 2
    render(Path(argv[1]), Path(argv[2]), Path(argv[3]), Path(argv[4]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

