import 'package:flutter/material.dart';

/// A pull-to-refresh indicator that stays below status-bar cutouts.
///
/// [RefreshIndicator] measures its overlay from the viewport itself, while a
/// sliver app bar only lays out its content below the safe inset. On iPhones
/// with a Dynamic Island that leaves the spinner behind the obstruction. This
/// wrapper applies the current safe-area inset to both the reveal edge and the
/// resting position.
class SafeRefreshIndicator extends StatelessWidget {
  const SafeRefreshIndicator({
    required this.onRefresh,
    required this.child,
    this.notificationPredicate = defaultScrollNotificationPredicate,
    super.key,
  });

  final RefreshCallback onRefresh;
  final Widget child;
  final ScrollNotificationPredicate notificationPredicate;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    return RefreshIndicator(
      edgeOffset: safeTop,
      displacement: safeTop + 40,
      notificationPredicate: notificationPredicate,
      onRefresh: onRefresh,
      child: child,
    );
  }
}
