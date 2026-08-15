import 'package:integration_test/integration_test.dart';

import '../test/features/shell/app_settings_navigation_test.dart' as suite;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  suite.main();
}
