import 'dart:async';

import 'package:flutter/material.dart';

/// Runs one bounded refresh loop only while its widget is actually visible.
///
/// `SlidingIndexedStack` deliberately keeps every destination mounted. A plain
/// periodic timer would therefore keep hidden tabs alive and recreate the API
/// and allocation storm this app previously removed. TickerMode, route state,
/// and app lifecycle jointly define whether the user can currently see the
/// page. Slow reads never overlap; the next tick is simply skipped.
mixin VisibleAutoRefreshState<T extends StatefulWidget> on State<T> {
  Timer? _visibleRefreshTimer;
  AppLifecycleListener? _visibleRefreshLifecycle;
  FutureOr<void> Function()? _visibleRefreshCallback;
  var _appActive = true;
  var _tickerVisible = true;
  var _refreshInFlight = false;

  void startVisibleAutoRefresh(
    FutureOr<void> Function() callback, {
    Duration interval = const Duration(seconds: 1),
  }) {
    assert(_visibleRefreshTimer == null);
    _visibleRefreshCallback = callback;
    _visibleRefreshLifecycle = AppLifecycleListener(
      onResume: () => _appActive = true,
      onPause: () => _appActive = false,
      onHide: () => _appActive = false,
      onInactive: () => _appActive = false,
      onDetach: () => _appActive = false,
    );
    _visibleRefreshTimer = Timer.periodic(interval, (_) => _runRefresh());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tickerVisible = TickerMode.valuesOf(context).enabled;
  }

  Future<void> _runRefresh() async {
    if (!mounted || !_appActive || !_tickerVisible || _refreshInFlight) return;
    if (ModalRoute.of(context)?.isCurrent == false) return;
    final callback = _visibleRefreshCallback;
    if (callback == null) return;
    _refreshInFlight = true;
    try {
      await callback();
    } finally {
      _refreshInFlight = false;
    }
  }

  @override
  void dispose() {
    _visibleRefreshTimer?.cancel();
    _visibleRefreshLifecycle?.dispose();
    super.dispose();
  }
}
