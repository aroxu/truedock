import '../../../core/api/truenas_json_rpc_client.dart';
import '../../resources/domain/server_resources.dart';
import '../domain/system_resources.dart';
import '../../../core/domain/data_message.dart';

class SystemResourcesRepository {
  const SystemResourcesRepository(this._client);

  final TrueNasJsonRpcClient _client;

  Future<ResourceValue<SystemUpdateStatus>> loadUpdateStatus() =>
      _value('update.status', SystemUpdateStatus.fromJson);

  Future<SystemUpdateProfiles> loadUpdateProfiles() async {
    final results = await Future.wait([
      _client.call('update.profile_choices'),
      _client.call('update.config'),
    ]);
    final choices = results[0];
    final config = results[1];
    if (choices is! Map || config is! Map) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'TrueNAS returned invalid update profile data.',
      );
    }
    final items =
        choices.entries
            .where((entry) => entry.key is String)
            .map(
              (entry) => SystemUpdateProfile.fromEntry(
                entry.key as String,
                entry.value,
              ),
            )
            .where((profile) => profile.available)
            .toList(growable: false)
          ..sort((a, b) {
            const order = {
              SystemUpdateChannel.developer: 0,
              SystemUpdateChannel.earlyAdopter: 1,
              SystemUpdateChannel.general: 2,
            };
            return order[a.channel]!.compareTo(order[b.channel]!);
          });
    return SystemUpdateProfiles(
      currentId: config['profile'] as String?,
      items: items,
    );
  }

  Future<SystemResources> load({Set<String>? supportedMethods}) async {
    final results = await Future.wait<Object>([
      _section('user.query', NasUser.fromJson),
      _section('group.query', NasGroup.fromJson),
      _section('interface.query', NetworkInterface.fromJson),
      _section('staticroute.query', StaticRoute.fromJson),
      _value('update.status', SystemUpdateStatus.fromJson),
      _section(
        'boot.environment.query',
        BootEnvironment.fromJson,
        supportedMethods: supportedMethods,
      ),
      _section(
        'api_key.query',
        NasApiKey.fromJson,
        supportedMethods: supportedMethods,
      ),
      _section(
        'auth.sessions',
        NasSession.fromJson,
        supportedMethods: supportedMethods,
      ),
    ]);
    final interfaces = results[2] as ResourceSection<NetworkInterface>;
    final sortedInterfaces = interfaces.items.toList(growable: false)
      ..sort((left, right) => naturalDeviceNameCompare(left.name, right.name));
    return SystemResources(
      users: results[0] as ResourceSection<NasUser>,
      groups: results[1] as ResourceSection<NasGroup>,
      interfaces: ResourceSection(
        items: sortedInterfaces,
        error: interfaces.error,
      ),
      routes: results[3] as ResourceSection<StaticRoute>,
      updateStatus: results[4] as ResourceValue<SystemUpdateStatus>,
      bootEnvironments: results[5] as ResourceSection<BootEnvironment>,
      apiKeys: results[6] as ResourceSection<NasApiKey>,
      sessions: results[7] as ResourceSection<NasSession>,
    );
  }

  Future<ResourceSection<T>> _section<T>(
    String method,
    T Function(JsonObject json) decode, {
    Set<String>? supportedMethods,
  }) async {
    if (supportedMethods != null && !supportedMethods.contains(method)) {
      return ResourceSection(
        error: DataMessage(
          DataMessageCode.methodUnavailable,
          method: method,
          fallback: '$method is not available on this TrueNAS version.',
        ),
      );
    }
    try {
      final response = await _client.call(method);
      if (response is! List<Object?>) {
        return ResourceSection(
          error: DataMessage(
            DataMessageCode.invalidData,
            method: method,
            fallback: '$method returned invalid data.',
          ),
        );
      }
      return ResourceSection(
        items: response
            .whereType<JsonObject>()
            .map(decode)
            .toList(growable: false),
      );
    } on TrueNasRpcException catch (error) {
      return ResourceSection(error: DataMessage.raw(error.displayMessage));
    } on Object {
      return ResourceSection(
        error: DataMessage(
          DataMessageCode.decodeFailed,
          method: method,
          fallback: 'Could not decode $method.',
        ),
      );
    }
  }

  Future<ResourceValue<T>> _value<T>(
    String method,
    T Function(JsonObject json) decode,
  ) async {
    try {
      final response = await _client.call(method);
      if (response is! JsonObject) {
        return ResourceValue(
          error: DataMessage(
            DataMessageCode.invalidData,
            method: method,
            fallback: '$method returned invalid data.',
          ),
        );
      }
      return ResourceValue(value: decode(response));
    } on TrueNasRpcException catch (error) {
      return ResourceValue(error: DataMessage.raw(error.displayMessage));
    } on Object {
      return ResourceValue(
        error: DataMessage(
          DataMessageCode.decodeFailed,
          method: method,
          fallback: 'Could not decode $method.',
        ),
      );
    }
  }
}
