#!/usr/bin/env python3
"""Static audit: compare the payload keys TrueDock sends against the schemas
the server advertises.

Reads a schema dump produced by `dart run tool/schema_dump.dart` and scans the
Dart sources for RPC call sites, extracting the top-level string keys of each
object literal passed as a parameter. Any key that is not in the method's
`accepts` schema is reported; when the schema sets `additionalProperties:
false` the server rejects the whole call, which is how the `app.delete`
`keep_volumes` defect was found.

This is a heuristic reader, not a Dart parser: it reports candidates for human
review rather than failing a build. Keys built dynamically (spread operators,
conditional entries with computed names, or maps assembled in a domain
`toApiJson`) are followed one level into the corresponding domain class when
the call site passes `configuration.toApiJson()`.

Usage:
  python3 tool/schema_audit.py [schemaDump] [libRoot]
"""

import json
import re
import sys
from pathlib import Path

SCHEMA = Path(sys.argv[1] if len(sys.argv) > 1 else '/tmp/td_all_methods.json')
LIB = Path(sys.argv[2] if len(sys.argv) > 2 else 'lib')

dump = json.loads(SCHEMA.read_text())
methods = dump['methods']
version = dump['version']


def walk(node, keys, depth=0):
    """Collects every property name reachable from a schema node.

    The middleware nests object schemas four ways that all have to be followed
    or the audit reports false positives: `anyOf` variants (a dataset create
    payload is a union of the filesystem and volume shapes), `oneOf` variants
    behind a discriminator (an alert destination's `attributes` is one exact
    variant chosen by its `type`), object properties that are themselves
    objects, and `items` schemas for arrays of objects such as a vdev list.

    Returns whether any visited object rejects unknown keys.
    """
    if depth > 6 or not isinstance(node, dict):
        return False
    strict = False
    props = node.get('properties')
    if isinstance(props, dict):
        keys.update(props)
        if node.get('additionalProperties') is False:
            strict = True
        for prop in props.values():
            strict |= walk(prop, keys, depth + 1)
    for key in ('anyOf', 'oneOf'):
        for variant in node.get(key) or []:
            strict |= walk(variant, keys, depth + 1)
    items = node.get('items')
    if isinstance(items, dict):
        strict |= walk(items, keys, depth + 1)
    elif isinstance(items, list):
        for item in items:
            strict |= walk(item, keys, depth + 1)
    return strict


def allowed_keys(method):
    """Union of every property name `method` accepts anywhere in its schema,
    plus whether any of those objects rejects unknown keys."""
    entry = methods.get(method)
    if entry is None:
        return None, False
    keys = set()
    strict = False
    for arg in entry.get('accepts') or []:
        strict |= walk(arg, keys)
    # `query` methods take [filters, options]; the options object is shared
    # middleware-wide and is not described in every method's accepts schema.
    if method.endswith('.query') or method == 'alert.list':
        keys.update({
            'limit', 'offset', 'order_by', 'select', 'count', 'get',
            'relationships', 'force_sql_filters', 'extra',
        })
    return keys, strict


# Every `'some.method'` string literal followed by a params list, plus the
# raw text that follows it, so we can pull the object keys out.
CALL = re.compile(r"'([a-z_]+(?:\.[a-z_0-9]+)+)'")
KEY = re.compile(r"'([a-z_][a-z_0-9]*)'\s*:")


def balanced_slice(text, start):
    """Returns the text from `start` through the matching close of the first
    bracket found, so we only look at one call's parameter list."""
    depth = 0
    opened = False
    for i in range(start, min(len(text), start + 4000)):
        c = text[i]
        if c in '([{':
            depth += 1
            opened = True
        elif c in ')]}':
            depth -= 1
            if opened and depth <= 0:
                return text[start:i + 1]
    return text[start:start + 4000]


