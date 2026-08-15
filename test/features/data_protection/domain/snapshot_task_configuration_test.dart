import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/data_protection/domain/snapshot_task_configuration.dart';

void main() {
  test('serializes the documented periodic snapshot create payload', () {
    const request = CreateSnapshotTaskRequest(
      dataset: 'tank/documents',
      recursive: true,
      lifetimeValue: 2,
      lifetimeUnit: SnapshotLifetimeUnit.week,
      enabled: true,
      excludes: ['tank/documents/cache'],
      namingSchema: 'auto-%Y-%m-%d_%H-%M',
      allowEmpty: false,
      schedule: SnapshotTaskSchedule(
        minute: '30',
        hour: '*/2',
        dayOfMonth: '*',
        month: '*',
        dayOfWeek: '1-5',
        begin: '06:30',
        end: '22:30',
      ),
    );

    expect(request.validate(), isEmpty);
    expect(request.toApiJson(), {
      'dataset': 'tank/documents',
      'recursive': true,
      'lifetime_value': 2,
      'lifetime_unit': 'WEEK',
      'enabled': true,
      'exclude': ['tank/documents/cache'],
      'naming_schema': 'auto-%Y-%m-%d_%H-%M',
      'allow_empty': false,
      'schedule': {
        'minute': '30',
        'hour': '*/2',
        'dom': '*',
        'month': '*',
        'dow': '1-5',
        'begin': '06:30',
        'end': '22:30',
      },
    });
  });

  test('drops exclusions when recursive snapshots are disabled', () {
    const request = CreateSnapshotTaskRequest(
      dataset: 'tank/documents',
      recursive: false,
      lifetimeValue: 1,
      lifetimeUnit: SnapshotLifetimeUnit.day,
      enabled: true,
      excludes: ['outside/data'],
      namingSchema: 'daily-%Y-%m-%d',
      allowEmpty: true,
      schedule: SnapshotTaskSchedule(hour: '00'),
    );

    expect(request.validate(), isEmpty);
    expect(request.toApiJson()['exclude'], isEmpty);
  });

  test('validates retention, cron fields, time window, and exclusions', () {
    const request = CreateSnapshotTaskRequest(
      dataset: 'tank/documents',
      recursive: true,
      lifetimeValue: 0,
      lifetimeUnit: SnapshotLifetimeUnit.hour,
      enabled: true,
      excludes: ['other/data'],
      namingSchema: 'invalid/name',
      allowEmpty: true,
      schedule: SnapshotTaskSchedule(minute: 'bad', begin: '29:00'),
    );

    final errors = request.validate();

    expect(errors, containsPair('lifetimeValue', isNotEmpty));
    expect(errors, containsPair('namingSchema', isNotEmpty));
    expect(errors, containsPair('excludes', isNotEmpty));
    expect(errors, containsPair('minute', isNotEmpty));
    expect(errors, containsPair('begin', isNotEmpty));
  });

  test('creates readable schedule presets', () {
    expect(
      SnapshotTaskSchedule.forPreset(SnapshotSchedulePreset.weekly).summary,
      'Every Sunday at 00:00',
    );
    expect(
      SnapshotTaskSchedule.forPreset(
        SnapshotSchedulePreset.monthly,
      ).toApiJson(),
      containsPair('dom', '1'),
    );
  });

  test('summarizes retention impact without retaining snapshot names', () {
    final impact = SnapshotRetentionImpact.fromResult({
      'will_change': ['tank/data@one', 'tank/data@two'],
      'will_drop': ['tank/data@three'],
    });

    expect(impact.total, 3);
    expect(impact.hasChanges, isTrue);
    expect(impact.counts, {'will_change': 2, 'will_drop': 1});
    expect(impact.toString(), isNot(contains('tank/data@one')));
  });
}
