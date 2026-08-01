#!/usr/bin/env python3
"""Prove every destructive action passes through a confirmation.

The confirmation widget itself is covered by widget tests, and individual flows
are covered by integration tests. Neither answers the question the safety policy
in AGENTS.md actually asks: is there a *call site* somewhere that reaches a
destructive controller method without first asking the user?

That gap cannot be closed by testing, because it is a question about code that
may not exist yet. A new screen calling `deleteDataset` directly would not fail
any existing test - there would simply be no test for it. So this walks the
presentation layer instead, finds every call into a destructive controller
method, and requires a confirmation in the same function.

Impact classes follow AGENTS.md: `CRITICAL` operations are irreversible and must
additionally use `MutationImpact.critical`, which is what forces the user to type
the target name.
"""

import re
import sys
from pathlib import Path

# Irreversible: data or configuration cannot be recovered afterwards.
CRITICAL = {
    "deleteDataset",
    "deleteSnapshot",
    "deleteApp",
    "deleteUser",
    "deleteGroup",
    "deleteApiKey",
    "deletePrivilege",
    "deleteVirtInstance",
    "destroyBootEnvironment",
    "exportPool",
    "resetConfiguration",
    "rollbackSnapshot",
    "deleteCloudBackupSnapshot",
    "replacePoolDisk",
}

# Disruptive: interrupts workloads or changes important configuration, but the
# result can be undone or retried.
HIGH = {
    "rebootServer",
    "shutdownServer",
    "runSystemUpdate",
    "activateBootEnvironment",
    "rollbackApp",
    "restoreCloudBackup",
    "changeUserPassword",
    "deleteSmbShare",
    "deleteNfsShare",
    "deleteIscsiPortal",
    "deleteIscsiInitiator",
    "deleteIscsiTarget",
    "deleteIscsiExtent",
    "deleteIscsiTargetExtent",
    "deleteIscsiAuth",
    "deleteSnapshotTask",
    "deleteReplicationTask",
    "deleteCloudSyncTask",
    "deleteCloudBackupTask",
    "deleteRsyncTask",
    "deleteCronJob",
    "deleteTunable",
    "deleteAlertService",
    "deleteStaticRoute",
    "deleteVirtualMachineDevice",
    "promoteDataset",
    "attachPoolDisk",
    # Aborts interrupt work in flight but do not destroy a stored result, so
    # they are disruptive rather than irreversible.
    "abortCloudBackup",
    "abortJob",
    # Ending a session signs a client out. Nothing stored is lost and the user
    # can sign in again, so this is disruptive rather than irreversible.
    "terminateSession",
    "terminateOtherSessions",
}

GUARDED = CRITICAL | HIGH

CONTROLLER = Path(
    "lib/features/actions/presentation/server_action_controller.dart"
)

# Controller methods whose name reads destructive but which are deliberately
# unclassified, with the reason. Anything else matching DESTRUCTIVE_VERB must
# appear in CRITICAL or HIGH.
UNCLASSIFIED = {
    # Undoes staged network changes that were never applied to the live system.
    # It restores the configuration the user already has, so confirming it would
    # be asking permission to change nothing - and it is the escape hatch from a
    # commit that broke the session, where an extra prompt is actively harmful.
    "rollbackInterfaceChanges",
}

DESTRUCTIVE_VERB = re.compile(
    r"^(delete|destroy|reset|export|rollback|replace|remove|wipe|revert"
    r"|detach|offline|purge|prune|abort|terminate|revoke|evict|kill)",
    re.I,
)


def classification_gaps() -> list[str]:
    """Controller methods that look destructive but are in no impact list.

    CRITICAL and HIGH are maintained by hand, which makes the audit only as
    complete as someone's memory: a new `deletePolicy` would be checked against
    nothing and pass silently. Nothing about that failure is visible - the audit
    still prints a green line, just for fewer methods.

    So the lists are checked against the controller itself. Every mutation
    whose name starts with a destructive verb has to be classified or explicitly
    excused in UNCLASSIFIED. This is what caught abortCloudBackup running with
    no confirmation at all while starting the same backup asked first.
    """
    text = CONTROLLER.read_text(encoding="utf-8")
    names = set(re.findall(r"Future<OperationReceipt\?>\s+(\w+)\s*\(", text))
    gaps = []
    for name in sorted(names):
        if not DESTRUCTIVE_VERB.match(name):
            continue
        if name in GUARDED or name in UNCLASSIFIED:
            continue
        gaps.append(
            f"{CONTROLLER}: {name}() reads as destructive but is in neither "
            f"CRITICAL nor HIGH, so no call site of it is checked"
        )
    # A name removed from the controller but left in a list is the same problem
    # in reverse: the audit looks like it covers something it does not.
    for name in sorted(GUARDED):
        if name not in names:
            gaps.append(
                f"{CONTROLLER}: {name}() is classified but no longer exists"
            )
    return gaps


