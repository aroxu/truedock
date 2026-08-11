import 'package:flutter/material.dart';
import '../../../core/widgets/truedock_dropdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/safe_refresh_indicator.dart';

import '../../../core/widgets/destructive_confirmation.dart';
import '../../../core/widgets/resource_landing_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../actions/data/server_actions_repository.dart';
import '../../actions/presentation/server_action_controller.dart';
import '../../connection/presentation/connection_controller.dart';
import '../../resources/domain/server_resources.dart';
import 'service_row.dart';
import '../../resources/presentation/server_resources_provider.dart';
import '../domain/app_installation.dart';
import '../domain/app_upgrade.dart';
import '../domain/apps_catalog.dart';
import 'app_details_sheet.dart';
import 'app_installation_sheet.dart';
import 'custom_app_editor_sheet.dart';
import 'apps_localizations.dart';
import 'apps_catalog_provider.dart';
import 'instance_lifecycle_controls.dart';
import 'instances_section.dart';
import '../../system/domain/service_configuration.dart';
import '../../system/presentation/service_config_sheet.dart';
import '../../connection/domain/server_capabilities.dart';
import '../../system/domain/vm_configuration.dart';
import '../../system/domain/vm_device.dart';
import '../../system/presentation/vm_config_sheet.dart';
import '../../system/presentation/vm_device_sheet.dart';
import '../../system/presentation/vm_device_localizations.dart';
import '../../system/domain/container_configuration.dart';
import '../../system/presentation/container_config_sheet.dart';
import '../../../core/domain/data_message.dart';
import '../../../core/l10n/data_message_localizations.dart';

class AppsScreen extends ConsumerWidget {
  const AppsScreen({super.key});