# Most mutation payloads are not written at the call site: the repository
# passes `configuration.toApiJson()` and the keys live in a domain class. That
# is exactly where the pool.create defects hid, so resolve those bodies and
# audit their keys against the method the repository sends them to.
# Payload builders take three forms in this codebase: a bare `toApiJson()`,
# a `toApiJson(x)` that needs a companion object (cloud-sync credentials, the
# original account row), and a `changedFields(baseline)` diff for methods that
# must not receive unchanged fields.
TO_API_JSON = re.compile(
    r'Map<String,\s*Object\?>\s+(?:toApiJson|changedFields)\([^)]*\)\s*(\{|=>)')


def api_json_bodies():
    """Maps a Dart type name to the set of top-level keys its toApiJson()
    produces. Nested object values are included; they are checked against the
    same flattened key set the schema walk produces."""
    bodies = {}
    for path in LIB.rglob('*.dart'):
        text = path.read_text()
        for match in TO_API_JSON.finditer(text):
            # walk backwards to the enclosing class declaration
            head = text[:match.start()]
            classes = re.findall(r'class\s+([A-Za-z0-9_]+)', head)
            if not classes:
                continue
            body = balanced_slice(text, match.end() - 1)
            bodies.setdefault(classes[-1], set()).update(KEY.findall(body))
    return bodies


API_JSON = api_json_bodies()

# `configuration.toApiJson()` tells us a payload is delegated but not which
# type. The repository's parameter declarations do, so map parameter type ->
# keys by reading the enclosing method signature.
DELEGATED = re.compile(
    r'([A-Za-z0-9_]+)\s+(?:configuration|request|next|baseline|fields)\b')


def delegated_keys(text, call_end):
    """Keys of the domain payload a call site delegates to, or None."""
    window = balanced_slice(text, call_end)
    if 'toApiJson(' not in window and 'fields' not in window:
        return None
    # the parameter type is declared above the call, in the same method
    head = text[max(0, call_end - 1500):call_end]
    types = DELEGATED.findall(head)
    for name in reversed(types):
        if name in API_JSON:
            return name, API_JSON[name]
    return None


delegated_findings = []
for path in sorted(LIB.rglob('*.dart')):
    if path.name.startswith('app_localizations'):
        continue
    # Job method names are server-provided identifiers translated for display,
    # not methods TrueDock invokes. Auditing them as call sites makes renamed
    # historical job names look like unsupported RPC calls.
    if path.name == 'job_localizations.dart':
        continue
    text = path.read_text()
    for match in CALL.finditer(text):
        method = match.group(1)
        if method not in methods:
            continue
        resolved = delegated_keys(text, match.end())
        if resolved is None:
            continue
        type_name, sent = resolved
        allowed, strict = allowed_keys(method)
        if allowed is None or not sent:
            continue
        extra = sorted(sent - allowed)
        if extra:
            delegated_findings.append((method, type_name, extra, strict))

findings = []
unadvertised = []
for path in sorted(LIB.rglob('*.dart')):
    if path.name.startswith('app_localizations'):
        continue
    if path.name == 'job_localizations.dart':
        continue
    text = path.read_text()
    for match in CALL.finditer(text):
        method = match.group(1)
        if method not in methods:
            # namespace check keeps filenames and l10n keys out of the report
            if method.split('.')[0] in {m.split('.')[0] for m in methods}:
                unadvertised.append((str(path), method))
            continue
        window = balanced_slice(text, match.end())
        # `extra` is a documented free-form per-endpoint object, so its inner
        # keys are not described in the accepts schema and must not be
        # reported. Drop everything from the first `'extra':` onwards.
        scan = window.split("'extra'")[0] if "'extra'" in window else window
        sent = set(KEY.findall(scan))
        # The authenticated /_upload endpoint embeds an RPC request as
        # {'method': 'update.file', 'params': [...]}. `params` belongs to the
        # JSON-RPC envelope; only the object inside it is checked against the
        # method's accepts schema.
        prefix = text[max(0, match.start() - 80):match.start()]
        if re.search(r"'method'\s*:\s*$", prefix):
            sent.discard('params')
        if not sent:
            continue
        allowed, strict = allowed_keys(method)
        if allowed is None:
            continue
        extra = sorted(sent - allowed)
        if extra:
            findings.append((str(path), method, extra, strict))

