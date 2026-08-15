import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/storage/domain/smb_acl_configuration.dart';

void main() {
  // Shapes pinned to a live 25.10 server (tool/live_mutation_probe.dart):
  // entries use ae_type/ae_perm and identify the principal with ae_who_str,
  // ae_who_sid, or ae_who_id. There is no permset or ae_qualified_name.
  group('SmbAclEntry.fromJson', () {
    test('parses a user allow entry', () {
      final entry = SmbAclEntry.fromJson({
        'ae_who_str': 'alice',
        'ae_who_id': {'id_type': 'USER', 'xid': 1001},
        'ae_type': 'ALLOWED',
        'ae_perm': 'CHANGE',
        'ae_who_sid': 'S-1-5-21-1-2-3-1001',
      });
      expect(entry.qualifiedName, 'user:alice');
      expect(entry.kind, SmbAclPrincipalKind.user);
      expect(entry.permission, SmbSharePermission.change);
      expect(entry.permType, SmbAclPermType.allowed);
      expect(entry.sid, 'S-1-5-21-1-2-3-1001');
      expect(entry.principalName, 'alice');
    });

    test('derives the group kind from ae_who_id', () {
      final entry = SmbAclEntry.fromJson({
        'ae_who_str': 'staff',
        'ae_who_id': {'id_type': 'GROUP', 'xid': 2001},
        'ae_type': 'ALLOWED',
        'ae_perm': 'FULL',
      });
      expect(entry.permission, SmbSharePermission.full);
      expect(entry.kind, SmbAclPrincipalKind.group);
      expect(entry.qualifiedName, 'group:staff');
      expect(entry.principalName, 'staff');
      expect(entry.sid, isNull);
    });

    test('parses a deny entry', () {
      final entry = SmbAclEntry.fromJson({
        'ae_who_str': 'contractors',
        'ae_who_id': {'id_type': 'GROUP', 'xid': 2002},
        'ae_type': 'DENIED',
        'ae_perm': 'READ',
      });
      expect(entry.permission, SmbSharePermission.read);
      expect(entry.permType, SmbAclPermType.denied);
      expect(entry.kind, SmbAclPrincipalKind.group);
    });

    test('falls back to NONE for an unrecognized ae_perm', () {
      final entry = SmbAclEntry.fromJson({
        'ae_who_str': 'mallory',
        'ae_who_id': {'id_type': 'USER', 'xid': 1002},
        'ae_type': 'ALLOWED',
        'ae_perm': 'BOGUS',
      });
      expect(entry.permission, SmbSharePermission.none);
    });

    test('treats a missing ae_type as allowed', () {
      final entry = SmbAclEntry.fromJson({
        'ae_who_str': 'builtin:administrators',
        'ae_perm': 'FULL',
      });
      expect(entry.permType, SmbAclPermType.allowed);
      expect(entry.kind, SmbAclPrincipalKind.other);
      expect(entry.principalName, 'administrators');
    });

    // A SID-only entry has no name to show, so the SID stands in for it.
    test('falls back to the SID when no name is returned', () {
      final entry = SmbAclEntry.fromJson({
        'ae_who_sid': 'S-1-1-0',
        'ae_type': 'ALLOWED',
        'ae_perm': 'FULL',
      });
      expect(entry.qualifiedName, 'S-1-1-0');
      expect(entry.sid, 'S-1-1-0');
      expect(entry.kind, SmbAclPrincipalKind.other);
    });
  });

  group('SmbAclEntry.toApiJson', () {
    test('identifies the principal by SID when one is known', () {
      const entry = SmbAclEntry(
        qualifiedName: 'user:alice',
        kind: SmbAclPrincipalKind.user,
        permission: SmbSharePermission.change,
        permType: SmbAclPermType.allowed,
        sid: 'S-1-5-21-1-2-3-1001',
      );
      expect(entry.toApiJson(), {
        'ae_type': 'ALLOWED',
        'ae_perm': 'CHANGE',
        'ae_who_sid': 'S-1-5-21-1-2-3-1001',
      });
    });

    // The user:/group: prefix is a TrueDock display convention; the server
    // wants the bare name.
    test('falls back to the bare name when no SID is known', () {
      const entry = SmbAclEntry(
        qualifiedName: 'group:staff',
        kind: SmbAclPrincipalKind.group,
        permission: SmbSharePermission.full,
        permType: SmbAclPermType.denied,
      );
      expect(entry.toApiJson(), {
        'ae_type': 'DENIED',
        'ae_perm': 'FULL',
        'ae_who_str': 'staff',
      });
    });
  });

  group('SmbAclEntry equality and copyWith', () {
    test('equals ignores sid', () {
      const a = SmbAclEntry(
        qualifiedName: 'user:alice',
        kind: SmbAclPrincipalKind.user,
        permission: SmbSharePermission.read,
        permType: SmbAclPermType.allowed,
        sid: 'sid-a',
      );
      const b = SmbAclEntry(
        qualifiedName: 'user:alice',
        kind: SmbAclPrincipalKind.user,
        permission: SmbSharePermission.read,
        permType: SmbAclPermType.allowed,
        sid: 'sid-b',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('copyWith overrides only the supplied fields', () {
      const base = SmbAclEntry(
        qualifiedName: 'user:alice',
        kind: SmbAclPrincipalKind.user,
        permission: SmbSharePermission.read,
        permType: SmbAclPermType.allowed,
      );
      final updated = base.copyWith(permission: SmbSharePermission.full);
      expect(updated.qualifiedName, 'user:alice');
      expect(updated.permission, SmbSharePermission.full);
      expect(updated.permType, SmbAclPermType.allowed);
    });
  });

  group('smbQualifiedPrincipalName', () {
    test('prefixes a bare name with the kind prefix', () {
      expect(
        smbQualifiedPrincipalName(SmbAclPrincipalKind.user, 'alice'),
        'user:alice',
      );
      expect(
        smbQualifiedPrincipalName(SmbAclPrincipalKind.group, 'staff'),
        'group:staff',
      );
    });

    test('returns the input unchanged when it already carries a prefix', () {
      expect(
        smbQualifiedPrincipalName(SmbAclPrincipalKind.user, 'builtin:admins'),
        'builtin:admins',
      );
    });
  });
}
