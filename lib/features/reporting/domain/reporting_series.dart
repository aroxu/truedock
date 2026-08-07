import '../../../core/domain/data_message.dart';

typedef JsonObject = Map<String, dynamic>;

/// A single decoded `reporting.netdata_get_data` graph.
///
/// TrueNAS returns rows as `[timestamp, dim1, dim2, ...]` alongside a `legend`
/// whose first entry is the time column. Rows can contain nulls when Netdata
/// has a gap, so every accessor tolerates missing samples.
class ReportingSeries {
  ReportingSeries({
    required this.name,
    required this.legend,
    required this.points,
    this.identifier,
    this.start,
    this.end,
    this.step,
    this.unit,
    this.aggregations = const {},
  });

  factory ReportingSeries.fromJson(JsonObject json) {
    final legend = json['legend'] is List<Object?>
        ? (json['legend']! as List<Object?>).whereType<String>().toList(
            growable: false,
          )
        : const <String>[];
    // Drop the leading time column so dimension indexes line up with samples.
    final dimensions = legend.isEmpty
        ? const <String>[]
        : legend.sublist(1).toList(growable: false);

    final rows = json['data'];
    final points = <ReportingPoint>[];
    if (rows is List<Object?>) {
      for (final row in rows) {
        if (row is! List<Object?> || row.isEmpty) continue;
        final time = row.first;
        if (time is! num) continue;
        points.add(
          ReportingPoint(
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              time.toInt() * 1000,
              isUtc: true,
            ),
            values: [
              for (var index = 1; index < row.length; index++)
                row[index] is num ? (row[index]! as num).toDouble() : null,
            ],
          ),
        );
      }
    }

