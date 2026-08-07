import '../../../core/api/truenas_json_rpc_client.dart';
import '../../resources/domain/server_resources.dart'
    show naturalDeviceNameCompare;
import '../domain/reporting_series.dart';
import '../../../core/domain/data_message.dart';

/// Reads Netdata-backed graphs through `reporting.netdata_get_data`.
///
/// The method is capability-gated because reporting can be unavailable or
/// permission-restricted, and TrueDock must show that rather than an empty
/// chart that looks like idle hardware.
class ReportingRepository {
  const ReportingRepository(this._client);

  static const method = 'reporting.netdata_get_data';
  static const graphsMethod = 'reporting.netdata_graphs';

  final TrueNasJsonRpcClient _client;

  /// Loads the Overview sparkline set for the last [window].
  Future<ReportingSnapshot> loadOverview({
    Set<String>? supportedMethods,
    Duration window = const Duration(hours: 1),
    int? totalMemoryBytes,
  }) async {
    if (supportedMethods != null && !supportedMethods.contains(method)) {
      return const ReportingSnapshot(
        error: DataMessage(
          DataMessageCode.reportingUnsupported,
          fallback: 'Reporting is not available on this TrueNAS version.',
        ),
      );
    }

    try {
      final requests = <({String name, String? identifier})>[
        (name: 'cpu', identifier: null),
        (name: 'memory', identifier: null),
        (name: 'load', identifier: null),
      ];
      if (supportedMethods?.contains(graphsMethod) == true) {
        requests.addAll(await _deviceRequests());
      }
      final series = await _fetch(requests, window);
      ReportingSeries? first(String name) {
        for (final item in series) {
          if (item.name == name) return item;
        }
        return null;
      }

      final network = series.where((item) => item.name == 'interface').toList()
        ..sort(
          (left, right) => naturalDeviceNameCompare(
            left.identifier ?? '',
            right.identifier ?? '',
          ),
        );
      final disks = series.where((item) => item.name == 'disk').toList()
        ..sort(
          (left, right) => naturalDeviceNameCompare(
            left.identifier ?? '',
            right.identifier ?? '',
          ),
        );

      return ReportingSnapshot(
        cpu: first('cpu'),
        memory: first('memory'),
        load: first('load'),
        network: List.unmodifiable(network),
        disks: List.unmodifiable(disks),
        totalMemoryBytes: totalMemoryBytes,
      );
    } on TrueNasRpcException catch (error) {
      return ReportingSnapshot(error: DataMessage.raw(error.displayMessage));
    } on Object {
      return const ReportingSnapshot(
        error: DataMessage(
          DataMessageCode.reportingUnreadable,
          fallback: 'Could not read reporting data.',
        ),
      );
    }
  }

  Future<List<({String name, String? identifier})>> _deviceRequests() async {
    final result = await _client.call(graphsMethod);
    if (result is! List) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'reporting.netdata_graphs returned invalid data.',
      );
    }
    final requests = <({String name, String? identifier})>[];
    for (final entry in result) {
      if (entry is! Map) continue;
      final name = entry['name'];
      if (name != 'interface' && name != 'disk') continue;
      final identifiers = entry['identifiers'];
      if (identifiers is! List) continue;
      for (final identifier in identifiers.whereType<String>()) {
        requests.add((name: name as String, identifier: identifier));
      }
    }
    return requests;
  }

  Future<List<ReportingSeries>> _fetch(
    List<({String name, String? identifier})> requests,
    Duration window,
  ) async {
    final now = DateTime.now().toUtc();
    final result = await _client.call(
      method,
      params: [
        [
          for (final request in requests)
            {
              'name': request.name,
              if (request.identifier != null) 'identifier': request.identifier,
            },
        ],
        {
          'start': now.subtract(window).millisecondsSinceEpoch ~/ 1000,
          'end': now.millisecondsSinceEpoch ~/ 1000,
        },
      ],
    );
    if (result is! List<Object?>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'reporting.netdata_get_data returned invalid data.',
      );
    }

    final decoded = <ReportingSeries>[];
    for (final entry in result) {
      if (entry is! JsonObject) continue;
      final series = ReportingSeries.fromJson(entry);
      decoded.add(series);
    }
    return decoded;
  }
}
