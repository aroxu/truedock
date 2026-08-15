import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/data_protection/domain/replication_configuration.dart';
import 'package:true_dock/features/data_protection/domain/task_schedule.dart';

const _base = ReplicationConfiguration(
  name: 'Nightly offsite',
  direction: ReplicationDirection.push,
  transport: ReplicationTransport.ssh,
  sshCredentialId: 3,
  sourceDatasets: ['tank/media'],
  targetDataset: 'backup/media',
);

void main() {
  group('toApiJson', () {
    test('emits the documented replication.create fields', () {
      final json = _base.toApiJson();
      expect(json['name'], 'Nightly offsite');
      expect(json['direction'], 'PUSH');
      expect(json['transport'], 'SSH');
      expect(json['ssh_credentials'], 3);
      expect(json['source_datasets'], ['tank/media']);
      expect(json['target_dataset'], 'backup/media');
      expect(json['recursive'], false);
      expect(json['auto'], true);
      expect(json['enabled'], true);
      expect(json['retention_policy'], 'SOURCE');
      expect(json['also_include_naming_schema'], isA<List<String>>());
      expect(json['schedule'], isA<Map<String, Object?>>());
    });

    test('omits ssh_credentials for a LOCAL transport', () {
      final json = _base
          .copyWith(
            transport: ReplicationTransport.local,
            clearSshCredential: true,
          )
          .toApiJson();
      expect(json['transport'], 'LOCAL');
      expect(json.containsKey('ssh_credentials'), isFalse);
    });

    test('sends retention fields only for the CUSTOM policy', () {
      final source = _base.toApiJson();
      expect(source.containsKey('lifetime_value'), isFalse);
      expect(source.containsKey('lifetime_unit'), isFalse);

      final custom = _base
          .copyWith(
            retentionPolicy: ReplicationRetentionPolicy.custom,
            lifetimeValue: 30,
            lifetimeUnit: ReplicationLifetimeUnit.day,
          )
          .toApiJson();
      expect(custom['retention_policy'], 'CUSTOM');
      expect(custom['lifetime_value'], 30);
      expect(custom['lifetime_unit'], 'DAY');
    });

    test('omits the schedule when the task is manual only', () {
      final json = _base.copyWith(auto: false).toApiJson();
      expect(json['auto'], false);
      expect(json.containsKey('schedule'), isFalse);
    });

    test('sends SSH+NETCAT verbatim', () {
      final json = _base
          .copyWith(transport: ReplicationTransport.sshNetcat)
          .toApiJson();
      expect(json['transport'], 'SSH+NETCAT');
      expect(json['ssh_credentials'], 3);
    });
  });

  group('validate', () {
    test('accepts a complete push task', () {
      expect(validateReplicationConfiguration(_base), isEmpty);
    });

    test('requires a name', () {
      final errors = validateReplicationConfiguration(
        _base.copyWith(name: '  '),
      );
      expect(errors['name'], isNotNull);
    });

    test('requires at least one source dataset', () {
      final errors = validateReplicationConfiguration(
        _base.copyWith(sourceDatasets: const []),
      );
      expect(errors['sourceDatasets'], isNotNull);
    });

    test('requires a target dataset', () {
      final errors = validateReplicationConfiguration(
        _base.copyWith(targetDataset: ''),
      );
      expect(errors['targetDataset'], isNotNull);
    });

    test('requires an SSH connection for SSH transports', () {
      final errors = validateReplicationConfiguration(
        _base.copyWith(clearSshCredential: true),
      );
      expect(errors['sshCredentials'], isNotNull);
    });

    test('does not require an SSH connection for LOCAL', () {
      final errors = validateReplicationConfiguration(
        _base.copyWith(
          transport: ReplicationTransport.local,
          clearSshCredential: true,
        ),
      );
      expect(errors['sshCredentials'], isNull);
    });

    test('rejects a local task replicating onto one of its sources', () {
      final errors = validateReplicationConfiguration(
        _base.copyWith(
          transport: ReplicationTransport.local,
          clearSshCredential: true,
          targetDataset: 'tank/media',
        ),
      );
      expect(errors['targetDataset'], contains('same as a source'));
    });

    test('rejects a naming schema containing a slash', () {
      final errors = validateReplicationConfiguration(
        _base.copyWith(namingSchema: 'auto/%Y'),
      );
      expect(errors['namingSchema'], isNotNull);
    });

    test('rejects a custom retention below 1', () {
      final errors = validateReplicationConfiguration(
        _base.copyWith(
          retentionPolicy: ReplicationRetentionPolicy.custom,
          lifetimeValue: 0,
        ),
      );
      expect(errors['lifetimeValue'], isNotNull);
    });

    test('validates the schedule only when auto is on', () {
      const badSchedule = TaskSchedule(minute: 'abc');
      final auto = validateReplicationConfiguration(
        _base.copyWith(schedule: badSchedule),
      );
      expect(auto['minute'], isNotNull);

      final manual = validateReplicationConfiguration(
        _base.copyWith(auto: false, schedule: badSchedule),
      );
      expect(manual['minute'], isNull);
    });
  });

  group('enum mapping', () {
    test('direction round-trips through the API value', () {
      expect(
        ReplicationDirectionApi.fromApi('PULL'),
        ReplicationDirection.pull,
      );
      expect(
        ReplicationDirectionApi.fromApi('PUSH'),
        ReplicationDirection.push,
      );
      expect(ReplicationDirectionApi.fromApi(null), ReplicationDirection.push);
    });

    test('transport knows when SSH credentials are required', () {
      expect(ReplicationTransport.ssh.requiresSshCredentials, isTrue);
      expect(ReplicationTransport.sshNetcat.requiresSshCredentials, isTrue);
      expect(ReplicationTransport.local.requiresSshCredentials, isFalse);
    });
  });
}
