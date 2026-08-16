import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../apps/presentation/apps_screen.dart';
import '../../apps/presentation/apps_catalog_provider.dart';
import '../../actions/presentation/server_action_controller.dart';
import '../../connection/presentation/connection_controller.dart';
import '../../data_protection/presentation/data_protection_screen.dart';
import '../../overview/presentation/overview_screen.dart';
import '../../reporting/presentation/reporting_provider.dart';
import '../../resources/domain/server_resources.dart';
import '../../resources/presentation/server_resources_provider.dart';
import '../../storage/presentation/storage_screen.dart';
import '../../system/presentation/system_screen.dart';
import '../../system/presentation/system_resources_provider.dart';
import '../../settings/presentation/app_settings_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/sliding_indexed_stack.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _navigationRailBreakpoint = 600.0;

  int _index = 0;
  late final AppLifecycleListener _lifecycleListener;
  Timer? _refreshTimer;
  var _appActive = true;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        _appActive = true;
        _handleResume();
      },
      onPause: () => _appActive = false,
      onHide: () => _appActive = false,
      onInactive: () => _appActive = false,
      onDetach: () => _appActive = false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(activeServerResourceScopeProvider.notifier).state =
          ServerResourceScope.overview;
    });
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshVisibleDestination(),
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _refreshVisibleDestination() {
    if (!_appActive || !mounted) return;
    if (ModalRoute.of(context)?.isCurrent == false) return;
    if (!ref.read(connectionControllerProvider).isConnected) return;

    if (_index == 0 && !ref.read(overviewReportingProvider).isLoading) {
      ref.invalidate(overviewReportingProvider);
    }
    final mutationOrReadInFlight = ref
        .read(serverActionControllerProvider)
        .busyKeys
        .isNotEmpty;
    if (mutationOrReadInFlight) return;
    if (_index >= 0 &&
        _index <= 4 &&
        !ref.read(serverResourcesProvider).isLoading) {
      ref.invalidate(serverResourcesProvider);
    }
    if (_index == 4 && !ref.read(systemResourcesProvider).isLoading) {
      ref.invalidate(systemResourcesProvider);
    }
  }

  void _selectDestination(int value) {
    setState(() => _index = value);
    ref
        .read(activeServerResourceScopeProvider.notifier)
        .state = switch (value) {
      0 => ServerResourceScope.overview,
      1 => ServerResourceScope.storage,
      2 => ServerResourceScope.protection,
      3 => ServerResourceScope.apps,
      4 => ServerResourceScope.system,
      _ => ServerResourceScope.none,
    };
    _refreshVisibleDestination();
  }

  /// Data can be minutes or hours old after iOS/Android suspends the app.
  /// Keep the last successful snapshot visible while probing/reconnecting;
  /// only invalidate feature providers after a new authenticated response.
  /// The app-level connection host gives this silent recovery seven seconds
  /// before exposing the ordinary connection-lost banner.
  Future<void> _handleResume() async {
    final controller = ref.read(connectionControllerProvider.notifier);
    final beforeProbe = ref.read(connectionControllerProvider);
    if (beforeProbe.isConnected) {
      await controller.refreshSystemInfo();
    }
    if (!mounted) return;

    final afterProbe = ref.read(connectionControllerProvider);
    if (afterProbe.isConnectionLost || afterProbe.isReconnecting) {
      // Timers are suspended along with the app on iOS. Returning to the
      // foreground must therefore bypass any remaining retry delay.
      await controller.reconnectAutomatically(resetBackoff: true);
    }
    if (!mounted || !ref.read(connectionControllerProvider).isConnected) {
      return;
    }

    ref.invalidate(serverResourcesProvider);
    ref.invalidate(overviewReportingProvider);
    ref.invalidate(appsCatalogProvider);
    ref.invalidate(systemResourcesProvider);
  }

  /// Built per-frame rather than held in a `const` list so the labels follow
  /// the active locale.
  static List<NavigationDestination> destinationsFor(AppLocalizations l10n) => [
    NavigationDestination(
      icon: const Icon(Icons.space_dashboard_outlined),
      selectedIcon: const Icon(Icons.space_dashboard_rounded),
      label: l10n.navOverview,
    ),
    NavigationDestination(
      icon: const Icon(Icons.storage_outlined),
      selectedIcon: const Icon(Icons.storage_rounded),
      label: l10n.navStorage,
    ),
    NavigationDestination(
      icon: const Icon(Icons.shield_outlined),
      selectedIcon: const Icon(Icons.shield_rounded),
      label: l10n.navProtection,
    ),
    NavigationDestination(
      icon: const Icon(Icons.widgets_outlined),
      selectedIcon: const Icon(Icons.widgets_rounded),
      label: l10n.navApps,
    ),
    NavigationDestination(
      icon: const Icon(Icons.tune_outlined),
      selectedIcon: const Icon(Icons.tune_rounded),
      label: l10n.navSystem,
    ),
    NavigationDestination(
      icon: const Icon(Icons.settings_outlined),
      selectedIcon: const Icon(Icons.settings_rounded),
      label: l10n.navAppSettings,
    ),
  ];

  static const screens = [
    OverviewScreen(),
    StorageScreen(),
    DataProtectionScreen(),
    AppsScreen(),
    SystemScreen(),
    AppSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final destinations = destinationsFor(AppLocalizations.of(context));
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    return PopScope<Object?>(
      // On Android the root route must remain poppable from Overview so the
      // framework delegates the second back press to the Activity and exits.
      // A non-overview tab consumes the first press below instead.
      canPop: !isAndroid || _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !isAndroid || _index == 0) return;
        _selectDestination(0);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Material 3 classifies windows below 600dp as compact. Tablets at
          // 600dp and above get a rail in both orientations, while phones
          // retain the familiar bottom navigation bar.
          final useRail = constraints.maxWidth >= _navigationRailBreakpoint;
          // The connection-lost banner is mounted app-wide by
          // `ConnectionLostHost`, above the router, so it also covers the
          // routes pushed on top of this shell.
          final content = _ReadableWidth(
            child: SlidingIndexedStack(index: _index, children: screens),
          );
          if (!useRail) {
            return Scaffold(
              body: content,
              bottomNavigationBar: NavigationBar(
                selectedIndex: _index,
                destinations: destinations,
                onDestinationSelected: _selectDestination,
              ),
            );
          }

          return Scaffold(
            body: Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    selectedIndex: _index,
                    destinations: [
                      for (final destination in destinations)
                        NavigationRailDestination(
                          icon: destination.icon,
                          selectedIcon: destination.selectedIcon,
                          label: Text(destination.label),
                        ),
                    ],
                    onDestinationSelected: _selectDestination,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Caps how wide the destination content may grow.
///
/// Tablets give the app far more horizontal room than a phone, but running
/// dense administrative lists across a full 1280dp window makes rows hard to
/// scan and reads as a stretched phone layout. Centring the content inside a
/// comfortable measure keeps the extra space as margin instead.
class _ReadableWidth extends StatelessWidget {
  const _ReadableWidth({required this.child});

  /// Chosen so a 10\" tablet in landscape keeps dense administrative content
  /// easy to scan, while smaller windows remain unaffected.
  static const maxContentWidth = 840.0;

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxContentWidth),
      child: child,
    ),
  );
}
