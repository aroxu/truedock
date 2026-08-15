import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/connection/domain/connection_message.dart';
import 'package:true_dock/features/connection/presentation/connection_message_localizations.dart';
import 'package:true_dock/l10n/app_localizations_ko.dart';

void main() {
  test('client connection failures do not expose English exception detail', () {
    final ko = AppLocalizationsKo();
    const detail = 'The saved vault is damaged.';

    final message = ko.connectionMessage(
      const ConnectionMessage(
        ConnectionMessageCode.appPinAccessFailed,
        detail: detail,
        fallback: detail,
      ),
    );

    expect(message, contains('TrueDock PIN'));
    expect(message, isNot(contains(detail)));
  });

  test('partial connection success uses fully localized copy', () {
    final ko = AppLocalizationsKo();

    expect(
      ko.connectionMessage(
        const ConnectionMessage(
          ConnectionMessageCode.savedSignInFailed,
          detail: 'Could not save the encrypted credential.',
        ),
      ),
      '연결되었지만 로그인 정보를 저장하지 못했습니다.',
    );
  });
}
