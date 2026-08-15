import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:true_dock/l10n/app_localizations.dart';
import 'package:true_dock/l10n/app_localizations_en.dart';
import 'package:true_dock/l10n/app_localizations_ko.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('pool issue copy follows English plural rules', () {
    expect(l10n.healthPoolIssues(1), '1 pool issue');
    expect(l10n.healthPoolIssues(2), '2 pool issues');
  });

  test('certificate trust copy includes the server authority', () {
    expect(
      l10n.certificateChangedDescription('nas.local'),
      contains('nas.local'),
    );
    expect(
      l10n.certificateTrustDescription('nas.local'),
      contains('nas.local'),
    );
  });

  test('system copy handles saved sign-in counts and versions', () {
    expect(l10n.systemSavedSignIns(1), '1 saved server sign-in');
    expect(l10n.systemSavedSignIns(3), '3 saved server sign-ins');
    expect(l10n.systemCommunityVersion('25.10.2'), 'Community 25.10.2');
  });

  group('Korean locale', () {
    final ko = AppLocalizationsKo();

    test('is registered as a supported locale', () {
      expect(AppLocalizations.supportedLocales, contains(const Locale('ko')));
    });

    test('translates the navigation destinations', () {
      expect(ko.navOverview, '개요');
      expect(ko.navStorage, '스토리지');
      expect(ko.navProtection, '보호');
      expect(ko.navApps, '앱');
      expect(ko.navSystem, '시스템');
      expect(ko.navAppSettings, '앱 설정');
    });

    test('Korean plural copy does not collapse to the English form', () {
      // Korean doesn't pluralize numerically; the count is embedded as a
      // noun-count phrase. The important invariant is that the Korean form
      // is distinct from the English form and keeps the count.
      expect(ko.healthPoolIssues(1), contains('1'));
      expect(ko.healthPoolIssues(1), isNot(contains('pool issue')));
      expect(ko.healthPoolIssues(5), contains('5'));
      expect(ko.systemSavedSignIns(1), contains('1'));
      expect(ko.systemSavedSignIns(3), contains('3'));
    });

    test('keeps placeholders in the translated connection-lost copy', () {
      expect(
        ko.connectionLostTitleNamed('truenas.local'),
        contains('truenas.local'),
      );
      expect(
        ko.serverSwitchDescription('truenas.local'),
        contains('truenas.local'),
      );
    });

    test('translates snapshot retention and scrub schedules', () {
      expect(ko.protectionRetentionHours(1), '1시간');
      expect(ko.protectionRetentionWeeks(2), '2주');
      expect(ko.protectionRetentionMonths(3), '3개월');
      expect(ko.protectionScheduleUnavailable, '일정 정보 없음');
      expect(ko.protectionScrubSchedule('03', '15', '7'), '03:15 · 요일 7');
    });
  });
}
