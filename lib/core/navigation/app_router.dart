import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../features/connection/presentation/connect_server_screen.dart';
import '../../features/connection/presentation/connection_controller.dart';
import '../../features/connection/presentation/server_entry_screen.dart';
import '../../features/connection/presentation/server_management_screen.dart';
import '../../features/settings/presentation/device_data_reset_screen.dart';
import '../../features/system/presentation/system_administration_screen.dart';
import '../../features/reporting/presentation/reporting_history_screen.dart';
import '../widgets/active_jobs_fab.dart';
import '../theme/app_motion.dart';

final rootNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (ref) => GlobalKey<NavigatorState>(),
);

final appRouterProvider = Provider<GoRouter>((ref) {
  // GoRouter does not know about Riverpod state by itself. Bridge connection
  // stage changes into its refresh contract so a dropped session can evict a
  // privileged detail route immediately.
  final refresh = ValueNotifier(0);
  ref.listen(connectionControllerProvider, (previous, next) {
    if (previous?.stage != next.stage) refresh.value++;
  });

  final router = GoRouter(
    navigatorKey: ref.watch(rootNavigatorKeyProvider),
    initialLocation: '/',
    observers: [
      SentryNavigatorObserver(
        enableNewTraceOnNavigation: true,
        routeNameExtractor: _privacySafeRouteSettings,
      ),
    ],
    refreshListenable: refresh,
    redirect: (context, state) {
      final connected = ref.read(connectionControllerProvider).isConnected;
      final path = state.uri.path;
      final publicRoute =
          path == '/' ||
          path == '/servers/new' ||
          path.startsWith('/servers/auth/') ||
          path == '/app-data/reset' ||
          path == '/connect';
      if (!connected && !publicRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        name: 'server-list',
        path: '/',
        builder: (context, state) =>
            const ActiveJobsFabHost(child: ServerEntryScreen()),
      ),
      GoRoute(
        name: 'server-registration',
        path: '/servers/new',
        pageBuilder: (context, state) => _slidePage(
          context,
          state,
          ActiveJobsFabHost(child: const ServerRegistrationScreen()),
        ),
      ),
      GoRoute(
        name: 'server-authentication',
        path: '/servers/auth/:serverId',
        pageBuilder: (context, state) => _slidePage(
          context,
          state,
          ActiveJobsFabHost(
            child: SavedServerAuthenticationScreen(
              serverId: state.pathParameters['serverId'] ?? '',
            ),
          ),
        ),
      ),
      GoRoute(
        name: 'connect',
        path: '/connect',
        redirect: (context, state) => '/servers/new',
      ),
      GoRoute(
        name: 'device-data-reset',
        path: '/app-data/reset',
        pageBuilder: (context, state) =>
            _slidePage(context, state, const DeviceDataResetScreen()),
      ),
      GoRoute(
        name: 'reporting-history',
        path: '/reporting/:metric',
        pageBuilder: (context, state) => _slidePage(
          context,
          state,
          ActiveJobsFabHost(
            child: ReportingHistoryScreen(
              metric: ReportingHistoryMetric.fromPath(
                state.pathParameters['metric'] ?? 'cpu',
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        name: 'server-settings',
        path: '/settings/servers',
        pageBuilder: (context, state) => _slidePage(
          context,
          state,
          const ActiveJobsFabHost(child: ServerManagementScreen()),
        ),
      ),
      GoRoute(
        name: 'legacy-server-settings',
        path: '/system/servers',
        redirect: (context, state) => '/settings/servers',
      ),
      GoRoute(
        name: 'system-administration',
        path: '/system/:section',
        pageBuilder: (context, state) => _slidePage(
          context,
          state,
          ActiveJobsFabHost(
            child: SystemAdministrationScreen(
              section: state.pathParameters['section'] ?? 'activity',
            ),
          ),
        ),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

RouteSettings? _privacySafeRouteSettings(RouteSettings? settings) {
  if (settings == null) return null;
  final routeName = settings.name;
  if (routeName == null || routeName.isEmpty) return const RouteSettings();
  // GoRouter route names above are static and never contain server IDs,
  // resource names, addresses, or other user-provided values.
  return RouteSettings(name: routeName);
}

Page<void> _slidePage(BuildContext context, GoRouterState state, Widget child) {
  final reduced = MediaQuery.of(context).disableAnimations;
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: reduced ? Duration.zero : AppMotion.standard,
    reverseTransitionDuration: reduced ? Duration.zero : AppMotion.standard,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.of(context).disableAnimations) return child;
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: animation,
                curve: AppMotion.standardCurve,
                reverseCurve: AppMotion.standardCurve,
              ),
            ),
        child: child,
      );
    },
  );
}
