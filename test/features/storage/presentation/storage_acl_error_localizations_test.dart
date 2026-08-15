import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/storage/presentation/storage_localizations.dart';
import 'package:true_dock/l10n/app_localizations_en.dart';
import 'package:true_dock/l10n/app_localizations_ko.dart';

void main() {
  test('localizes missing disk identity without changing real values', () {
    final ko = AppLocalizationsKo();

    expect(ko.diskModelLabel('Unknown model'), '알 수 없는 모델');
    expect(ko.diskSerialLabel('No serial'), '시리얼 정보 없음');
    expect(ko.diskModelLabel('QEMU HARDDISK'), 'QEMU HARDDISK');
  });

  test('localizes the TrueNAS pool mountpoint setacl error in Korean', () {
    final message = AppLocalizationsKo().datasetAclSetAclError(
      'The specified path is a ZFS pool mountpoint "(/mnt/truedock_data)"',
    );

    expect(
      message,
      'setacl 오류\n'
      '지정한 경로는 ZFS 풀 탑재 지점입니다. (/mnt/truedock_data)',
    );
  });

  test('keeps unknown server detail under a localized operation title', () {
    expect(
      AppLocalizationsKo().datasetAclSetAclError('Permission denied.'),
      'setacl 오류\nPermission denied.',
    );
    expect(
      AppLocalizationsEn().datasetAclSetAclError('Permission denied.'),
      'setacl error\nPermission denied.',
    );
  });
}
