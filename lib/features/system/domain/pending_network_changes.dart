import 'package:meta/meta.dart';

/// The state of staged (uncommitted) network changes on the server.
///
/// TrueNAS SCALE 25.10 has no single method describing staged network work.
/// This aggregates `interface.has_pending_changes`,
/// `interface.checkin_waiting`, and
/// `interface.network_config_to_be_removed` so the commit sheet can preview
/// the consequence of a commit before the user confirms it.
@immutable
class PendingNetworkChanges {
  const PendingNetworkChanges({
    required this.hasPendingChanges,
    required this.checkInSecondsRemaining,
    required this.fieldsClearedOnCheckIn,
  });

  /// Whether any interface or route change is staged but not committed.
  final bool hasPendingChanges;

  /// Seconds left to call `interface.checkin` before the server reverts a
  /// commit that is already in flight, or `null` when no commit is waiting.
  final int? checkInSecondsRemaining;

  /// `network.configuration` fields the next check-in will clear, such as
  /// `ipv4gateway` or `nameserver1`. Clearing a gateway or nameserver can
  /// sever the session TrueDock is connected over, so this is surfaced as a
  /// consequence rather than logged.
  final List<String> fieldsClearedOnCheckIn;

  /// True when a commit is already in flight and awaiting check-in.
  bool get isAwaitingCheckIn => checkInSecondsRemaining != null;

  /// True when there is nothing staged and nothing awaiting check-in, so a
  /// commit would be a no-op.
  bool get isEmpty => !hasPendingChanges && !isAwaitingCheckIn;
}
