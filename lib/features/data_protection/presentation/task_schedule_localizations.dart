import '../../../l10n/app_localizations.dart';
import '../domain/task_schedule.dart';

/// Localized names for the shared schedule control.
///
/// Extracted so every editor that takes a `{minute, hour, dom, month, dow}`
/// object — the data-protection tasks and `cronjob` — renders the presets and
/// the summary identically. Keeping a private copy per sheet is how two
/// schedule pickers drift into describing the same schedule differently.
extension TaskScheduleLocalizations on AppLocalizations {
  String schedulePresetLabel(TaskSchedulePreset preset) => switch (preset) {
    TaskSchedulePreset.hourly => taskPresetHourly,
    TaskSchedulePreset.daily => taskPresetDaily,
    TaskSchedulePreset.weekly => taskPresetWeekly,
    TaskSchedulePreset.monthly => taskPresetMonthly,
    TaskSchedulePreset.custom => taskPresetCustom,
  };

  String scheduleSummary(
    TaskSchedule schedule,
  ) => switch (schedule.summaryCode) {
    TaskScheduleSummaryCode.everyHour => taskScheduleEveryHour,
    TaskScheduleSummaryCode.everySundayMidnight => taskScheduleEverySunday,
    TaskScheduleSummaryCode.firstOfMonthMidnight => taskScheduleFirstOfMonth,
    TaskScheduleSummaryCode.everyDayMidnight => taskScheduleEveryDay,
    TaskScheduleSummaryCode.cron => taskScheduleCron(schedule.cronExpression),
  };
}
