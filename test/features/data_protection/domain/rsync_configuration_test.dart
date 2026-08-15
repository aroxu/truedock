import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/data_protection/domain/rsync_configuration.dart';
import 'package:true_dock/features/data_protection/domain/task_schedule.dart';

const _sshBase = RsyncConfiguration(
  path: '/mnt/tank/media',
  user: 'backup',
  direction: RsyncDirection.push,
  mode: RsyncMode.ssh,
  remoteHost: 'offsite.example',
  remotePath: '/srv/media',
  sshCredentialId: 4,
);

const _moduleBase = RsyncConfiguration(
  path: '/mnt/tank/media',
  user: 'backup',
  direction: RsyncDirection.pull,
  mode: RsyncMode.module,
  remoteHost: 'offsite.example',
  remoteModule: 'media',
);

void main() {
  group('toApiJson', () {
    test('emits the documented SSH-mode fields', () {
      final json = _sshBase.toApiJson();
      expect(json['path'], '/mnt/tank/media');
      expect(json['user'], 'backup');
      expect(json['direction'], 'PUSH');
      expect(json['mode'], 'SSH');
      expect(json['remotehost'], 'offsite.example');
      expect(json['remotepath'], '/srv/media');
      expect(json['ssh_credentials'], 4);
      expect(json['enabled'], true);
      expect(json['validate_rpath'], true);
      expect(json['schedule'], isA<Map<String, Object?>>());
      // Module-only fields must not leak into an SSH payload.
      expect(json.containsKey('remotemodule'), isFalse);
    });

    test('emits the documented module-mode fields', () {
      final json = _moduleBase.toApiJson();
      expect(json['mode'], 'MODULE');
      expect(json['remotemodule'], 'media');
      expect(json['direction'], 'PULL');
      // SSH-only fields must not leak into a module payload.
      expect(json.containsKey('remotepath'), isFalse);
      expect(json.containsKey('ssh_credentials'), isFalse);
    });

    test('defaults the port to 22 for SSH and 873 for module', () {
      expect(_sshBase.toApiJson()['remoteport'], 22);
      expect(_moduleBase.toApiJson()['remoteport'], 873);
    });

    test('an explicit port overrides the mode default', () {
      final json = _sshBase.copyWith(remotePort: 2222).toApiJson();
      expect(json['remoteport'], 2222);
    });

    test('omits an empty description', () {
      expect(_sshBase.toApiJson().containsKey('desc'), isFalse);
      final described = _sshBase.copyWith(description: 'Offsite copy');
      expect(described.toApiJson()['desc'], 'Offsite copy');
    });
  });

  group('validate', () {
    test('accepts a complete SSH task', () {
      expect(validateRsyncConfiguration(_sshBase), isEmpty);
    });

    test('accepts a complete module task', () {
      expect(validateRsyncConfiguration(_moduleBase), isEmpty);
    });

    test('requires an absolute local path', () {
      final relative = validateRsyncConfiguration(
        _sshBase.copyWith(path: 'tank/media'),
      );
      expect(relative['path'], contains('absolute'));

      final empty = validateRsyncConfiguration(_sshBase.copyWith(path: ''));
      expect(empty['path'], isNotNull);
    });

    test('requires a user', () {
      final errors = validateRsyncConfiguration(_sshBase.copyWith(user: ' '));
      expect(errors['user'], isNotNull);
    });

    test('requires a remote host', () {
      final errors = validateRsyncConfiguration(
        _sshBase.copyWith(remoteHost: ''),
      );
      expect(errors['remoteHost'], isNotNull);
    });

    test('rejects an out-of-range port', () {
      expect(
        validateRsyncConfiguration(
          _sshBase.copyWith(remotePort: 0),
        )['remotePort'],
        isNotNull,
      );
      expect(
        validateRsyncConfiguration(
          _sshBase.copyWith(remotePort: 70000),
        )['remotePort'],
        isNotNull,
      );
    });

    test('SSH mode requires a remote path and an SSH connection', () {
      final errors = validateRsyncConfiguration(
        _sshBase.copyWith(remotePath: '', clearSshCredential: true),
      );
      expect(errors['remotePath'], isNotNull);
      expect(errors['sshCredentials'], isNotNull);
    });

    test('module mode requires a module name and ignores SSH fields', () {
      final errors = validateRsyncConfiguration(
        _moduleBase.copyWith(remoteModule: ''),
      );
      expect(errors['remoteModule'], isNotNull);
      expect(errors['sshCredentials'], isNull);
      expect(errors['remotePath'], isNull);
    });

    test('validates the schedule', () {
      final errors = validateRsyncConfiguration(
        _sshBase.copyWith(schedule: const TaskSchedule(hour: 'nope')),
      );
      expect(errors['hour'], isNotNull);
    });
  });

  group('enum mapping', () {
    test('mode maps to the documented API values and default ports', () {
      expect(RsyncMode.ssh.apiValue, 'SSH');
      expect(RsyncMode.module.apiValue, 'MODULE');
      expect(RsyncMode.ssh.defaultPort, 22);
      expect(RsyncMode.module.defaultPort, 873);
      expect(RsyncMode.ssh.usesSshCredentials, isTrue);
      expect(RsyncMode.module.usesSshCredentials, isFalse);
    });

    test('direction round-trips through the API value', () {
      expect(RsyncDirectionApi.fromApi('PULL'), RsyncDirection.pull);
      expect(RsyncDirectionApi.fromApi('PUSH'), RsyncDirection.push);
      expect(RsyncDirectionApi.fromApi(null), RsyncDirection.push);
    });
  });
}