def functions(text: str):
    """Yield (name, body) for each function in a Dart file.

    Dart has no reflection available here and a real parser would be overkill,
    so functions are split on their signature line and closed by brace balance.
    That is enough because the property under test is local: the confirmation
    and the call have to live in the same function, or in a helper it calls.

    The signature's parentheses must be skipped before looking for the body.
    Taking the first `{` after the name instead finds the *named-parameter*
    block of a function like `_powerAction(ctx, ref, {required String title})`,
    so its body would be read as nothing but a parameter list - which is exactly
    how this audit first reported restart and shut down as unconfirmed when the
    confirmation was sitting in plain sight inside that helper.
    """
    pattern = re.compile(
        r"^\s*(?:static\s+)?(?:Future<.*?>|void|bool)\s+(_?\w+)\s*\(",
        re.M,
    )
    for match in pattern.finditer(text):
        # Walk to the parenthesis that closes the signature.
        depth = 1
        index = match.end()
        while index < len(text) and depth:
            if text[index] == "(":
                depth += 1
            elif text[index] == ")":
                depth -= 1
            index += 1
        if depth:
            continue

        start = text.find("{", index)
        if start == -1:
            continue
        # An arrow body (`=> ...;`) has no braces of its own; the next `{` would
        # belong to an unrelated later function.
        arrow = text.find("=>", index)
        if arrow != -1 and arrow < start:
            end = text.find(";", arrow)
            if end != -1:
                yield match.group(1), text[arrow:end]
            continue

        depth = 0
        index = start
        while index < len(text):
            char = text[index]
            if char == "{":
                depth += 1
            elif char == "}":
                depth -= 1
                if depth == 0:
                    break
            index += 1
        yield match.group(1), text[start : index + 1]


def resolve(name: str, bodies: dict[str, str], marker: str,
            seen: frozenset[str] = frozenset()) -> bool:
    """Whether [name] contains [marker], directly or via a helper it calls.

    Several screens funnel related actions through a shared helper - restart and
    shut down both delegate to `_powerAction`, which is where their confirmation
    actually lives. Requiring the marker in the calling function alone would
    report those as unguarded, so delegation is followed. Only helpers defined in
    the same file are followed, and `seen` keeps mutual recursion from hanging.
    """
    if name in seen:
        return False
    body = bodies.get(name)
    if body is None:
        return False
    if marker in body:
        return True
    seen = seen | {name}
    for helper in re.findall(r"\b(_\w+)\s*\(", body):
        if helper != name and resolve(helper, bodies, marker, seen):
            return True
    return False


def main(roots: list[str]) -> int:
    problems: list[str] = classification_gaps()
    guarded_sites = 0

    # Select by what a file *does*, not by what it is called. Listing suffixes
    # (`*_screen.dart`, `*_sheet.dart`, ...) silently excluded `job_center.dart`,
    # which calls abortJob: the audit reported a confident green while never
    # looking at it. A naming convention is not an enforcement mechanism, and any
    # file that reads the action controller can reach a destructive method.
    files = []
    for root in roots:
        files.extend(sorted(Path(root).rglob("*.dart")))

    for path in sorted(set(files)):
        text = path.read_text(encoding="utf-8")
        if "serverActionControllerProvider" not in text:
            continue
        # The controller defines these methods rather than calling them from a
        # screen; its own call sites are the repository, not the user.
        if path == CONTROLLER:
            continue
        bodies = dict(functions(text))
        for name, body in bodies.items():
            called = {
                method
                for method in GUARDED
                if re.search(rf"\.{method}\s*\(", body)
            }
            if not called:
                continue
            confirms = resolve(name, bodies, "confirmDestructiveAction")
            typed = resolve(name, bodies, "MutationImpact.critical")
            line = text[: text.find(body)].count("\n") + 1
            for method in sorted(called):
                if not confirms:
                    problems.append(
                        f"{path}:{line}: {name}() calls {method}() "
                        f"without confirmDestructiveAction"
                    )
                    continue
                if method in CRITICAL and not typed:
                    problems.append(
                        f"{path}:{line}: {name}() calls irreversible "
                        f"{method}() but does not use MutationImpact.critical"
                    )
                    continue
                guarded_sites += 1

    for problem in problems:
        print(problem, file=sys.stderr)

    if problems:
        print(
            f"Confirmation audit found {len(problems)} unguarded call site(s).",
            file=sys.stderr,
        )
        return 1

    print(
        f"Confirmation audit clean: {guarded_sites} destructive call site(s), "
        f"all confirmed"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:] or ["lib"]))
