typedef AppStatsJson = Map<String, dynamic>;

class AppStats {
  const AppStats({
    required this.appName,
    required this.cpuUsage,
    required this.memoryBytes,
    required this.networks,
    required this.blockReadBytes,
    required this.blockWriteBytes,
  });

  factory AppStats.fromJson(AppStatsJson json) {
    final blkio = json['blkio'] is Map
        ? Map<String, dynamic>.from(json['blkio'] as Map)
        : const <String, dynamic>{};
    return AppStats(
      appName: '${json['app_name'] ?? ''}',
      cpuUsage: _number(json['cpu_usage']),
      memoryBytes: _integer(json['memory']),
      networks: _objects(
        json['networks'],
      ).map(AppNetworkStats.fromJson).toList(growable: false),
      blockReadBytes: _integer(blkio['read']),
      blockWriteBytes: _integer(blkio['write']),
    );
  }

  final String appName;
  final double cpuUsage;
  final int memoryBytes;
  final List<AppNetworkStats> networks;
  final int blockReadBytes;
  final int blockWriteBytes;
}

class AppNetworkStats {
  const AppNetworkStats({
    required this.interfaceName,
    required this.receivedBytesPerSecond,
    required this.sentBytesPerSecond,
  });

  factory AppNetworkStats.fromJson(AppStatsJson json) => AppNetworkStats(
    interfaceName: '${json['interface_name'] ?? 'network'}',
    receivedBytesPerSecond: _integer(json['rx_bytes']),
    sentBytesPerSecond: _integer(json['tx_bytes']),
  );

  final String interfaceName;
  final int receivedBytesPerSecond;
  final int sentBytesPerSecond;
}

List<AppStats> appStatsFromNotification(Object? params) {
  if (params is! Map) return const [];
  final fields = params['fields'];
  return _objects(fields).map(AppStats.fromJson).toList(growable: false);
}

List<AppStatsJson> _objects(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false)
    : const [];

int _integer(Object? value) => value is num ? value.round() : 0;
double _number(Object? value) => value is num ? value.toDouble() : 0;
