import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/apps/domain/app_configuration.dart';

void main() {
  group('AppConfiguration.fromJson', () {
    test('parses catalog app config with current values', () {
      final config = AppConfiguration.fromJson({
        'app_id': 'immich',
        'name': 'immich',
        'catalog_app': 'immich',
        'train': 'stable',
        'app_version': '1.0.0',
        'values': {'port': 8080, 'image_repository': 'immich-app/immich'},
      });
      expect(config.appId, 'immich');
      expect(config.name, 'immich');
      expect(config.catalogApp, 'immich');
      expect(config.train, 'stable');
      expect(config.version, '1.0.0');
      expect(config.values['port'], 8080);
      expect(config.canReconfigure, isTrue);
    });

    test('falls back when fields are missing', () {
      final config = AppConfiguration.fromJson({'name': 'mystery'});
      expect(config.appId, '');
      expect(config.name, 'mystery');
      expect(config.catalogApp, isNull);
      expect(config.train, isNull);
      expect(config.version, isNull);
      expect(config.values, isEmpty);
      expect(config.canReconfigure, isFalse);
    });

    test('treats non-map values as an empty values object', () {
      final config = AppConfiguration.fromJson({
        'app_id': 'immich',
        'name': 'immich',
        'values': 'not-a-map',
      });
      expect(config.values, isEmpty);
    });

    test('accepts alternative field names for catalog reference', () {
      final config = AppConfiguration.fromJson({
        'app_id': 'x',
        'name': 'x',
        'app_catalog': 'plex',
        'version': '2.0.0',
        'values': <String, Object?>{},
      });
      expect(config.catalogApp, 'plex');
      expect(config.version, '2.0.0');
    });
  });
}
