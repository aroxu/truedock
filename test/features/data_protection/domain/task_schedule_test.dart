import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/data_protection/domain/task_schedule.dart';

void main() {
  group('TaskSchedule', () {
    test('toApiJson uses the documented cron field names', () {
      const schedule = TaskSchedule(
        minute: '30',
        hour: '2',
        dayOfMonth: '1',
        month: '*',
        dayOfWeek: '7',
      );
      expect(schedule.toApiJson(), {
        'minute': '30',
        'hour': '2',
        'dom': '1',
        'month': '*',
        'dow': '7',
      });
    });

    test('fromJson reads the dom/dow abbreviations', () {
      final schedule = TaskSchedule.fromJson({
        'minute': '15',
        'hour': '3',
        'dom': '5',
        'month': '6',
        'dow': '2',
      });
      expect(schedule.minute, '15');
      expect(schedule.hour, '3');
      expect(schedule.dayOfMonth, '5');
      expect(schedule.month, '6');
      expect(schedule.dayOfWeek, '2');
    });

    test('fromJson falls back to safe defaults', () {
      final schedule = TaskSchedule.fromJson(const {});
      expect(schedule.minute, '00');
      expect(schedule.hour, '*');
      expect(schedule.dayOfMonth, '*');
    });

    test('presets produce the expected cron values', () {
      expect(TaskSchedule.forPreset(TaskSchedulePreset.hourly).hour, '*');
      expect(TaskSchedule.forPreset(TaskSchedulePreset.daily).hour, '00');
      expect(TaskSchedule.forPreset(TaskSchedulePreset.weekly).dayOfWeek, '7');
      expect(
        TaskSchedule.forPreset(TaskSchedulePreset.monthly).dayOfMonth,
        '1',
      );
    });

    test('summary describes the common presets', () {
      expect(
        TaskSchedule.forPreset(TaskSchedulePreset.hourly).summary,
        'At the start of every hour',
      );
      expect(
        TaskSchedule.forPreset(TaskSchedulePreset.daily).summary,
        'Every day at 00:00',
      );
      expect(
        TaskSchedule.forPreset(TaskSchedulePreset.weekly).summary,
        'Every Sunday at 00:00',
      );
    });

    test('validate rejects non-cron characters', () {
      const schedule = TaskSchedule(minute: 'abc');
      expect(validateOf(schedule)['minute'], isNotNull);
    });

    test('validate accepts cron ranges and steps', () {
      const schedule = TaskSchedule(
        minute: '0,30',
        hour: '*/2',
        dayOfMonth: '1-15',
      );
      expect(validateOf(schedule), isEmpty);
    });

    test('copyWith preserves untouched fields', () {
      const base = TaskSchedule(minute: '10', hour: '4');
      final next = base.copyWith(hour: '6');
      expect(next.minute, '10');
      expect(next.hour, '6');
    });
  });

  group('SshCredential', () {
    test('fromJson reads id and name', () {
      final credential = SshCredential.fromJson({
        'id': 7,
        'name': 'Offsite backup',
        'type': 'SSH_CREDENTIALS',
      });
      expect(credential.id, 7);
      expect(credential.name, 'Offsite backup');
    });

    test('falls back to a readable name when missing', () {
      final credential = SshCredential.fromJson({'id': 2});
      expect(credential.name, 'SSH connection');
    });
  });
}

Map<String, String> validateOf(TaskSchedule schedule) => schedule.validate();
