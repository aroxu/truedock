import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/features/system/data/system_resources_repository.dart';
import 'package:true_dock/features/system/domain/system_resources.dart';

void main() {
  test('orders firmware channels as nightly, beta, and stable', () async {
    final repository = SystemResourcesRepository(
      _FakeClient({
        'update.profile_choices': {
          'GENERAL': {'name': 'General', 'available': true},
          'EARLY_ADOPTER': {'name': 'Early Adopter', 'available': true},
          'DEVELOPER': {'name': 'Developer', 'available': true},
        },
        'update.config': {'profile': 'GENERAL'},
      }),
    );

    final profiles = await repository.loadUpdateProfiles();

    expect(profiles.items.map((profile) => profile.channel), [
      SystemUpdateChannel.developer,
      SystemUpdateChannel.earlyAdopter,
      SystemUpdateChannel.general,
    ]);
  });

  test('loads account, network, route, and update sections', () async {
    final repository = SystemResourcesRepository(
      _FakeClient({
        'user.query': [
          {
            'id': 1,
            'username': 'admin',
            'uid': 3000,
            'local': true,
            'builtin': false,
            'roles': ['FULL_ADMIN'],
          },
        ],
        'group.query': [
          {
            'id': 2,
            'name': 'admins',
            'gid': 3000,
            'local': true,
            'builtin': false,
            'roles': ['FULL_ADMIN'],
            'users': [1],
          },
        ],
        'interface.query': [
          {
            'id': 'eno1',
            'name': 'eno1',
            'type': 'PHYSICAL',
            'state': {'link_state': 'UP', 'aliases': const []},
          },
        ],
        'staticroute.query': const [],
        'update.status': {
          'code': 'NORMAL',
          'status': {
            'current_version': {'train': '25.10', 'profile': 'GENERAL'},
            'new_version': null,
          },
          'error': null,
          'update_download_progress': null,
        },
      }),
    );

    final resources = await repository.load();

    expect(resources.users.items.single.username, 'admin');
    expect(resources.groups.items.single.userIds, [1]);
    expect(resources.interfaces.items.single.isUp, isTrue);
    expect(resources.updateStatus.value?.train, '25.10');
  });

  test('sorts network interfaces in natural name order', () async {
    Map<String, Object?> interfaceJson(String name) => {
      'id': name,
      'name': name,
      'type': 'PHYSICAL',
      'state': {'link_state': 'UP', 'aliases': const []},
    };
    final repository = SystemResourcesRepository(
      _FakeClient({
        'interface.query': [
          interfaceJson('enp6s18'),
          interfaceJson('enp6s20'),
          interfaceJson('enp6s19'),
        ],
      }),
    );

    final resources = await repository.load();

    expect(resources.interfaces.items.map((item) => item.name), [
      'enp6s18',
      'enp6s19',
      'enp6s20',
    ]);
  });

  test('keeps other sections when account access is denied', () async {
    final repository = SystemResourcesRepository(
      _FakeClient(
        {
          'group.query': const [],
          'interface.query': const [],
          'staticroute.query': const [],
          'update.status': {
            'code': 'NORMAL',
            'status': {
              'current_version': {'train': '25.10', 'profile': 'GENERAL'},
              'new_version': null,
            },
            'error': null,
            'update_download_progress': null,
          },
        },
        failures: {
          'user.query': const TrueNasRpcException(
            code: -32001,
            message: 'Not authorized',
          ),
        },
      ),
    );

    final resources = await repository.load();

    expect(resources.users.errorMessage, 'Not authorized');
    expect(resources.interfaces.hasError, isFalse);
    expect(resources.updateStatus.hasError, isFalse);
  });

  test('loads boot environments alongside the update status', () async {
    final repository = SystemResourcesRepository(
      _FakeClient({
        'boot.environment.query': [
          {'id': '25.10.2', 'active': true, 'activated': true, 'keep': false},
          {'id': '25.10.1', 'active': false, 'activated': false, 'keep': true},
        ],
      }),
    );

    final resources = await repository.load();

    expect(resources.bootEnvironments.items, hasLength(2));
    expect(resources.bootEnvironments.items.first.active, isTrue);
    expect(resources.bootEnvironments.items.last.keep, isTrue);
  });

  test('gates boot environments on the discovered API surface', () async {
    final client = _RecordingClient();
    final repository = SystemResourcesRepository(client);

    final resources = await repository.load(
      supportedMethods: const {
        'user.query',
        'group.query',
        'interface.query',
        'staticroute.query',
        'update.status',
      },
    );

    expect(client.calledMethods, isNot(contains('boot.environment.query')));
    expect(resources.bootEnvironments.hasError, isTrue);
    expect(
      resources.bootEnvironments.errorMessage,
      'boot.environment.query is not available on this TrueNAS version.',
    );
  });

  test('a denied boot environment read keeps the update status', () async {
    final repository = SystemResourcesRepository(
      _FakeClient(
        {
          'update.status': {
            'code': 'NORMAL',
            'status': {
              'current_version': {'train': '25.10', 'profile': 'GENERAL'},
              'new_version': null,
            },
            'error': null,
            'update_download_progress': null,
          },
        },
        failures: {
          'boot.environment.query': const TrueNasRpcException(
            code: -32001,
            message: 'Not authorized',
          ),
        },
      ),
    );

    final resources = await repository.load();

    expect(resources.bootEnvironments.errorMessage, 'Not authorized');
    expect(resources.updateStatus.value?.train, '25.10');
  });

  test('loads API keys without retaining key material', () async {
    final repository = SystemResourcesRepository(
      _FakeClient({
        'api_key.query': [
          {
            'id': 4,
            'name': 'backup-runner',
            'username': 'admin',
            'revoked': false,
            'key': 'plaintext-secret-should-not-survive',
          },
        ],
      }),
    );

    final resources = await repository.load();

    final apiKey = resources.apiKeys.items.single;
    expect(apiKey.name, 'backup-runner');
    expect(apiKey.username, 'admin');
    // The model has no field for a secret, so the value cannot be retained.
    expect(apiKey.toString(), isNot(contains('plaintext-secret')));
  });

  test('gates API keys on the discovered API surface', () async {
    final client = _RecordingClient();
    final repository = SystemResourcesRepository(client);

    final resources = await repository.load(
      supportedMethods: const {'user.query'},
    );

    expect(client.calledMethods, isNot(contains('api_key.query')));
    expect(resources.apiKeys.hasError, isTrue);
    expect(
      resources.apiKeys.errorMessage,
      'api_key.query is not available on this TrueNAS version.',
    );
  });

  test('a denied API key read keeps the account sections', () async {
    final repository = SystemResourcesRepository(
      _FakeClient(
        {
          'user.query': [
            {
              'id': 1,
              'username': 'admin',
              'uid': 3000,
              'local': true,
              'builtin': false,
              'roles': ['FULL_ADMIN'],
            },
          ],
        },
        failures: {
          'api_key.query': const TrueNasRpcException(
            code: -32001,
            message: 'Not authorized',
          ),
        },
      ),
    );

    final resources = await repository.load();

    expect(resources.apiKeys.errorMessage, 'Not authorized');
    expect(resources.users.items.single.username, 'admin');
  });
}

class _RecordingClient extends TrueNasJsonRpcClient {
  final List<String> calledMethods = [];

  @override
  Future<Object?> call(
    String method, {
    List<Object?> params = const [],
    Duration timeout = const Duration(seconds: 20),
  }) async {
    calledMethods.add(method);
    return const [];
  }
}

class _FakeClient extends TrueNasJsonRpcClient {
  _FakeClient(this.responses, {this.failures = const {}});

  final Map<String, Object?> responses;
  final Map<String, Object> failures;

  @override
  Future<Object?> call(
    String method, {
    List<Object?> params = const [],
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final failure = failures[method];
    if (failure != null) throw failure;
    return responses[method] ?? const [];
  }
}
