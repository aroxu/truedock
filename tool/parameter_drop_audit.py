#!/usr/bin/env python3
"""Find options the repository accepts but the controller never forwards.

The pool.replace defect had a specific shape: the repository exposed `force`
with a safe default, the UI collected it and warned the user about it, and the
controller in between simply had no parameter for it. Every layer looked
correct in isolation, so nothing failed - the flag just evaporated, and the
server performed a different operation than the one the user confirmed.

Nothing catches that class of bug. Analyzer sees a legal call using a default.
Unit tests of the repository pass the flag directly. Widget tests of the sheet
assert the switch flips local state. The break is in the seam between layers.

So this compares the two signatures directly: for every repository method the
controller wraps, any optional parameter the repository accepts but the
controller neither takes nor passes is reported. Parameters that are genuinely
server-side defaults the app never intends to expose can be listed in ALLOWED,
which forces that decision to be written down instead of silently assumed.
"""

import re
import sys
from pathlib import Path

REPOSITORY = Path("lib/features/actions/data/server_actions_repository.dart")
CONTROLLER = Path("lib/features/actions/presentation/server_action_controller.dart")

# Repository parameters the controller deliberately does not surface, with the
# reason. Anything not listed here must be forwarded.
ALLOWED = {
    # TrueNAS keeps the replaced disk's settings and description by default and
    # TrueDock has no UI for changing them; exposing them would be a setting
    # with no screen behind it.
    ("replacePoolDisk", "preserveSettings"),
    ("replacePoolDisk", "preserveDescription"),
    # A zvol block size is chosen by pool geometry; the create sheet
    # deliberately leaves it to the server.
    ("createVolume", "blockSizeBytes"),
    # Snapshot deletion defer is a ZFS-level detail with no screen behind it.
    ("deleteSnapshot", "defer"),
    # The commit sheet never chooses the rollback window. It displays the time
    # remaining from `interface.checkin_waiting`, i.e. the server's own count,
    # rather than echoing a number TrueDock sent - so a fixed 60s here cannot
    # disagree with what the user is shown. Making it configurable would add a
    # setting with no screen and a real chance of the two drifting apart.
    ("commitInterfaceChanges", "checkInTimeoutSeconds"),
    # The instance controls are plain start/stop/restart/power-off buttons with
    # no timeout field. The bounded 90s exists so a wedged guest cannot hang the
    # job forever; power off already bypasses it with `force`.
    ("controlVirtInstance", "gracefulTimeoutSeconds"),
    # Unlike replace's `force`, nothing in the attach sheet offers this, so the
    # app never promises it. Duplicate serials mean two disks reporting the same
    # identity, which is a hardware or passthrough fault worth refusing by
    # default rather than a choice to put in front of a phone user.
    ("attachPoolDisk", "allowDuplicateSerials"),
}


def _skip_signature(text: str, open_paren: int) -> int:
    """Index just past the `)` closing a signature that starts at [open_paren]."""
    depth = 1
    index = open_paren
    while index < len(text) and depth:
        if text[index] == "(":
            depth += 1
        elif text[index] == ")":
            depth -= 1
        index += 1
    return index if depth == 0 else -1


def _body(text: str, after_signature: int) -> str:
    """The function body starting after [after_signature].

    The signature's parentheses must already be consumed. Looking for the first
    `{` from the *name* instead lands on the named-parameter block of a
    signature like `foo(int id, {bool force = false})`, so the body reads as a
    parameter list and every check against it silently answers "no". That is
    exactly how this audit first reported only 2 of 12 candidate methods: each
    body was a parameter list, so `_repository.<name>` was never found in it and
    the method was skipped as "not a wrapper".
    """
    brace = text.find("{", after_signature)
    arrow = text.find("=>", after_signature)
    if arrow != -1 and (brace == -1 or arrow < brace):
        end = text.find(";", arrow)
        return text[arrow:end] if end != -1 else text[arrow:]
    if brace == -1:
        return ""
    depth, index = 0, brace
    while index < len(text):
        if text[index] == "{":
            depth += 1
        elif text[index] == "}":
            depth -= 1
            if depth == 0:
                break
        index += 1
    return text[brace : index + 1]


