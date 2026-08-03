import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../apps/presentation/apps_screen.dart';
import '../../apps/presentation/apps_catalog_provider.dart';
import '../../connection/presentation/connection_controller.dart';
import '../../data_protection/presentation/data_protection_screen.dart';
import '../../overview/presentation/overview_screen.dart';
import '../../reporting/presentation/reporting_provider.dart';
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
  int _index = 0;
  late final AppLifecycleListener _lifecycleListener;
  Timer? _reportingTimer;
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
    _reportingTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshLiveReporting(),
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _reportingTimer?.cancel();
    super.dispose();
  }

  void _refreshLiveReporting() {
    if (!_appActive || _index != 0) return;
    if (!ref.read(connectionControllerProvider).isConnected) return;
    if (ref.read(overviewReportingProvider).isLoading) return;
    ref.invalidate(overviewReportingProvider);
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
        setState(() => _index = 0);
        _refreshLiveReporting();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useRail = constraints.maxWidth >= 840;
          // The connection-lost banner is mounted app-wide by
          // `ConnectionLostHost`, above the router, so it also covers the
          // routes pushed on top of this shell.
          final content = SlidingIndexedStack(index: _index, children: screens);
          if (!useRail) {
            return Scaffold(
              body: content,
              bottomNavigationBar: NavigationBar(
                selectedIndex: _index,
                destinations: destinations,
                onDestinationSelected: (value) {
                  setState(() => _index = value);
                  if (value == 0) _refreshLiveReporting();
                },
              ),
            );
          }

          return Scaffold(
            body: Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    selectedIndex: _index,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Icon(
                        Icons.dock_rounded,
                        size: 34,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    destinations: [
                      for (final destination in destinations)
                        NavigationRailDestination(
                          icon: destination.icon,
                          selectedIcon: destination.selectedIcon,
                          label: Text(destination.label),
                        ),
                    ],
                    onDestinationSelected: (value) {
                      setState(() => _index = value);
                      if (value == 0) _refreshLiveReporting();
                    },
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