    return ReportingSeries(
      name: json['name'] is String ? json['name']! as String : 'series',
      identifier: json['identifier'] is String
          ? json['identifier']! as String
          : null,
      legend: dimensions,
      points: points,
      start: _timestamp(json['start']),
      end: _timestamp(json['end']),
      step: json['step'] is num ? (json['step']! as num).toInt() : null,
      unit: json['unit'] is String ? json['unit']! as String : null,
      aggregations: _aggregations(json['aggregations']),
    );
  }

  final String name;
  final String? identifier;

  /// Dimension labels, excluding the leading time column.
  final List<String> legend;
  final List<ReportingPoint> points;
  final DateTime? start;
  final DateTime? end;
  final int? step;
  final String? unit;
  final Map<String, Map<String, double>> aggregations;

  bool get isEmpty => points.isEmpty || legend.isEmpty;

  /// Memoised projections of [points].
  ///
  /// These used to be plain getters, which meant every widget build recomputed
  /// a full-length list: an hour of one-second samples is thousands of entries
  /// per series, and Overview reads several of them on every frame while a
  /// one-second timer replaces the snapshot underneath. A series is immutable
  /// once decoded, so the projection can only be computed once.
  final Map<String, List<double?>> _dimensionCache = {};

  /// Samples for one dimension, with gaps preserved as null.
  List<double?> valuesFor(String dimension) {
    final cached = _dimensionCache[dimension];
    if (cached != null) return cached;
    final index = legend.indexOf(dimension);
    final values = index < 0
        ? const <double?>[]
        : List<double?>.unmodifiable(<double?>[
            for (final point in points)
              index < point.values.length ? point.values[index] : null,
          ]);
    _dimensionCache[dimension] = values;
    return values;
  }

  /// Sums every dimension per sample, which is how Netdata CPU utilisation
  /// and similar stacked charts are meant to be read.
  late final List<double?> totals = List<double?>.unmodifiable(<double?>[
    for (final point in points)
      point.values.every((value) => value == null)
          ? null
          : point.values.fold<double>(0, (sum, value) => sum + (value ?? 0)),
  ]);

  /// Whole-machine CPU utilisation on a 0–100 percent scale.
  ///
  /// TrueNAS reports one percentage dimension per logical CPU. Adding those
  /// dimensions makes an eight-core host peak at 800%, which is useful for
  /// capacity accounting but misleading in a system utilisation chart. The
  /// mobile dashboard presents the mean of the available cores instead.
  late final List<double?>
  cpuUtilisation = List<double?>.unmodifiable(<double?>[
    for (final point in points)
      switch (point.values.whereType<double>().toList(growable: false)) {
        final values when values.isNotEmpty =>
          (values.fold<double>(0, (sum, value) => sum + value) / values.length)
          // `clamp` returns the bound itself when it saturates, so an int
          // bound would yield an int here and break the double list.
          .clamp(0.0, 100.0),
        _ => null,
      },
  ]);

  late final double? latestTotal = () {
    for (final value in totals.reversed) {
      if (value != null) return value;
    }
    return null;
  }();

  double? aggregate(String kind, String dimension) =>
      aggregations[kind]?[dimension];

  /// Identity of the graph this series describes, independent of its samples.
  ///
  /// `interface`/`disk` graphs repeat the same [name] once per device, so the
  /// identifier has to participate or a tail refresh would splice one NIC's
  /// samples onto another's.
  String get graphKey => identifier == null ? name : '$name\u0000$identifier';

  /// Extends [previous] with this series' newer samples.
  ///
  /// A one-second Overview refresh only needs the seconds that elapsed since
  /// the last one, but the chart still shows an hour. Re-requesting the whole
  /// hour every second is what made each tick allocate thousands of points;
  /// this stitches a short tail onto the retained history instead.
  ///
  /// Returns `this` unchanged whenever the two cannot be safely joined — a
  /// different graph, a changed dimension layout, or a gap between the two
  /// ranges that would silently fabricate continuity across missing time.
  ReportingSeries appendTo(
    ReportingSeries? previous, {
    required Duration keep,
  }) {
    if (previous == null ||
        previous.graphKey != graphKey ||
        !_sameLegend(previous.legend, legend) ||
        previous.points.isEmpty ||
        points.isEmpty) {
      return this;
    }

    final firstNew = points.first.timestamp;
    final lastOld = previous.points.last.timestamp;
    // The tail must overlap or meet the retained history. If it starts after
    // the previous range ended, the time in between was never sampled and
    // joining the two would draw a line across data we do not have.
    if (firstNew.isAfter(lastOld.add(_joinTolerance))) return this;

    final merged = <ReportingPoint>[
      for (final point in previous.points)
        if (point.timestamp.isBefore(firstNew)) point,
      ...points,
    ];

    final cutoff = merged.last.timestamp.subtract(keep);
    final trimmed = merged.first.timestamp.isBefore(cutoff)
        ? [
            for (final point in merged)
              if (!point.timestamp.isBefore(cutoff)) point,
          ]
        : merged;

    return ReportingSeries(
      name: name,
      identifier: identifier,
      legend: legend,
      points: List.unmodifiable(trimmed),
      start: trimmed.first.timestamp,
      end: trimmed.last.timestamp,
      step: step ?? previous.step,
      unit: unit ?? previous.unit,
      // Aggregations describe the requested window, so the short tail's
      // figures do not describe the stitched range. Drop them rather than
      // report a one-minute maximum as if it covered the hour.
      aggregations: const {},
    );
  }

  /// Netdata rounds sample timestamps to its collection interval, so a tail
  /// can legitimately begin a step or two after the retained history ends.
  static const _joinTolerance = Duration(seconds: 90);

  static bool _sameLegend(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  static DateTime? _timestamp(Object? value) => value is num
      ? DateTime.fromMillisecondsSinceEpoch(value.toInt() * 1000, isUtc: true)
      : null;

  static Map<String, Map<String, double>> _aggregations(Object? value) {
    if (value is! JsonObject) return const {};
    final result = <String, Map<String, double>>{};
    for (final entry in value.entries) {
      final inner = entry.value;
      if (inner is! JsonObject) continue;
      result[entry.key] = {
        for (final dimension in inner.entries)
          if (dimension.value is num)
            dimension.key: (dimension.value as num).toDouble(),
      };
    }
    return result;
  }
}

class ReportingPoint {
  const ReportingPoint({required this.timestamp, required this.values});

  final DateTime timestamp;
  final List<double?> values;
}