def signatures(text: str) -> dict[str, tuple[str, str]]:
    """Map method name -> (parameter source, body) for `Future<...> name(...)`."""
    found: dict[str, tuple[str, str]] = {}
    pattern = re.compile(r"^\s*Future<[^>]*>\s+(\w+)\s*\(", re.M)
    for match in pattern.finditer(text):
        after = _skip_signature(text, match.end())
        if after == -1:
            continue
        found[match.group(1)] = (
            text[match.end() : after - 1],
            _body(text, after),
        )
    return found


def optional_named(params: str) -> set[str]:
    """Optional named parameters, i.e. the ones with a default that can vanish.

    Required parameters cannot be dropped silently - omitting one is a compile
    error - so they are not interesting here. It is precisely the parameters
    with defaults that disappear without a trace.
    """
    start = params.find("{")
    if start == -1:
        return set()
    body = params[start + 1 : params.rfind("}")]
    names: set[str] = set()
    depth = 0
    current = ""
    for char in body:
        if char in "(<[":
            depth += 1
        elif char in ")>]":
            depth -= 1
        if char == "," and depth == 0:
            names.add(current)
            current = ""
        else:
            current += char
    names.add(current)

    optional = set()
    for raw in names:
        declaration = raw.strip()
        if not declaration or declaration.startswith("required "):
            continue
        # `Type name = default` or `Type? name`
        head = declaration.split("=")[0].strip()
        parts = head.split()
        if parts:
            optional.add(parts[-1])
    return optional


def wrapping_pairs() -> list[str]:
    """Report any layer that wraps a repository besides the audited pair.

    REPOSITORY and CONTROLLER are hardcoded, which is only correct while the
    app has exactly one wrapping seam. Today it does - `server_action_controller`
    is the sole file that forwards calls to a `_repository`. But that is an
    assumption about the codebase, not a fact about the audit, and if a second
    controller appears this file keeps passing while never looking at it.

    The confirmation audit had precisely this shape of blind spot: it selected
    files by name, so a screen that did not match the convention was invisible
    and the run still printed green. Rather than repeat that, the assumption is
    checked. A checker that silently covers less than it claims is worse than no
    checker, because it is trusted.
    """
    others = []
    for path in sorted(Path("lib").rglob("*.dart")):
        if path == CONTROLLER:
            continue
        text = path.read_text(encoding="utf-8")
        if re.search(r"_\w*[Rr]epository\.\w+\s*\(", text):
            others.append(
                f"{path}: forwards to a repository but is not audited; "
                f"add it to the audited pairs or explain why it cannot drop "
                f"an option"
            )
    return others


def main() -> int:
    repository = signatures(REPOSITORY.read_text(encoding="utf-8"))
    controller = signatures(CONTROLLER.read_text(encoding="utf-8"))

    problems: list[str] = wrapping_pairs()
    checked = 0
    skipped: list[str] = []

    for name, (repo_params, _) in sorted(repository.items()):
        repo_optional = optional_named(repo_params)
        if not repo_optional:
            continue
        if name not in controller:
            continue
        controller_params, body = controller[name]
        # Only consider controller methods that actually wrap this repository
        # method, rather than sharing a name by coincidence.
        if f"_repository.{name}" not in body:
            skipped.append(name)
            continue
        checked += 1
        for parameter in sorted(repo_optional):
            if (name, parameter) in ALLOWED:
                continue
            declared = re.search(rf"\b{re.escape(parameter)}\b", controller_params)
            forwarded = re.search(rf"\b{re.escape(parameter)}\s*:", body)
            if not declared and not forwarded:
                problems.append(
                    f"{CONTROLLER}: {name}() drops the repository's "
                    f"optional '{parameter}' - the UI cannot ever set it"
                )

    for problem in problems:
        print(problem, file=sys.stderr)

    # A candidate that parsed but did not look like a wrapper is reported rather
    # than dropped. Silently skipping is how a broken body extractor turns into
    # a green run that checked almost nothing.
    if skipped:
        print(
            f"note: {len(skipped)} method(s) not recognised as wrappers: "
            f"{', '.join(sorted(skipped))}",
            file=sys.stderr,
        )

    if problems:
        print(
            f"Parameter-drop audit found {len(problems)} dropped option(s).",
            file=sys.stderr,
        )
        return 1

    print(
        f"Parameter-drop audit clean: {checked} wrapped method(s) with optional "
        f"parameters across 1 wrapping seam, none silently dropped"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
