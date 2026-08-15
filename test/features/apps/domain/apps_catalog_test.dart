import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/apps/domain/apps_catalog.dart';

void main() {
  test(
    'parses searchable catalog metadata without retaining large or private fields',
    () {
      final app = CatalogApp.fromJson({
        'name': 'immich',
        'title': 'Immich',
        'description': 'Self-hosted photo management',
        'healthy': true,
        'recommended': true,
        'latest_human_version': '1.2.3',
        'categories': ['media'],
        'tags': ['photos', 'backup'],
        'app_readme': '<html>must-not-be-modeled</html>',
        'maintainers': [
          {'name': 'Example', 'email': 'must-not-be-modeled@example.com'},
        ],
      }, train: 'stable');

      expect(app.title, 'Immich');
      expect(app.train, 'stable');
      expect(app.recommended, isTrue);
      expect(app.matches('PHOTO'), isTrue);
      expect(app.matches('database'), isFalse);
      expect(app.toString(), isNot(contains('must-not-be-modeled')));
    },
  );

  test('keeps only Docker configuration summaries needed by the UI', () {
    final configuration = DockerConfiguration.fromJson({
      'pool': 'tank',
      'dataset': 'tank/ix-apps',
      'enable_image_updates': true,
      'nvidia': false,
      'address_pools': [
        {'base': '172.17.0.0/12', 'size': 24},
      ],
      'secure_registry_mirrors': ['https://registry.example.com'],
      'insecure_registry_mirrors': ['http://internal.example.com'],
    });

    expect(configuration.pool, 'tank');
    expect(configuration.addressPoolCount, 1);
    expect(configuration.secureMirrorCount, 1);
    expect(configuration.insecureMirrorCount, 1);
    expect(configuration.toString(), isNot(contains('registry.example.com')));
  });
}