/// The Overview sparkline set. Kept small on purpose: Overview should stay
/// fast, and detailed graphs belong on dedicated screens.
class ReportingSnapshot {
  const ReportingSnapshot({
    this.cpu,
    this.memory,
    this.load,
    this.network = const [],
    this.disks = const [],
    this.totalMemoryBytes,
    this.error,
  });

  final ReportingSeries? cpu;
  final ReportingSeries? memory;
  final ReportingSeries? load;
  final List<ReportingSeries> network;
  final List<ReportingSeries> disks;
  final int? totalMemoryBytes;

  /// The failure to show, as a code the presentation layer localizes.
  final DataMessage? error;

  /// English text for logs and tests. The UI renders [error] through
  /// `DataMessageLocalizations` instead.
  String? get errorMessage => error?.fallback;

  bool get hasError => error != null;

  bool get isEmpty =>
      (cpu?.isEmpty ?? true) &&
      (memory?.isEmpty ?? true) &&
      (load?.isEmpty ?? true) &&
      network.every((series) => series.isEmpty) &&
      disks.every((series) => series.isEmpty);

  /// Timestamp of the newest sample anywhere in the snapshot.
  ///
  /// Lets a refresh ask only for the time that has actually elapsed since the
  /// data on screen, instead of re-requesting the whole displayed window.
  DateTime? get latestSampleTime {
    DateTime? newest;
    for (final series in [cpu, memory, load, ...network, ...disks]) {
      if (series == null || series.points.isEmpty) continue;
      final candidate = series.points.last.timestamp;
      if (newest == null || candidate.isAfter(newest)) newest = candidate;
    }
    return newest;
  }

  /// Keeps the last confirmed device series when a foreground refresh only
  /// returns the always-present host graphs.
  ///
  /// Netdata graph discovery can briefly return no interface/disk identifiers
  /// while TrueNAS is restoring its reporting pipeline. CPU and memory still
  /// arrive in that response, so replacing the whole snapshot would make only
  /// the lower device charts disappear. Empty device lists therefore mean
  /// "not refreshed yet" when a previous successful list exists. A non-empty
  /// list always wins, so genuinely changed hardware is adopted naturally on
  /// the next complete response.
  ReportingSnapshot retainMissingDevicesFrom(ReportingSnapshot? previous) {
    if (previous == null || hasError) return this;
    return ReportingSnapshot(
      cpu: cpu,
      memory: memory,
      load: load,
      network: network.isEmpty ? previous.network : network,
      disks: disks.isEmpty ? previous.disks : disks,
      totalMemoryBytes: totalMemoryBytes ?? previous.totalMemoryBytes,
      error: error,
    );
  }

  /// Stitches a short tail refresh onto the retained hour of history.
  ///
  /// Overview refreshes once a second but displays an hour. Requesting the
  /// whole hour on every tick decoded thousands of samples per series per
  /// second and threw all of them away; asking only for the seconds since the
  /// last tick and joining them here keeps the same chart for a fraction of
  /// the allocation.
  ///
  /// Each series decides for itself whether the join is safe, so a device that
  /// appears, disappears, or changes its dimensions falls back to whatever the
  /// server just sent rather than to a spliced-together history.
  ReportingSnapshot appendTo(
    ReportingSnapshot? previous, {
    required Duration keep,
  }) {
    if (previous == null || hasError) return this;

    List<ReportingSeries> join(
      List<ReportingSeries> fresh,
      List<ReportingSeries> retained,
    ) {
      if (fresh.isEmpty) return retained;
      final byKey = {for (final series in retained) series.graphKey: series};
      return List.unmodifiable([
        for (final series in fresh)
          series.appendTo(byKey[series.graphKey], keep: keep),
      ]);
    }

    return ReportingSnapshot(
      cpu: cpu?.appendTo(previous.cpu, keep: keep),
      memory: memory?.appendTo(previous.memory, keep: keep),
      load: load?.appendTo(previous.load, keep: keep),
      network: join(network, previous.network),
      disks: join(disks, previous.disks),
      totalMemoryBytes: totalMemoryBytes ?? previous.totalMemoryBytes,
      error: error,
    );
  }
}