def first_arg_is_scalar(method):
    """True when the method's first parameter is a scalar (string/int/bool),
    so passing an object literal first is a shape error rather than a naming
    one. This is the class of defect that hid in system.reboot."""
    accepts = methods[method].get('accepts') or []
    if not accepts or not isinstance(accepts[0], dict):
        return False
    first = accepts[0]
    if (first.get('properties') or
            first.get('anyOf') or
            first.get('oneOf') or
            first.get('items')):
        return False
    return first.get('type') in {'string', 'integer', 'boolean', 'number'}


def required_object_keys(method):
    """Required property names of the method's object arguments.

    Only unambiguous cases are collected: a union argument (`anyOf` or a
    discriminated `oneOf`) has no single required set, so those are skipped
    rather than guessed at.
    """
    required = set()
    for arg in methods[method].get('accepts') or []:
        if not isinstance(arg, dict) or arg.get('anyOf') or arg.get('oneOf'):
            continue
        if isinstance(arg.get('properties'), dict):
            required.update(arg.get('required') or [])
    return required


OBJECT_FIRST = re.compile(r"^\s*[\[(]\s*\{")
shape_findings = []
for path in sorted(LIB.rglob('*.dart')):
    if path.name.startswith('app_localizations'):
        continue
    text = path.read_text()
    for match in CALL.finditer(text):
        method = match.group(1)
        if method not in methods or not first_arg_is_scalar(method):
            continue
        window = balanced_slice(text, match.end())
        # skip the method-name-only references (capability gating, logs)
        if not OBJECT_FIRST.search(window):
            continue
        shape_findings.append((str(path), method))

# Required object keys the call site never mentions. A missing required field
# is rejected the same way an unknown one is, and is just as invisible to a
# fixture that agrees with the app.
missing_findings = []
for path in sorted(LIB.rglob('*.dart')):
    if path.name.startswith('app_localizations'):
        continue
    text = path.read_text()
    for match in CALL.finditer(text):
        method = match.group(1)
        if method not in methods:
            continue
        required = required_object_keys(method)
        if not required:
            continue
        window = balanced_slice(text, match.end())
        if '{' not in window:
            continue
        sent = set(KEY.findall(window))
        if not sent:
            continue
        missing = sorted(required - sent)
        if missing:
            missing_findings.append((str(path), method, missing))

# ---------------------------------------------------------------------------
# Method names built by interpolation.
#
# CALL only matches `'some.method'` string literals, so a name assembled at
# runtime is invisible to every check above. `ConfigurableService` builds
# `'$namespace.config'` and `'$namespace.update'` for five services, which is
# ten methods and 27 payload keys the audit silently never examined - while
# still printing its confident summary.
#
# The keys turn out to be correct today, but "we checked and it was fine" is not
# the same as "it is checked". Two things happen here: the service table is
# resolved and validated against the real schema, and any *other* interpolated
# method name is reported, so a second dynamic call site cannot quietly inherit
# the same blind spot.
DYNAMIC = re.compile(r"'\$\{?(\w+)\}?\.([a-z_0-9]+)'")
SERVICE_FILE = LIB / 'features/system/domain/service_configuration.dart'

dynamic_findings = []
unresolved_dynamic = []

