#!/usr/bin/env python3
"""Apply small, auditable source patches needed on modern build hosts."""

from __future__ import annotations

import sys
from pathlib import Path

OLD_TOOLS = "\n.PHONY: tools\ntools:\n\tmake -C tools\n"
NEW_TOOLS = "\n.PHONY: tools\ntools:\n\t$(MAKE) -C tools -j1\n"


def patch_tools(makefile: Path) -> None:
    """Build host tools serially; xz/mksquashfs have an implicit ordering race."""
    text = makefile.read_text(encoding="utf-8")
    if NEW_TOOLS in text:
        print("tools target already serial")
        return
    if OLD_TOOLS not in text:
        raise SystemExit(f"tools target pattern not found in {makefile}")
    makefile.write_text(text.replace(OLD_TOOLS, NEW_TOOLS, 1), encoding="utf-8")
    print("patched tools target to -j1")


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("usage: patch-source.py SOURCE_ROOT", file=sys.stderr)
        return 2
    root = Path(argv[1])
    patch_tools(root / "trunk" / "Makefile")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
