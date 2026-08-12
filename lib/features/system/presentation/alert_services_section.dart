import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/destructive_confirmation.dart';
import '../../../l10n/app_localizations.dart';
import '../../actions/presentation/server_action_controller.dart';
import '../../connection/presentation/connection_controller.dart';
import '../domain/alert_class_configuration.dart';
import '../domain/alert_service_configuration.dart';
import 'alert_classes_sheet.dart';
import 'alert_service_sheet.dart';

/// Alert destinations (`alertservice.*`).
///
/// Loads its own list rather than joining the shared resource batch: these are
/// not dashboard data, and that batch already fans out enough concurrent reads
/// to matter against the server's per-connection call cap.
class AlertServicesSection extends ConsumerStatefulWidget {
  const AlertServicesSection({super.key});

  @override
  ConsumerState<AlertServicesSection> createState() =>
      _AlertServicesSectionState();
}

class _AlertServicesSectionState extends ConsumerState<AlertServicesSection> {
  List<AlertServiceEntry>? _services;
  String? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final services = await ref
        .read(serverActionControllerProvider.notifier)
        .loadAlertServices();
    if (!mounted) return;
    setState(() {
      _services = services;
      _error = services == null
          ? ref.read(serverActionControllerProvider).errorMessage
          : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final capabilities = ref.watch(connectionControllerProvider).capabilities;
    final canCreate = capabilities?.supports('alertservice.create') == true;
    final canUpdate = capabilities?.supports('alertservice.update') == true;
    final canDelete = capabilities?.supports('alertservice.delete') == true;
    final canTest = capabilities?.supports('alertservice.test') == true;
    final services = _services;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.sysAlertServicesSubtitle, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 14),
        if (_loading)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (_error != null)
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(_error!),
            ),
          )
        else if (services == null || services.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(l10n.sysAlertServicesEmpty),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (final (index, service) in services.indexed) ...[
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    leading: CircleAvatar(
                      child: Icon(
                        service.enabled
                            ? Icons.notifications_active_outlined
                            : Icons.notifications_off_outlined,
                      ),
                    ),
                    title: Text(service.name),
                    subtitle: Text(
                      // A destination TrueDock does not model still has to be
                      // listed, so its type falls back to whatever the server
                      // reported.
                      '${service.kind == null ? '?' : l10n.alertKindLabel(service.kind!)}'
                      ' · ${l10n.alertLevelLabel(service.level)}'
                      '${service.enabled ? '' : ' · ${l10n.sysAlertServiceDisabled}'}',
                    ),
                    trailing: canUpdate || canDelete
                        ? PopupMenuButton<_AlertAction>(
                            itemBuilder: (context) => [
                              if (canUpdate && service.kind != null)
                                PopupMenuItem(
                                  value: _AlertAction.edit,
                                  child: Text(l10n.sysEdit),
                                ),
                              if (canDelete)
                                PopupMenuItem(
                                  value: _AlertAction.delete,
                                  child: Text(l10n.sysDelete),
                                ),
                            ],
                            onSelected: (action) => switch (action) {
                              _AlertAction.edit => _edit(service),
                              _AlertAction.delete => _delete(service),
                            },
                          )
                        : null,
                    onTap: canUpdate && service.kind != null
                        ? () => _edit(service)
                        : service.kind == null
                        ? () => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.sysAlertServiceUnknownKind),
                            ),
                          )
                        : null,
                  ),
                  if (index < services.length - 1)
                    const Divider(indent: 68, height: 1),
                ],
              ],
            ),
          ),
        if (canCreate) ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _create(canTest: canTest),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.sysAlertServiceCreate),
          ),
        ],
        // Destinations are only half the story: a class set to NEVER reaches no
        // destination at all, and nothing else in the app reveals that.
        if (capabilities?.supports('alertclasses.config') == true) ...[
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.rule_rounded),
              title: Text(l10n.sysAlertClassesTitle),
              subtitle: Text(l10n.sysAlertClassesSubtitle),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _editAlertClasses(
                editable: capabilities?.supports('alertclasses.update') == true,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Reviews and edits the per-class policies.
  ///
  /// `alertclasses.update` replaces the whole override map, so the sheet returns
  /// the full merged configuration and the payload is rebuilt from it; sending
  /// one class would silently reset every other override.
  Future<void> _editAlertClasses({required bool editable}) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(serverActionControllerProvider.notifier);
    final configuration = await controller.loadAlertClasses();
    if (!mounted) return;
    if (configuration == null) {
      _report(false, '');
      return;
    }

    final next = await showModalBottomSheet<AlertClassConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => AlertClassesSheet(configuration: configuration),
    );
    if (next == null || !mounted) return;
    if (!editable) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.sysAlertClassesNoChanges)));
      return;
    }

    final serverName =
        ref.read(connectionControllerProvider).profile?.name ??
        l10n.systemServerFallback;
    final silenced = next.silenced.length;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.sysAlertClassesApplyTitle,
      server: serverName,
      target: l10n.sysAlertClassesTitle,
      actionLabel: l10n.sysAlertClassesApplyAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.swap_horiz_rounded,
          text: l10n.sysAlertClassesApplyReplace,
        ),
        if (silenced > 0)
          ImpactDetail(
            icon: Icons.notifications_off_outlined,
            text: l10n.sysAlertClassesApplyConsequence,
          ),
      ],
    );
    if (!confirmed || !mounted) return;

    final receipt = await controller.updateAlertClasses(
      AlertClassEdit.fromConfiguration(next),
    );
    if (!mounted) return;
    _report(receipt != null, l10n.sysAlertClassesUpdated);
  }

  Future<void> _create({required bool canTest}) async {
    final l10n = AppLocalizations.of(context);
    final result = await showModalBottomSheet<AlertServiceSheetResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const AlertServiceSheet(),
    );
    if (result == null || !mounted) return;
    final controller = ref.read(serverActionControllerProvider.notifier);
    if (result.test) {
      final receipt = await controller.testAlertService(result.configuration);
      if (!mounted) return;
      _report(
        receipt != null,
        l10n.sysAlertServiceTested(result.configuration.name),
      );
      return;
    }
    final receipt = await controller.createAlertService(result.configuration);
    if (!mounted) return;
    _report(receipt != null, l10n.sysAlertServiceCreated);
    if (receipt != null) await _load();
  }

  Future<void> _edit(AlertServiceEntry service) async {
    final l10n = AppLocalizations.of(context);
    final result = await showModalBottomSheet<AlertServiceSheetResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => AlertServiceSheet(existing: service),
    );
    if (result == null || !mounted) return;
    final controller = ref.read(serverActionControllerProvider.notifier);
    if (result.test) {
      final receipt = await controller.testAlertService(result.configuration);
      if (!mounted) return;
      _report(receipt != null, l10n.sysAlertServiceTested(service.name));
      return;
    }
    final receipt = await controller.updateAlertService(
      service.id,
      result.configuration,
      // The editor leaves secrets blank, and the server requires them, so the
      // queried values stand in for anything the user did not retype.
      storedSecrets: service.attributes,
    );
    if (!mounted) return;
    _report(receipt != null, l10n.sysAlertServiceUpdated);
    if (receipt != null) await _load();
  }

  Future<void> _delete(AlertServiceEntry service) async {
    final l10n = AppLocalizations.of(context);
    final serverName =
        ref.read(connectionControllerProvider).profile?.name ??
        l10n.systemServerFallback;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.sysAlertServiceDeleteTitle(service.name),
      server: serverName,
      target: service.name,
      actionLabel: l10n.sysAlertServiceDeleteAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.notifications_off_outlined,
          text: l10n.sysAlertServiceDeleteConsequence,
        ),
      ],
    );
    if (!confirmed || !mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .deleteAlertService(service.id);
    if (!mounted) return;
    _report(receipt != null, l10n.sysAlertServiceDeleted);
    if (receipt != null) await _load();
  }

  void _report(bool succeeded, String success) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          succeeded
              ? success
              : ref.read(serverActionControllerProvider).errorMessage ??
                    l10n.sysGenericOperationFailed,
        ),
        showCloseIcon: !succeeded,
      ),
    );
  }
}

enum _AlertAction { edit, delete }