if SERVICE_FILE.exists():
    service_src = SERVICE_FILE.read_text()

    # service -> payload keys, read from the serviceFields table.
    block = service_src[service_src.index('const serviceFields'):]
    block = block[:block.index('\n};')]
    service_keys = {}
    current = None
    for line in block.splitlines():
        header = re.search(r'ConfigurableService\.(\w+):', line)
        if header:
            current = header.group(1)
            service_keys[current] = set()
        key = re.search(r"key:\s*'([^']+)'", line)
        if key and current:
            service_keys[current].add(key.group(1))

    for service, sent in sorted(service_keys.items()):
        for suffix in ('config', 'update'):
            method = f'{service}.{suffix}'
            if method not in methods:
                unadvertised.append((str(SERVICE_FILE), method))
                continue
            if suffix == 'config':
                continue  # a read takes no payload
            allowed, strict = allowed_keys(method)
            if allowed is None:
                continue
            extra = sorted(sent - allowed)
            if extra:
                dynamic_findings.append((method, extra, strict))

# Any interpolated method name outside the resolved service table.
for path_ in sorted(LIB.rglob('*.dart')):
    if path_.name.startswith('app_localizations'):
        continue
    if path_ == SERVICE_FILE:
        continue
    for match in DYNAMIC.finditer(path_.read_text()):
        unresolved_dynamic.append((str(path_), match.group(0)))

print(f'audited against {version}: {len(methods)} advertised methods')
# Methods TrueDock references that 25.10 does not advertise, but which are
# reached only through capability gating, so their absence degrades the UI
# instead of failing a call. Listing them here keeps the audit output
# actionable; anything not listed is a real defect.
GATED = {
    'sharing.webshare.query',   # gated by ServerResourcesRepository._section
    'container.query',          # gated by ServerCapabilities.supportsContainers
    'container.start',
    'container.stop',
    'container.restart',
    'container.update',
    'container.poweroff',
}
unadvertised = [(p, m) for p, m in unadvertised if m not in GATED]

if unadvertised:
    print('\nUNADVERTISED METHODS (not capability-gated):')
    for path, method in sorted(set(unadvertised)):
        print(f'  {method}  ({path})')

if findings:
    print('\nKEYS NOT IN THE ACCEPTS SCHEMA:')
    for path, method, extra, strict in findings:
        flag = 'REJECTED (additionalProperties: false)' if strict else 'unknown'
        print(f'  {method}: {", ".join(extra)}  [{flag}]')
        print(f'      {path}')
else:
    print('\nno unexpected payload keys found')

if shape_findings:
    print('\nOBJECT PASSED WHERE A POSITIONAL SCALAR IS EXPECTED:')
    for path, method in sorted(set(shape_findings)):
        print(f'  {method}  ({path})')
else:
    print('no positional-argument shape mismatches found')

if delegated_findings:
    print('\nDOMAIN toApiJson KEYS NOT IN THE ACCEPTS SCHEMA:')
    for method, type_name, extra, strict in sorted(set(map(
        lambda f: (f[0], f[1], tuple(f[2]), f[3]), delegated_findings))):
        flag = 'REJECTED (additionalProperties: false)' if strict else 'unknown'
        print(f'  {method} <- {type_name}: {", ".join(extra)}  [{flag}]')
else:
    print('no unexpected keys in delegated payloads')

if dynamic_findings:
    print('\nINTERPOLATED-METHOD KEYS NOT IN THE ACCEPTS SCHEMA:')
    for method, extra, strict in sorted(set(map(
        lambda f: (f[0], tuple(f[1]), f[2]), dynamic_findings))):
        flag = 'REJECTED (additionalProperties: false)' if strict else 'unknown'
        print(f'  {method}: {", ".join(extra)}  [{flag}]')
else:
    print('no unexpected keys in interpolated-method payloads')

if unresolved_dynamic:
    print('\nUNRESOLVED INTERPOLATED METHOD NAMES (not audited):')
    for path_, literal in sorted(set(unresolved_dynamic)):
        print(f'  {literal}  ({path_})')

if missing_findings:
    print('\nREQUIRED KEYS NOT MENTIONED AT THE CALL SITE:')
    for path, method, missing in sorted(set(map(
        lambda f: (f[0], f[1], tuple(f[2])), missing_findings))):
        print(f'  {method}: {", ".join(missing)}  ({path})')
else:
    print('no missing required keys found')

sys.exit(0)
