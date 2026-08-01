#!/usr/bin/env python3
"""Reject duplicate top-level keys in the ARB translation files.

JSON parsers keep the last definition of a repeated key, so a duplicate does not
fail `gen-l10n`, does not fail `flutter analyze`, and does not fail the test
suite. It simply makes an earlier string disappear. That is exactly the kind of
defect no other gate can see: `storageSnapshotCreated` was defined twice in both
locales , so the translation a reader saw in the
file was not the one the app shipped.

"""

import json
import re
import sys
from collections import Counter
from pathlib import Path


def top_level_keys(text: str) -> list[tuple[str, int]]:
    """Keys at object depth 1, with line numbers.

    A plain regex over the file would also match keys nested inside `@meta`
    objects (`description`, `placeholders`, `type`), which are legitimately
    repeated across entries. Tracking brace depth is what keeps this from
    reporting those as duplicates.
    """
    depth = 0
    found: list[tuple[str, int]] = []
    for match in re.finditer(r'"((?:[^"\\]|\\.)*)"\s*:|[{}]', text):
        token = match.group(0)
        if token == "{":
            depth += 1
        elif token == "}":
            depth -= 1
        elif depth == 1:
            line = text.count("\n", 0, match.start()) + 1
            found.append((match.group(1), line))
    return found


def main(paths: list[str]) -> int:
    failures = 0
    key_sets: dict[str, set[str]] = {}

    for path_name in paths:
        path = Path(path_name)
        text = path.read_text(encoding="utf-8")

        try:
            json.loads(text)
        except json.JSONDecodeError as error:
            print(f"{path}: invalid JSON: {error}", file=sys.stderr)
            failures += 1
            continue

        keys = top_level_keys(text)
        counts = Counter(name for name, _ in keys)
        for name, count in sorted(counts.items()):
            if count == 1:
                continue
            lines = [line for key, line in keys if key == name]
            print(
                f"{path}: duplicate key {name!r} at lines "
                f"{', '.join(str(line) for line in lines)}",
                file=sys.stderr,
            )
            failures += 1

        key_sets[path_name] = {
            name for name, _ in keys if not name.startswith("@")
        }

    names = list(key_sets)
    for index, left in enumerate(names):
        for right in names[index + 1:]:
            only_left = key_sets[left] - key_sets[right]
            only_right = key_sets[right] - key_sets[left]
            for missing in sorted(only_left):
                print(f"{right}: missing {missing!r} (defined in {left})",
                      file=sys.stderr)
                failures += 1
            for missing in sorted(only_right):
                print(f"{left}: missing {missing!r} (defined in {right})",
                      file=sys.stderr)
                failures += 1

    if failures:
        print(f"ARB lint found {failures} problem(s).", file=sys.stderr)
        return 1
    print(f"ARB lint clean: {len(paths)} file(s), "
          f"{len(next(iter(key_sets.values())))} keys per locale")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:] or ["lib/l10n/app_en.arb"]))