  ResourceLandingScreen _landing(AppLocalizations l10n) =>
      ResourceLandingScreen(
        title: l10n.appsTitle,
        description: l10n.appsLandingDescription,
        icon: Icons.widgets_rounded,
        features: [
          (
            icon: Icons.apps_rounded,
            title: l10n.appsInstalledApps,
            subtitle: l10n.appsFeatureInstalledSubtitle,
          ),
          (
            icon: Icons.inventory_2_outlined,
            title: l10n.appsDiscover,
            subtitle: l10n.appsFeatureDiscoverSubtitle,
          ),
          (
            icon: Icons.developer_board_outlined,
            title: l10n.appsContainers,
            subtitle: l10n.appsFeatureContainersSubtitle,
          ),
          (
            icon: Icons.computer_outlined,
            title: l10n.appsVirtualMachines,
            subtitle: l10n.appsFeatureVirtualMachinesSubtitle,
          ),
          (
            icon: Icons.miscellaneous_services_outlined,
            title: l10n.appsServices,
            subtitle: l10n.appsFeatureServicesSubtitle,
          ),
        ],
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final connection = ref.watch(connectionControllerProvider);
    if (!connection.hasRetainedSession) return _landing(l10n);
    final resources = ref.watch(serverResourcesProvider);
    final catalog = ref.watch(appsCatalogProvider);
    final actions = ref.watch(serverActionControllerProvider);
    return SafeRefreshIndicator(
      onRefresh: () async {
        refreshServerResources(ref);
        refreshAppsCatalog(ref);
        await Future.wait([
          ref.read(serverResourcesProvider.future),
          ref.read(appsCatalogProvider.future),
        ]);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(title: Text(l10n.appsTitle)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            sliver: resources.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (_, _) =>
                  SliverToBoxAdapter(child: Text(l10n.appsLoadFailed)),
              data: (data) => SliverList.list(
                children: [
                  _AppsSummary(apps: data.apps.items),
                  const SizedBox(height: 24),
                  Text(
                    l10n.appsInstalledApps,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (data.apps.hasError)
                    _MessageCard(
                      message: l10n.dataMessage(data.apps.error!),
                      error: true,
                    )
                  else if (data.apps.items.isEmpty)
                    _MessageCard(message: l10n.appsNoAppsInstalled)
                  else
                    Card(
                      child: Column(
                        children: [
                          for (final (index, app)
                              in data.apps.items.indexed) ...[
                            _AppTile(
                              app: app,
                              lifecycleBusy: actions.isBusy('app:${app.id}'),
                              upgradeBusy: actions.isBusy(
                                'app-upgrade:${app.id}',
                              ),
                              canUpgrade:
                                  app.catalogUpgradeAvailable &&
                                  connection.capabilities?.supports(
                                        'app.upgrade_summary',
                                      ) ==
                                      true &&
                                  connection.capabilities?.supports(
                                        'app.upgrade',
                                      ) ==
                                      true,
                              canRedeploy:
                                  connection.capabilities?.supports(
                                    'app.redeploy',
                                  ) ==
                                  true,
                              canReconfigure:
                                  connection.capabilities?.supports(
                                        'app.update',
                                      ) ==
                                      true &&
                                  connection.capabilities?.supports(
                                        'app.config',
                                      ) ==
                                      true,
                              canRollback:
                                  connection.capabilities?.supports(
                                    'app.rollback',
                                  ) ==
                                  true,
                              canDelete:
                                  connection.capabilities?.supports(
                                    'app.delete',
                                  ) ==
                                  true,
                              onToggle: () => _toggleApp(context, ref, app),
                              onOpen: () => _openAppDetails(
                                context,
                                ref,
                                app,
                                canReconfigure:
                                    connection.capabilities?.supports(
                                          'app.update',
                                        ) ==
                                        true &&
                                    connection.capabilities?.supports(
                                          'app.config',
                                        ) ==
                                        true,
                              ),
                              onUpgrade: () => _upgradeApp(context, ref, app),
                              onRedeploy: () => _redeployApp(context, ref, app),
                              onReconfigure: () =>
                                  _reconfigureApp(context, ref, app),
                              onRollback: () => _rollbackApp(context, ref, app),
                              onDelete: () => _deleteApp(context, ref, app),
                            ),
                            if (index < data.apps.items.length - 1)
                              const Divider(indent: 68, height: 1),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 28),
                  _CatalogPreview(
                    catalog: catalog,
                    onAppTap: (app) => _openCatalogDetails(
                      context,
                      ref,
                      app,
                      canInstall:
                          connection.capabilities?.supports(
                                'catalog.get_app_details',
                              ) ==
                              true &&
                          connection.capabilities?.supports('app.create') ==
                              true,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.appsVirtualMachines,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (data.virtualMachines.hasError)
                    _MessageCard(
                      message: l10n.dataMessage(data.virtualMachines.error!),
                      error: true,
                    )
                  else if (data.virtualMachines.items.isEmpty)
                    _MessageCard(message: l10n.appsNoVirtualMachines)
                  else
                    Card(
                      child: Column(
                        children: [
                          for (final (index, vm)
                              in data.virtualMachines.items.indexed) ...[
                            _VmTile(vm: vm),
                            if (index < data.virtualMachines.items.length - 1)
                              const Divider(indent: 68, height: 1),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.appsContainers,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (connection.capabilities?.supports('container.query') !=
                      true)
                    _MessageCard(message: l10n.appsContainersUnsupported)
                  else if (data.containers.hasError)
                    _MessageCard(
                      message: l10n.dataMessage(data.containers.error!),
                      error: true,
                    )
                  else if (data.containers.items.isEmpty)
                    _MessageCard(message: l10n.appsNoContainers)
                  else
                    Card(
                      child: Column(
                        children: [
                          for (final (index, container)
                              in data.containers.items.indexed) ...[
                            _ContainerTile(container: container),
                            if (index < data.containers.items.length - 1)
                              const Divider(indent: 68, height: 1),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.appsInstances,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (connection.capabilities?.supportsVirtInstances != true)
                    _MessageCard(message: l10n.appsInstancesUnsupported)
                  else if (data.virtInstances.hasError)
                    _MessageCard(
                      message: l10n.dataMessage(data.virtInstances.error!),
                      error: true,
                    )
                  else
                    InstancesSection(instances: data.virtInstances.items),
                  const SizedBox(height: 28),
                  Text(
                    l10n.appsServices,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (data.services.hasError)
                    _MessageCard(
                      message: l10n.dataMessage(data.services.error!),
                      error: true,
                    )
                  else
                    Card(
                      child: Column(
                        children: [
                          for (final (index, service)
                              in data.services.items.take(12).indexed) ...[
                            ServiceRow(
                              service: service,
                              busy: actions.isBusy('service:${service.name}'),
                              onToggle: (running) => _toggleService(
                                context,
                                ref,
                                service,
                                running,
                              ),
                              canEditStartOnBoot:
                                  connection.capabilities?.supports(
                                    'service.update',
                                  ) ==
                                  true,
                              bootBusy: actions.isBusy(
                                'service-boot:${service.id}',
                              ),
                              onToggleStartOnBoot: (enabled) =>
                                  _setServiceStartOnBoot(
                                    context,
                                    ref,
                                    service,
                                    enabled,
                                  ),
                              // Only five services expose a config surface; the
                              // rest get no editor rather than an empty sheet.
                              onConfigure: switch (_configurableServiceFor(
                                service,
                                connection.capabilities,
                              )) {
                                final ConfigurableService configurable =>
                                  () => _editServiceConfig(
                                    context,
                                    ref,
                                    configurable,
                                    service,
                                  ),
                                null => null,
                              },
                            ),
                            if (index < data.services.items.take(12).length - 1)
                              const Divider(indent: 68, height: 1),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleApp(
    BuildContext context,
    WidgetRef ref,
    InstalledApp app,
  ) async {
    final l10n = AppLocalizations.of(context);
    final shouldRun = app.state != 'RUNNING';
    if (!shouldRun) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.stop_circle_outlined),
          title: Text(l10n.appsStopAppTitle(app.name)),
          content: Text(l10n.appsStopAppBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.appsStopApp),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .setAppRunning(app.id, running: shouldRun);
    if (!context.mounted) return;
    _showResult(
      context,
      receipt == null
          ? ref.read(serverActionControllerProvider).errorMessage
          : (shouldRun
                    ? l10n.appsStartRequested(app.name)
                    : l10n.appsStopRequested(app.name)) +
                _jobSuffix(l10n, receipt.jobId),
      error: receipt == null,
    );
  }

  Future<void> _openAppDetails(
    BuildContext context,
    WidgetRef ref,
    InstalledApp app, {
    required bool canReconfigure,
  }) async {
    final edit = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => AppDetailsSheet(app: app, canEdit: canReconfigure),
    );
    if (edit == true && context.mounted) {
      await _reconfigureApp(context, ref, app);
    }
  }

  Future<void> _toggleService(
    BuildContext context,
    WidgetRef ref,
    SystemService service,
    bool shouldRun,
  ) async {
    final l10n = AppLocalizations.of(context);
    final name = service.name.toUpperCase();
    if (!shouldRun) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.miscellaneous_services_outlined),
          title: Text(l10n.appsStopServiceTitle(name)),
          content: Text(l10n.appsStopServiceBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.appsStopService),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .setServiceRunning(service.name, running: shouldRun);
    if (!context.mounted) return;
    _showResult(
      context,
      receipt == null
          ? ref.read(serverActionControllerProvider).errorMessage
          : (shouldRun
                    ? l10n.appsStartRequested(name)
                    : l10n.appsStopRequested(name)) +
                _jobSuffix(l10n, receipt.jobId),
      error: receipt == null,
    );
  }

  /// Persists a service's start-on-boot setting through `service.update`.
  ///
  /// This is a configuration change rather than a run-state change: it takes
  /// effect on the next boot and does not start or stop the service now, so the
  /// confirmation says so explicitly. Turning autostart off is the disruptive
  /// direction, because a service the user relies on would not come back after
  /// a reboot.
  Future<void> _setServiceStartOnBoot(
    BuildContext context,
    WidgetRef ref,
    SystemService service,
    bool enabled,
  ) async {
    final l10n = AppLocalizations.of(context);
    final serverName =
        ref.read(connectionControllerProvider).profile?.name ??
        l10n.systemServerFallback;
    final name = service.name.toUpperCase();
    final running = service.state == 'RUNNING';
    final confirmed = await confirmDestructiveAction(
      context,
      title: enabled
          ? l10n.appsStartOnBootTitle(name)
          : l10n.appsStopStartOnBootTitle(name),
      server: serverName,
      target: name,
      actionLabel: enabled ? l10n.appsStartOnBoot : l10n.appsDoNotStartOnBoot,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.restart_alt_rounded,
          text: enabled
              ? l10n.appsStartOnBootConsequence(name, serverName)
              : l10n.appsStopOnBootConsequence(name, serverName),
        ),
        ImpactDetail(
          icon: running
              ? Icons.play_circle_outline_rounded
              : Icons.pause_circle_outline_rounded,
          text: running
              ? l10n.appsBootChangeRunningNote
              : l10n.appsBootChangeStoppedNote,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .setServiceStartOnBoot(service.id, enabled: enabled);
    if (!context.mounted) return;
    _showResult(
      context,
      receipt == null
          ? ref.read(serverActionControllerProvider).errorMessage
          : enabled
          ? l10n.appsStartOnBootSaved(name)
          : l10n.appsStopOnBootSaved(name),
      error: receipt == null,
    );
  }

  Future<void> _upgradeApp(
    BuildContext context,
    WidgetRef ref,
    InstalledApp app,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(serverActionControllerProvider.notifier);
    final summary = await controller.loadAppUpgradeSummary(app.id);
    if (!context.mounted) return;
    if (summary == null) {
      _showResult(
        context,
        ref.read(serverActionControllerProvider).errorMessage,
        error: true,
      );
      return;
    }
    final choice = await showModalBottomSheet<AppUpgradeChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _UpgradeAppSheet(app: app, summary: summary),
    );
    if (choice == null || !context.mounted) return;
    final receipt = await controller.upgradeApp(
      app.id,
      version: choice.version,
      snapshotHostPaths: choice.snapshotHostPaths,
    );
    if (!context.mounted) return;
    _showResult(
      context,
      receipt == null
          ? ref.read(serverActionControllerProvider).errorMessage
          : l10n.appsUpgradeRequested(app.name) +
                _jobSuffix(l10n, receipt.jobId),
      error: receipt == null,
    );
  }

  Future<void> _redeployApp(
    BuildContext context,
    WidgetRef ref,
    InstalledApp app,
  ) async {
    final l10n = AppLocalizations.of(context);
    final serverName =
        ref.read(connectionControllerProvider).profile?.name ??
        l10n.systemServerFallback;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.appsRedeployTitle(app.name),
      server: serverName,
      target: app.name,
      actionLabel: l10n.appsRedeployAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.refresh_rounded,
          text: l10n.appsRedeployConsequenceRebuild,
        ),
        ImpactDetail(
          icon: Icons.history_toggle_off_rounded,
          text: l10n.appsRedeployConsequenceData,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .redeployApp(app.id);
    if (!context.mounted) return;
    _showResult(
      context,
      receipt == null
          ? ref.read(serverActionControllerProvider).errorMessage
          : l10n.appsRedeployRequested(app.name) +
                _jobSuffix(l10n, receipt.jobId),
      error: receipt == null,
    );
  }

  Future<void> _reconfigureApp(
    BuildContext context,
    WidgetRef ref,
    InstalledApp app,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(serverActionControllerProvider.notifier);
    final config = await controller.loadAppConfig(app);
    if (!context.mounted) return;
    if (config == null) {
      _showResult(
        context,
        ref.read(serverActionControllerProvider).errorMessage ??
            l10n.appsConfigLoadFailed(app.name),
        error: true,
      );
      return;
    }
    if (!config.canReconfigure) {
      final compose = config.customComposeConfig;
      if (!app.customApp || compose == null) {
        _showResult(context, l10n.appsNotReconfigurable(app.name), error: true);
        return;
      }
      final edited = await showModalBottomSheet<Map<String, Object?>>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) =>
            CustomAppEditorSheet(appName: app.name, configuration: compose),
      );
      if (edited == null || !context.mounted) return;
      final serverName =
          ref.read(connectionControllerProvider).profile?.name ??
          l10n.systemServerFallback;
      final confirmed = await confirmDestructiveAction(
        context,
        title: l10n.appsCustomComposeConfirmTitle(app.name),
        server: serverName,
        target: app.name,
        actionLabel: l10n.appsCustomComposeApply,
        impact: MutationImpact.high,
        consequences: [
          ImpactDetail(
            icon: Icons.restart_alt_rounded,
            text: l10n.appsCustomComposeRecreateWarning,
          ),
          ImpactDetail(
            icon: Icons.schedule_rounded,
            text: l10n.appsCustomComposeDowntimeWarning,
          ),
        ],
      );
      if (!confirmed || !context.mounted) return;
      final receipt = await controller.updateApp(
        app.id,
        customComposeConfig: edited,
      );
      if (!context.mounted) return;
      _showResult(
        context,
        receipt == null
            ? ref.read(serverActionControllerProvider).errorMessage
            : l10n.appsReconfigureRequested(app.name) +
                  _jobSuffix(l10n, receipt.jobId),
        error: receipt == null,
      );
      return;
    }
    final catalogApp = CatalogApp(
      name: config.catalogApp!,
      title: config.name,
      train: config.train!,
      description: l10n.appsReconfigureDescription,
      healthy: true,
      recommended: false,
      categories: const [],
      tags: const [],
    );
    final connection = ref.read(connectionControllerProvider);
    final detailsResult = await ref
        .read(appsCatalogRepositoryProvider)
        .getInstallationDetails(
          catalogApp,
          supportedMethods: connection.capabilities?.methods,
        );
    if (!context.mounted) return;
    final details = detailsResult.value;
    if (details == null) {
      _showResult(context, switch (detailsResult.error) {
        final error? => l10n.dataMessage(error),
        _ => l10n.appsSchemaLoadFailed,
      }, error: true);
      return;
    }
    final result = await showModalBottomSheet<AppSheetResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => AppInstallationSheet(
        app: catalogApp,
        details: details,
        configuration: config,
      ),
    );
    if (result == null || result is! AppSheetUpdate || !context.mounted) {
      return;
    }
    final receipt = await controller.updateApp(
      app.id,
      values: result.request.values,
    );
    if (!context.mounted) return;
    _showResult(
      context,
      receipt == null
          ? ref.read(serverActionControllerProvider).errorMessage
          : l10n.appsReconfigureRequested(app.name) +
                _jobSuffix(l10n, receipt.jobId),
      error: receipt == null,
    );
  }

  Future<void> _rollbackApp(
    BuildContext context,
    WidgetRef ref,
    InstalledApp app,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(serverActionControllerProvider.notifier);
    final versions = await controller.loadAppRollbackVersions(app.id);
    if (!context.mounted) return;
    if (versions == null) {
      _showResult(
        context,
        ref.read(serverActionControllerProvider).errorMessage,
        error: true,
      );
      return;
    }
    final serverName =
        ref.read(connectionControllerProvider).profile?.name ??
        l10n.systemServerFallback;
    final choice = await showModalBottomSheet<_AppRollbackChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _RollbackAppSheet(
        app: app,
        versions: versions,
        serverName: serverName,
      ),
    );
    if (choice == null || !context.mounted) return;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.appsRollbackTitle(app.name),
      server: serverName,
      target: app.name,
      actionLabel: l10n.appsRollbackAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.restore_rounded,
          text: l10n.appsRollbackConsequenceRebuild,
        ),
        ImpactDetail(
          icon: Icons.history_rounded,
          text: l10n.appsRollbackConsequenceData,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;
    final receipt = await controller.rollbackApp(
      app.id,
      appVersion: choice.version,
    );
    if (!context.mounted) return;
    _showResult(
      context,
      receipt == null
          ? ref.read(serverActionControllerProvider).errorMessage
          : l10n.appsRollbackRequested(app.name) +
                _jobSuffix(l10n, receipt.jobId),
      error: receipt == null,
    );
  }

  Future<void> _deleteApp(
    BuildContext context,
    WidgetRef ref,
    InstalledApp app,
  ) async {
    final l10n = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<_AppRemovalChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _DeleteAppSheet(appName: app.name),
    );
    if (choice == null || !context.mounted) return;

    final serverName =
        ref.read(connectionControllerProvider).profile?.name ??
        l10n.systemServerFallback;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.appsRemoveTitle(app.name),
      server: serverName,
      target: app.name,
      actionLabel: l10n.appsRemoveAction,
      impact: MutationImpact.critical,
      confirmationText: app.name,
      consequences: [
        ImpactDetail(
          icon: Icons.delete_forever_rounded,
          text: l10n.appsRemoveConsequenceApp(serverName),
        ),
        if (choice.removeImages)
          ImpactDetail(
            icon: Icons.broken_image_outlined,
            text: l10n.appsRemoveConsequenceImages,
          ),
        if (!choice.keepVolumes)
          ImpactDetail(
            icon: Icons.folder_delete_outlined,
            text: l10n.appsRemoveConsequenceVolumesDeleted,
          ),
        if (choice.keepVolumes)
          ImpactDetail(
            icon: Icons.folder_copy_outlined,
            text: l10n.appsRemoveConsequenceVolumesKept,
          ),
      ],
    );
    if (!confirmed || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .deleteApp(
          app.id,
          removeImages: choice.removeImages,
          keepVolumes: choice.keepVolumes,
        );
    if (!context.mounted) return;
    _showResult(
      context,
      receipt == null
          ? ref.read(serverActionControllerProvider).errorMessage
          : l10n.appsRemovalRequested(app.name) +
                _jobSuffix(l10n, receipt.jobId),
      error: receipt == null,
    );
  }

  Future<void> _openCatalogDetails(
    BuildContext context,
    WidgetRef ref,
    CatalogApp app, {
    required bool canInstall,
  }) async {
    final l10n = AppLocalizations.of(context);
    final install = await _showCatalogDetails(
      context,
      app,
      canInstall: canInstall,
    );
    if (install != true || !context.mounted) return;

    final connection = ref.read(connectionControllerProvider);
    final result = await ref
        .read(appsCatalogRepositoryProvider)
        .getInstallationDetails(
          app,
          supportedMethods: connection.capabilities?.methods,
        );
    if (!context.mounted) return;
    final details = result.value;
    if (details == null) {
      _showResult(context, switch (result.error) {
        final error? => l10n.dataMessage(error),
        _ => l10n.appsInstallSchemaLoadFailed,
      }, error: true);
      return;
    }
    final request = await showModalBottomSheet<AppSheetResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => AppInstallationSheet(app: app, details: details),
    );
    if (request == null || request is! AppSheetInstall || !context.mounted) {
      return;
    }
    final installReceipt = await ref
        .read(serverActionControllerProvider.notifier)
        .installCatalogApp(request.request);
    if (!context.mounted) return;
    _showResult(
      context,
      installReceipt == null
          ? ref.read(serverActionControllerProvider).errorMessage
          : l10n.appsInstallRequested(request.request.appName) +
                _jobSuffix(l10n, installReceipt.jobId),
      error: installReceipt == null,
    );
  }

  /// Maps a service row to its configuration surface, when the server has one.
  ///
  /// Most services have no `<name>.config` pair, so this returns null and the
  /// row shows no editor. Keyed by the `service.query` name, which does not
  /// always match the API namespace: SMB is `cifs`.
  ConfigurableService? _configurableServiceFor(
    SystemService service,
    ServerCapabilities? capabilities,
  ) {
    for (final candidate in ConfigurableService.values) {
      if (candidate.serviceName != service.name) continue;
      final supported =
          capabilities?.supports(candidate.configMethod) == true &&
          capabilities?.supports(candidate.updateMethod) == true;
      return supported ? candidate : null;
    }
    return null;
  }

  /// Edits a service's configuration.
  ///
  /// Updates are partial, so anything TrueDock does not surface keeps its server
  /// value. A running service restarts to apply the change, which interrupts its
  /// clients, so the confirmation says which of the two cases applies.
  Future<void> _editServiceConfig(
    BuildContext context,
    WidgetRef ref,
    ConfigurableService configurable,
    SystemService service,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(serverActionControllerProvider.notifier);
    final configuration = await controller.loadServiceConfiguration(
      configurable,
    );
    if (!context.mounted) return;
    if (configuration == null) {
      _showResult(
        context,
        ref.read(serverActionControllerProvider).errorMessage,
        error: true,
      );
      return;
    }

    final running = service.state == 'RUNNING';
    final edit = await showModalBottomSheet<ServiceConfigurationEdit>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) =>
          ServiceConfigSheet(configuration: configuration, running: running),
    );
    if (edit == null || !context.mounted) return;
    if (edit.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.sysServiceNoChanges)));
      return;
    }

    final name = l10n.serviceName(configurable);
    final serverName =
        ref.read(connectionControllerProvider).profile?.name ??
        l10n.systemServerFallback;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.sysServiceApplyTitle(name),
      server: serverName,
      target: name,
      actionLabel: l10n.sysServiceApplyAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: running ? Icons.restart_alt_rounded : Icons.schedule_rounded,
          text: running
              ? l10n.sysServiceApplyConsequenceRunning(name)
              : l10n.sysServiceApplyConsequenceStopped(name),
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;

    final receipt = await controller.updateServiceConfiguration(edit);
    if (!context.mounted) return;
    _showResult(
      context,
      receipt == null
          ? ref.read(serverActionControllerProvider).errorMessage
          : l10n.sysServiceUpdated(name),
      error: receipt == null,
    );
  }

  void _showResult(
    BuildContext context,
    String? message, {
    required bool error,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message ?? AppLocalizations.of(context).appsOperationFailed,
        ),
        showCloseIcon: error,
      ),
    );
  }
}

/// Appends the TrueNAS job id to a result message when the mutation started a
/// job, so the user can find it in the job center. A mutation that completed
/// inline has no job and gets no suffix.
String _jobSuffix(AppLocalizations l10n, int? jobId) =>
    jobId == null ? '' : l10n.appsJobSuffix('$jobId');

class _AppsSummary extends StatelessWidget {
  const _AppsSummary({required this.apps});
  final List<InstalledApp> apps;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final running = apps.where((app) => app.state == 'RUNNING').length;
    final updates = apps.where((app) => app.upgradeAvailable).length;
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          const Icon(Icons.widgets_rounded, size: 38),
          const SizedBox(width: 18),
          Expanded(
            child: _SummaryValue(
              value: '${apps.length}',
              label: l10n.appsSummaryInstalled,
            ),
          ),
          Expanded(
            child: _SummaryValue(
              value: '$running',
              label: l10n.appsSummaryRunning,
            ),
          ),
          Expanded(
            child: _SummaryValue(
              value: '$updates',
              label: l10n.appsSummaryUpdates,
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogPreview extends StatelessWidget {
  const _CatalogPreview({required this.catalog, required this.onAppTap});

  final AsyncValue<AppsCatalogSnapshot> catalog;
  final ValueChanged<CatalogApp> onAppTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        AppLocalizations.of(context).appsDiscover,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      catalog.when(
        loading: () => const Card(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
        error: (_, _) => _MessageCard(
          message: AppLocalizations.of(context).appsLoadFailed,
          error: true,
        ),
        data: (snapshot) =>
            _CatalogContents(snapshot: snapshot, onAppTap: onAppTap),
      ),
    ],
  );
}

class _CatalogContents extends StatelessWidget {
  const _CatalogContents({required this.snapshot, required this.onAppTap});

  final AppsCatalogSnapshot snapshot;
  final ValueChanged<CatalogApp> onAppTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final apps = snapshot.apps.value ?? const <CatalogApp>[];
    final trains = snapshot.trains.value ?? const <String>[];
    // Match on the code, not the rendered text: a localized message would not
    // contain the English phrase.
    final unavailable =
        snapshot.apps.error?.code == DataMessageCode.methodUnavailable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (snapshot.dockerStatus.value != null ||
            snapshot.dockerConfiguration.value != null)
          _DockerStatusCard(
            status: snapshot.dockerStatus.value,
            configuration: snapshot.dockerConfiguration.value,
          ),
        if (snapshot.dockerStatus.value != null ||
            snapshot.dockerConfiguration.value != null)
          const SizedBox(height: 12),
        if (snapshot.apps.hasError)
          _MessageCard(
            message: unavailable
                ? l10n.appsCatalogUnsupported
                : l10n.dataMessage(snapshot.apps.error!),
            error: !unavailable,
          )
        else if (apps.isEmpty)
          _MessageCard(message: l10n.appsCatalogEmpty)
        else ...[
          if (trains.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final train in trains) ...[
                    ActionChip(
                      avatar: const Icon(Icons.train_outlined, size: 18),
                      label: Text(train),
                      onPressed: () => _showCatalogBrowser(
                        context,
                        snapshot,
                        onAppTap: onAppTap,
                        initialTrain: train,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Card(
            child: Column(
              children: [
                for (final (index, app) in apps.take(6).indexed) ...[
                  _CatalogAppTile(app: app, onTap: () => onAppTap(app)),
                  if (index < apps.take(6).length - 1)
                    const Divider(indent: 68, height: 1),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () =>
                  _showCatalogBrowser(context, snapshot, onAppTap: onAppTap),
              icon: const Icon(Icons.search_rounded),
              label: Text(l10n.appsBrowseAll(apps.length)),
            ),
          ),
        ],
      ],
    );
  }
}

class _DockerStatusCard extends StatelessWidget {
  const _DockerStatusCard({required this.status, required this.configuration});

  final DockerStatus? status;
  final DockerConfiguration? configuration;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final running = status?.isRunning == true;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: running
                ? colors.primaryContainer
                : colors.surfaceContainerHighest,
            child: Icon(
              Icons.hub_outlined,
              color: running ? colors.onPrimaryContainer : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(l10n.appsDockerService)),
                    Text(
                      status?.status ?? l10n.appsStatusUnknown,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: running
                            ? colors.primary
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  status?.description ?? l10n.appsDockerConfigurationAvailable,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                if (configuration != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    configuration!.pool == null
                        ? l10n.appsNoAppsPool
                        : '${configuration!.pool} · '
                              '${configuration!.imageUpdatesEnabled ? l10n.appsImageUpdatesEnabled : l10n.appsManualImageUpdates}'
                              '${configuration!.nvidiaEnabled ? ' · NVIDIA' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogAppTile extends StatelessWidget {
  const _CatalogAppTile({required this.app, required this.onTap});

  final CatalogApp app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      leading: CircleAvatar(
        child: Text(
          app.title.isEmpty ? '?' : app.title.characters.first.toUpperCase(),
        ),
      ),
      title: Row(
        children: [
          Expanded(child: Text(app.title)),
          if (app.recommended) const Icon(Icons.recommend_outlined, size: 19),
        ],
      ),
      subtitle: Text(
        l10n.appsCatalogTileSubtitle(
          app.train,
          app.latestVersion ?? l10n.appsVersionUnavailable,
          l10n.appCatalogText(app.description),
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _CatalogBrowser extends StatefulWidget {
  const _CatalogBrowser({
    required this.snapshot,
    required this.onAppTap,
    this.initialTrain,
  });

  final AppsCatalogSnapshot snapshot;
  final ValueChanged<CatalogApp> onAppTap;
  final String? initialTrain;

  @override
  State<_CatalogBrowser> createState() => _CatalogBrowserState();
}

class _CatalogBrowserState extends State<_CatalogBrowser> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _train;

  @override
  void initState() {
    super.initState();
    _train = widget.initialTrain;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allApps = widget.snapshot.apps.value ?? const <CatalogApp>[];
    final trains =
        widget.snapshot.trains.value ??
        ({for (final app in allApps) app.train}.toList()..sort());
    final apps = allApps
        .where(
          (app) =>
              (_train == null || app.train == _train) && app.matches(_query),
        )
        .toList(growable: false);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .9,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.appsDiscoverApps,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: l10n.actionClose,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SearchBar(
                controller: _searchController,
                leading: const Icon(Icons.search_rounded),
                hintText: l10n.appsSearchHint,
                onChanged: (value) => setState(() => _query = value),
                trailing: [
                  if (_query.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.clear_rounded),
                      tooltip: l10n.appsClearSearch,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text(l10n.appsAllTrains),
                      selected: _train == null,
                      onSelected: (_) => setState(() => _train = null),
                    ),
                    for (final train in trains) ...[
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(train),
                        selected: _train == train,
                        onSelected: (_) => setState(() => _train = train),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(l10n.appsAppCount(apps.length)),
              const SizedBox(height: 6),
              Expanded(
                child: apps.isEmpty
                    ? Center(child: Text(l10n.appsNoSearchResults))
                    : ListView.separated(
                        itemCount: apps.length,
                        separatorBuilder: (_, _) => const Divider(indent: 68),
                        itemBuilder: (context, index) {
                          final app = apps[index];
                          return _CatalogAppTile(
                            app: app,
                            onTap: () => widget.onAppTap(app),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showCatalogBrowser(
  BuildContext context,
  AppsCatalogSnapshot snapshot, {
  required ValueChanged<CatalogApp> onAppTap,
  String? initialTrain,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _CatalogBrowser(
      snapshot: snapshot,
      initialTrain: initialTrain,
      onAppTap: onAppTap,
    ),
  );
}

Future<bool?> _showCatalogDetails(
  BuildContext context,
  CatalogApp app, {
  required bool canInstall,
}) {
  final l10n = AppLocalizations.of(context);
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(
        app.healthy ? Icons.verified_outlined : Icons.warning_amber_rounded,
      ),
      title: Text(app.title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.appCatalogText(app.description)),
            const SizedBox(height: 16),
            _CatalogDetail(label: l10n.appsLabelTrain, value: app.train),
            _CatalogDetail(
              label: l10n.appsLabelVersion,
              value: app.latestVersion ?? l10n.appsUnavailable,
            ),
            _CatalogDetail(
              label: l10n.appsLabelHealth,
              value: app.healthy
                  ? l10n.appsCatalogHealthy
                  : l10n.appsNeedsAttention,
            ),
            if (app.categories.isNotEmpty)
              _CatalogDetail(
                label: l10n.appsLabelCategories,
                value: app.categories.join(', '),
              ),
            if (app.tags.isNotEmpty)
              _CatalogDetail(
                label: l10n.appsLabelTags,
                value: app.tags.join(', '),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.actionClose),
        ),
        FilledButton.icon(
          onPressed: canInstall && app.healthy
              ? () => Navigator.pop(context, true)
              : null,
          icon: const Icon(Icons.download_rounded),
          label: Text(
            canInstall
                ? (app.healthy
                      ? l10n.appsConfigureInstall
                      : l10n.appsAppUnavailable)
                : l10n.appsInstallUnsupported,
          ),
        ),
      ],
    ),
  );
}

class _CatalogDetail extends StatelessWidget {
  const _CatalogDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _AppTile extends StatelessWidget {
  const _AppTile({
    required this.app,
    required this.lifecycleBusy,
    required this.upgradeBusy,
    required this.canUpgrade,
    required this.onToggle,
    required this.onOpen,
    required this.onUpgrade,
    required this.onRedeploy,
    required this.onReconfigure,
    required this.onRollback,
    required this.onDelete,
    this.canRedeploy = false,
    this.canReconfigure = false,
    this.canRollback = false,
    this.canDelete = false,
  });
  final InstalledApp app;
  final bool lifecycleBusy;
  final bool upgradeBusy;
  final bool canUpgrade;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  final VoidCallback onUpgrade;
  final VoidCallback onRedeploy;
  final VoidCallback onReconfigure;
  final VoidCallback onRollback;
  final VoidCallback onDelete;
  final bool canRedeploy;
  final bool canReconfigure;
  final bool canRollback;
  final bool canDelete;

  bool get _anyLifecycleAction =>
      canRedeploy || canReconfigure || canRollback || canDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final running = app.state == 'RUNNING';
    final busy = lifecycleBusy || upgradeBusy;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      leading: CircleAvatar(
        child: Icon(running ? Icons.play_arrow_rounded : Icons.stop_rounded),
      ),
      title: Row(
        children: [
          Expanded(child: Text(app.name)),
          if (app.upgradeAvailable)
            const Icon(Icons.system_update_alt_rounded, size: 18),
        ],
      ),
      subtitle: Text(
        '${l10n.appRuntimeState(app.state)} · ${l10n.appVersionLabel(app.version)}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_anyLifecycleAction)
            PopupMenuButton<_AppOverflowAction>(
              tooltip: l10n.appsMoreActions,
              enabled: !busy,
              onSelected: (action) {
                switch (action) {
                  case _AppOverflowAction.redeploy:
                    onRedeploy();
                  case _AppOverflowAction.reconfigure:
                    onReconfigure();
                  case _AppOverflowAction.rollback:
                    onRollback();
                  case _AppOverflowAction.delete:
                    onDelete();
                }
              },
              itemBuilder: (context) => [
                if (canRedeploy)
                  PopupMenuItem(
                    value: _AppOverflowAction.redeploy,
                    child: ListTile(
                      leading: const Icon(Icons.refresh_rounded),
                      title: Text(l10n.appsRedeploy),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (canReconfigure)
                  PopupMenuItem(
                    value: _AppOverflowAction.reconfigure,
                    child: ListTile(
                      leading: const Icon(Icons.tune_rounded),
                      title: Text(l10n.appsReconfigure),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (canRollback)
                  PopupMenuItem(
                    value: _AppOverflowAction.rollback,
                    child: ListTile(
                      leading: const Icon(Icons.restore_rounded),
                      title: Text(l10n.appsRollbackMenu),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (canDelete)
                  PopupMenuItem(
                    value: _AppOverflowAction.delete,
                    child: ListTile(
                      leading: Icon(
                        Icons.delete_outline_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(
                        l10n.appsRemoveAction,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          if (app.catalogUpgradeAvailable)
            upgradeBusy
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                : IconButton(
                    onPressed: canUpgrade ? onUpgrade : null,
                    icon: const Icon(Icons.system_update_alt_rounded),
                    tooltip: canUpgrade
                        ? l10n.appsReviewUpgrade
                        : l10n.appsUpgradeUnsupported,
                  ),
          lifecycleBusy
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                )
              : IconButton.filledTonal(
                  onPressed: upgradeBusy ? null : onToggle,
                  icon: Icon(
                    running ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  ),
                  tooltip: running ? l10n.appsStopApp : l10n.appsStartApp,
                ),
        ],
      ),
      onTap: busy ? null : onOpen,
    );
  }
}

enum _AppOverflowAction { redeploy, reconfigure, rollback, delete }

class _UpgradeAppSheet extends StatefulWidget {
  const _UpgradeAppSheet({required this.app, required this.summary});

  final InstalledApp app;
  final AppUpgradeSummary summary;

  @override
  State<_UpgradeAppSheet> createState() => _UpgradeAppSheetState();
}

class _UpgradeAppSheetState extends State<_UpgradeAppSheet> {
  late String _version;
  bool _snapshotHostPaths = true;

  List<AppUpgradeVersion> get _versions =>
      widget.summary.availableVersions.isEmpty
      ? [widget.summary.versionOrFallback(widget.summary.selectedVersion)]
      : widget.summary.availableVersions;

  AppUpgradeVersion get _selected => widget.summary.versionOrFallback(_version);

  @override
  void initState() {
    super.initState();
    final target = widget.summary.selectedVersion;
    _version = _versions.any((version) => version.version == target)
        ? target
        : _versions.first.version;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .82,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colors.primaryContainer,
                    child: Icon(
                      Icons.system_update_alt_rounded,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.appsUpgradeSheetTitle(widget.app.name),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          l10n.appsVersionTransition(
                            widget.app.version,
                            _version,
                          ),
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              TrueDockDropdownMenu<String>(
                expandedInsets: EdgeInsets.zero,
                initialSelection: _version,
                label: Text(l10n.appsTargetVersion),
                dropdownMenuEntries: [
                  for (final version in _versions)
                    DropdownMenuEntry(
                      value: version.version,
                      label: version.humanVersion,
                      trailingIcon:
                          version.version == widget.summary.latestVersion
                          ? const Icon(Icons.new_releases_outlined)
                          : null,
                    ),
                ],
                onSelected: (value) {
                  if (value != null) setState(() => _version = value);
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _snapshotHostPaths,
                onChanged: (value) =>
                    setState(() => _snapshotHostPaths = value),
                title: Text(l10n.appsSnapshotHostPaths),
                subtitle: Text(l10n.appsSnapshotHostPathsSubtitle),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.tertiaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l10n.appsUpgradeNotice)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.appsReleaseNotes,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      _selected.changelog ?? l10n.appsNoReleaseNotes,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.actionCancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(
                      context,
                      AppUpgradeChoice(
                        version: _version,
                        snapshotHostPaths: _snapshotHostPaths,
                      ),
                    ),
                    icon: const Icon(Icons.system_update_alt_rounded),
                    label: Text(l10n.appsUpgradeAction),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VmTile extends StatelessWidget {
  const _VmTile({required this.vm});

  final VirtualMachine vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      leading: CircleAvatar(
        child: Icon(
          vm.isRunning ? Icons.computer_rounded : Icons.computer_outlined,
        ),
      ),
      title: Text(vm.name),
      subtitle: Text(
        l10n.appsVmSubtitle(
          vm.state,
          vm.vcpus * vm.cores * vm.threads,
          vm.memoryMiB,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => _VmDetails(vm: vm),
      ),
    );
  }
}

/// Selection returned by [_RollbackAppSheet] to [_rollbackApp]. Carries the
/// image version the user wants to roll the app back to.
class _AppRollbackChoice {
  const _AppRollbackChoice({required this.version});

  final String version;
}

/// Selects the target version for an `app.rollback` job.
///
/// The list comes from `app.rollback_versions`, which reports the versions this
/// app was previously deployed at. It is not the upgrade summary: that method
/// describes upgrade targets and errors out once the app is on the newest
/// version, which is exactly when a rollback is wanted.
class _RollbackAppSheet extends StatefulWidget {
  const _RollbackAppSheet({
    required this.app,
    required this.versions,
    required this.serverName,
  });

  final InstalledApp app;

  /// Versions the server says this app can be rolled back to, newest first.
  final List<String> versions;
  final String serverName;

  @override
  State<_RollbackAppSheet> createState() => _RollbackAppSheetState();
}

class _RollbackAppSheetState extends State<_RollbackAppSheet> {
  late String _version;

  /// Rolling back to the version already running is a no-op, so it is not
  /// offered.
  List<String> get _versions => widget.versions
      .where((version) => version != widget.app.version)
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _version = _versions.isNotEmpty ? _versions.first : widget.app.version;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .74,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colors.tertiaryContainer,
                    child: Icon(
                      Icons.restore_rounded,
                      color: colors.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.appsRollbackSheetTitle(widget.app.name),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          l10n.appsVersionTransition(
                            widget.app.version,
                            _version,
                          ),
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              TrueDockDropdownMenu<String>(
                expandedInsets: EdgeInsets.zero,
                initialSelection: _version,
                label: Text(l10n.appsTargetVersion),
                dropdownMenuEntries: [
                  for (final version in _versions)
                    DropdownMenuEntry(value: version, label: version),
                ],
                onSelected: (value) {
                  if (value != null) setState(() => _version = value);
                },
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.history_rounded, color: colors.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.appsRollbackSheetNotice(widget.serverName),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.actionCancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    // Nothing to roll back to when the server lists no prior
                    // version, so the action stays disabled rather than
                    // submitting a job the server will reject.
                    onPressed: _versions.isEmpty
                        ? null
                        : () => Navigator.pop(
                            context,
                            _AppRollbackChoice(version: _version),
                          ),
                    icon: const Icon(Icons.restore_rounded),
                    label: Text(l10n.actionContinue),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VmDetails extends ConsumerWidget {
  const _VmDetails({required this.vm});

  final VirtualMachine vm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final capabilities = ref.watch(connectionControllerProvider).capabilities;
    final supported = {
      if (capabilities?.supports('vm.start') == true) InstanceVerb.start,
      if (capabilities?.supports('vm.stop') == true) InstanceVerb.stop,
      if (capabilities?.supports('vm.restart') == true) InstanceVerb.restart,
      if (capabilities?.supports('vm.poweroff') == true) InstanceVerb.powerOff,
    };
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(vm.name, style: Theme.of(context).textTheme.headlineSmall),
            if (vm.description != null) ...[
              const SizedBox(height: 6),
              Text(
                vm.description!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 20),
            _VmDetail(label: l10n.appsLabelState, value: vm.state),
            _VmDetail(
              label: l10n.appsLabelCpu,
              value: l10n.appsCpuSummary(vm.vcpus, vm.cores, vm.threads),
            ),
            _VmDetail(
              label: l10n.appsLabelMemory,
              value: l10n.appsMemoryMiB(vm.memoryMiB),
            ),
            _VmDetail(
              label: l10n.appsLabelAutostart,
              value: vm.autostart ? l10n.appsEnabled : l10n.appsDisabled,
            ),
            _VmDetail(
              label: l10n.appsLabelDisplay,
              value: vm.displayAvailable
                  ? l10n.appsDisplayAvailable
                  : l10n.appsDisplayNotConfigured,
            ),
            const SizedBox(height: 18),
            InstanceLifecycleControls(
              name: vm.name,
              kind: l10n.appsKindVirtualMachine,
              running: vm.isRunning,
              busyKey: 'vm:${vm.id}',
              supportedVerbs: supported,
              onInvoke: (verb) => _controlVm(context, ref, verb),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (capabilities?.supports('vm.update') == true)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editVmConfig(context, ref),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(l10n.appsEdit),
                    ),
                  ),
                if (capabilities?.supports('vm.update') == true &&
                    capabilities?.supports('vm.device.query') == true)
                  const SizedBox(width: 12),
                if (capabilities?.supports('vm.device.query') == true)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _manageVmDevices(context, ref),
                      icon: const Icon(Icons.memory_outlined),
                      label: Text(l10n.appsDevices),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _controlVm(
    BuildContext context,
    WidgetRef ref,
    InstanceVerb verb,
  ) async {
    final l10n = AppLocalizations.of(context);
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .controlVirtualMachine(vm.id, verb);
    if (!context.mounted) return;
    final error = ref.read(serverActionControllerProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          receipt == null
              ? error ??
                    l10n.appsControlFailed(
                      localizedVerbLabel(l10n, verb).toLowerCase(),
                      vm.name,
                    )
              : l10n.appsVerbRequested(localizedVerbLabel(l10n, verb), vm.name),
        ),
        showCloseIcon: receipt == null,
      ),
    );
  }

  Future<void> _editVmConfig(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final baseline = VmConfiguration.fromVm(vm);
    final next = await showModalBottomSheet<VmConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => VmConfigSheet(vm: vm),
    );
    if (next == null || !context.mounted) return;
    final diff = next.changedFields(baseline);
    if (diff.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.appsNoChanges)));
      return;
    }
    final serverName =
        ref.read(connectionControllerProvider).profile?.name ??
        l10n.systemServerFallback;
    final changingRuntime =
        diff.containsKey('vcpus') ||
        diff.containsKey('cores') ||
        diff.containsKey('threads') ||
        diff.containsKey('memory') ||
        diff.containsKey('bootloader') ||
        diff.containsKey('cpu_mode');
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.appsSaveChangesTitle(vm.name),
      server: serverName,
      target: vm.name,
      actionLabel: l10n.actionSaveChanges,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.memory_rounded,
          text: changingRuntime
              ? (vm.isRunning
                    ? l10n.appsVmRuntimeChangeRunning
                    : l10n.appsVmRuntimeChangeStopped)
              : l10n.appsConfigUpdatedOnServer,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .updateVirtualMachine(vm.id, next: next, baseline: baseline);
    if (!context.mounted) return;
    final error = ref.read(serverActionControllerProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          receipt == null
              ? error ?? l10n.appsUpdateFailed(vm.name)
              : l10n.appsVmUpdated(vm.name),
        ),
        showCloseIcon: receipt == null,
      ),
    );
  }

  Future<void> _manageVmDevices(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(serverActionControllerProvider.notifier);
    final devicesOrNull = await controller.getVirtualMachineDevices(vm.id);
    if (!context.mounted) return;
    if (devicesOrNull == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.appsVmDevicesLoadFailed),
          showCloseIcon: true,
        ),
      );
      return;
    }
    final devices = devicesOrNull;
    final canCreate =
        ref
            .read(connectionControllerProvider)
            .capabilities
            ?.supports('vm.device.create') ==
        true;
    final canDelete =
        ref
            .read(connectionControllerProvider)
            .capabilities
            ?.supports('vm.device.delete') ==
        true;
    final canEdit =
        ref
            .read(connectionControllerProvider)
            .capabilities
            ?.supports('vm.device.update') ==
        true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => VmDeviceSheet(
        devices: devices,
        canCreate: canCreate,
        canDelete: canDelete,
        canEdit: canEdit,
        onAddDevice: () => _addVmDevice(context, ref, controller),
        onDeleteDevice: (device) =>
            _deleteVmDevice(context, ref, controller, device),
        onEditDevice: (device) =>
            _editVmDevice(context, ref, controller, device),
      ),
    );
    // Refresh the parent resource section so the device count updates.
    ref.invalidate(serverResourcesProvider);
  }

  Future<VmDeviceConfiguration?> _addVmDevice(
    BuildContext context,
    WidgetRef ref,
    ServerActionController controller,
  ) async {
    final l10n = AppLocalizations.of(context);
    final configuration = await showModalBottomSheet<VmDeviceConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const VmDeviceAddSheet(),
    );
    if (configuration == null || !context.mounted) return null;
    final serverName =
        ref.read(connectionControllerProvider).profile?.name ??
        l10n.systemServerFallback;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.appsAddDeviceTitle(
        l10n.vmDeviceTypeLabel(configuration.dtype),
        vm.name,
      ),
      server: serverName,
      target: vm.name,
      actionLabel: l10n.appsAddDevice,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.add_circle_outline_rounded,
          text: l10n.appsAddDeviceConsequence(vm.name),
        ),
      ],
    );
    if (!confirmed || !context.mounted) return null;
    final receipt = await controller.createVirtualMachineDevice(
      vm.id,
      configuration,
    );
    if (!context.mounted) return null;
    final error = ref.read(serverActionControllerProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          receipt == null
              ? error ?? l10n.appsAddDeviceFailed
              : l10n.appsDeviceAdded(vm.name),
        ),
        showCloseIcon: receipt == null,
      ),
    );
    return null;
  }

  Future<bool> _deleteVmDevice(
    BuildContext context,
    WidgetRef ref,
    ServerActionController controller,
    VmDevice device,
  ) async {
    return _removeVmDevice(context, ref, controller, device);
  }

  /// Edits an existing device via `vm.device.update`.
  ///
  /// The form seeds from the current attributes and preserves the ones it does
  /// not surface, because TrueNAS replaces the attribute set rather than
  /// merging it.
  Future<bool> _editVmDevice(
    BuildContext context,
    WidgetRef ref,
    ServerActionController controller,
    VmDevice device,
  ) async {
    final l10n = AppLocalizations.of(context);
    final configuration = await showModalBottomSheet<VmDeviceConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => VmDeviceAddSheet(existing: device),
    );
    if (configuration == null || !context.mounted) return false;
    final serverName =
        ref.read(connectionControllerProvider).profile?.name ??
        l10n.systemServerFallback;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.appsSaveDeviceTitle(
        l10n.vmDeviceTypeLabel(configuration.dtype),
        vm.name,
      ),
      server: serverName,
      target: l10n.appsDeviceTarget(
        vm.name,
        l10n.vmDeviceTypeLabel(device.type),
      ),
      actionLabel: l10n.appsSaveDevice,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.edit_outlined,
          text: l10n.appsEditDeviceConsequence(vm.name),
        ),
        ImpactDetail(
          icon: Icons.warning_amber_rounded,
          text: l10n.appsEditDeviceDiskWarning,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return false;
    final receipt = await controller.updateVirtualMachineDevice(
      device.id,
      configuration,
    );
    if (!context.mounted) return false;
    final error = ref.read(serverActionControllerProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          receipt == null
              ? error ?? l10n.appsUpdateDeviceFailed
              : l10n.appsDeviceUpdated(vm.name),
        ),
        showCloseIcon: receipt == null,
      ),
    );
    return receipt != null;
  }

  Future<bool> _removeVmDevice(
    BuildContext context,
    WidgetRef ref,
    ServerActionController controller,
    VmDevice device,
  ) async {
    final l10n = AppLocalizations.of(context);
    final serverName =
        ref.read(connectionControllerProvider).profile?.name ??
        l10n.systemServerFallback;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.appsRemoveDeviceTitle(
        l10n.vmDeviceTypeLabel(device.type),
        vm.name,
      ),
      server: serverName,
      target: l10n.appsDeviceTarget(
        vm.name,
        l10n.vmDeviceTypeLabel(device.type),
      ),
      actionLabel: l10n.appsRemoveDevice,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.link_off_rounded,
          text: l10n.appsRemoveDeviceConsequence,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return false;
    final receipt = await controller.deleteVirtualMachineDevice(device.id);
    if (!context.mounted) return false;
    final error = ref.read(serverActionControllerProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          receipt == null
              ? error ?? l10n.appsRemoveDeviceFailed
              : l10n.appsDeviceRemoved(vm.name),
        ),
        showCloseIcon: receipt == null,
      ),
    );
    return receipt != null;
  }
}

class _ContainerTile extends StatelessWidget {
  const _ContainerTile({required this.container});

  final ManagedContainer container;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      leading: CircleAvatar(
        child: Icon(
          container.isRunning
              ? Icons.widgets_rounded
              : Icons.inventory_2_outlined,
        ),
      ),
      title: Text(container.name),
      subtitle: Text(
        l10n.appsContainerSubtitle(
          container.state,
          container.dataset,
          container.deviceCount,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => _ContainerDetails(container: container),
      ),
    );
  }
}

class _ContainerDetails extends ConsumerWidget {
  const _ContainerDetails({required this.container});

  final ManagedContainer container;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final capabilities = ref.watch(connectionControllerProvider).capabilities;
    final supported = {
      if (capabilities?.supports('container.start') == true) InstanceVerb.start,
      if (capabilities?.supports('container.stop') == true) ...[
        InstanceVerb.stop,
        InstanceVerb.powerOff,
      ],
      if (capabilities?.supports('container.restart') == true)
        InstanceVerb.restart,
    };
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              container.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (container.description != null) ...[
              const SizedBox(height: 6),
              Text(
                container.description!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 20),
            _VmDetail(label: l10n.appsLabelState, value: container.state),
            _VmDetail(label: l10n.appsLabelDataset, value: container.dataset),
            _VmDetail(label: l10n.appsLabelUuid, value: container.uuid),
            _VmDetail(
              label: l10n.appsLabelDevices,
              value: '${container.deviceCount}',
            ),
            _VmDetail(
              label: l10n.appsLabelNetwork,
              value: container.defaultNetwork ?? l10n.appsNetworkByDevices,
            ),
            _VmDetail(
              label: l10n.appsLabelAutostart,
              value: container.autostart ? l10n.appsEnabled : l10n.appsDisabled,
            ),
            const SizedBox(height: 18),
            InstanceLifecycleControls(
              name: container.name,
              kind: l10n.appsKindContainer,
              running: container.isRunning,
              busyKey: 'container:${container.id}',
              supportedVerbs: supported,
              onInvoke: (verb) => _controlContainer(context, ref, verb),
            ),
            const SizedBox(height: 12),
            if (capabilities?.supports('container.update') == true)
              OutlinedButton.icon(
                onPressed: () => _editContainerConfig(context, ref),
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.appsEdit),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _controlContainer(
    BuildContext context,
    WidgetRef ref,
    InstanceVerb verb,
  ) async {
    final l10n = AppLocalizations.of(context);
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .controlContainer(container.id, verb);
    if (!context.mounted) return;
    final error = ref.read(serverActionControllerProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          receipt == null
              ? error ??
                    l10n.appsControlFailed(
                      localizedVerbLabel(l10n, verb).toLowerCase(),
                      container.name,
                    )
              : l10n.appsVerbRequested(
                  localizedVerbLabel(l10n, verb),
                  container.name,
                ),
        ),
        showCloseIcon: receipt == null,
      ),
    );
  }

  Future<void> _editContainerConfig(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(serverActionControllerProvider.notifier);
    final raw = await controller.getContainerConfig(container.id);
    if (!context.mounted) return;
    if (raw == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.appsContainerConfigLoadFailed),
          showCloseIcon: true,
        ),
      );
      return;
    }
    final baseline = ContainerConfiguration.fromRawConfig(raw);
    final deviceChoices = await controller.getContainerDeviceChoices();
    if (!context.mounted) return;
    final next = await showModalBottomSheet<ContainerConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ContainerConfigSheet(
        container: container,
        baseline: baseline,
        deviceChoices: deviceChoices ?? const {},
      ),
    );
    if (next == null || !context.mounted) return;
    final serverName =
        ref.read(connectionControllerProvider).profile?.name ??
        l10n.systemServerFallback;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.appsSaveChangesTitle(container.name),
      server: serverName,
      target: container.name,
      actionLabel: l10n.actionSaveChanges,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.inventory_2_outlined,
          text: l10n.appsContainerUpdateConsequence,
        ),
        ImpactDetail(
          icon: Icons.restart_alt_rounded,
          text: container.isRunning
              ? l10n.appsContainerRestartToApply(container.name)
              : l10n.appsContainerStartToApply,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;
    final receipt = await controller.updateContainer(container.id, next);
    if (!context.mounted) return;
    final error = ref.read(serverActionControllerProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          receipt == null
              ? error ?? l10n.appsUpdateFailed(container.name)
              : l10n.appsContainerUpdated(container.name),
        ),
        showCloseIcon: receipt == null,
      ),
    );
  }
}

class _VmDetail extends StatelessWidget {
  const _VmDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, this.error = false});
  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: error ? colors.errorContainer : null,
      child: Padding(padding: const EdgeInsets.all(20), child: Text(message)),
    );
  }
}

class _AppRemovalChoice {
  const _AppRemovalChoice({
    required this.removeImages,
    required this.keepVolumes,
  });
  final bool removeImages;
  final bool keepVolumes;
}

class _DeleteAppSheet extends StatefulWidget {
  const _DeleteAppSheet({required this.appName});
  final String appName;

  @override
  State<_DeleteAppSheet> createState() => _DeleteAppSheetState();
}

class _DeleteAppSheetState extends State<_DeleteAppSheet> {
  bool _removeImages = false;
  bool _keepVolumes = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.appsRemovalSheetTitle(widget.appName),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.appsRemovalSheetBody,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          SwitchListTile(
            value: _removeImages,
            onChanged: (value) => setState(() => _removeImages = value),
            title: Text(l10n.appsRemoveImages),
            subtitle: Text(l10n.appsRemoveImagesSubtitle),
          ),
          SwitchListTile(
            value: _keepVolumes,
            onChanged: (value) => setState(() => _keepVolumes = value),
            title: Text(l10n.appsKeepVolumes),
            subtitle: Text(
              _keepVolumes ? l10n.appsKeepVolumesOn : l10n.appsKeepVolumesOff,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.actionCancel),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).pop(
                  _AppRemovalChoice(
                    removeImages: _removeImages,
                    keepVolumes: _keepVolumes,
                  ),
                ),
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(l10n.appsReviewRemoval),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
