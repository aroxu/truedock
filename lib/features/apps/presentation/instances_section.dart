import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/destructive_confirmation.dart';
import '../../../l10n/app_localizations.dart';
import '../../actions/data/server_actions_repository.dart';
import '../../actions/presentation/server_action_controller.dart';
import '../../connection/presentation/connection_controller.dart';
import '../../resources/domain/server_resources.dart';
import '../../system/domain/virt_instance_configuration.dart';
import 'instance_sheets.dart';
import 'apps_localizations.dart';

/// The Instances list on the Apps screen, backed by 25.10's `virt.*` surface.
///
/// The platform is unusable until a storage pool is chosen, and in that state
/// the server returns an empty instance list — indistinguishable from "no
/// instances yet" unless `virt.global.config` is read. So this widget reads the
/// config first and explains the difference instead of showing a misleading
/// empty state.
class InstancesSection extends ConsumerStatefulWidget {
  const InstancesSection({required this.instances, super.key});

  final List<VirtInstance> instances;

  @override
  ConsumerState<InstancesSection> createState() => _InstancesSectionState();
}

class _InstancesSectionState extends ConsumerState<InstancesSection> {
  VirtGlobalConfig? _config;
  var _loadingConfig = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadConfig();
    });
  }

  Future<void> _loadConfig() async {
    final config = await ref
        .read(serverActionControllerProvider.notifier)
        .loadVirtGlobalConfig();
    if (!mounted) return;
    setState(() {
      _config = config;
      _loadingConfig = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final config = _config;

    if (_loadingConfig) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // A failed config read leaves `config` null. Fall through to the list
    // rather than blocking it: the instances themselves loaded fine.
    if (config != null && config.needsPool) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.appsInstancesNoPool),
              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                onPressed: _choosePool,
                icon: const Icon(Icons.dns_outlined),
                label: Text(l10n.appsInstancesChoosePool),
              ),
            ],
          ),
        ),
      );
    }

    final capabilities = ref.watch(connectionControllerProvider).capabilities;
    final canCreate = capabilities?.supports('virt.instance.create') == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.instances.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(l10n.appsNoInstances),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (final (index, instance) in widget.instances.indexed) ...[
                  _InstanceTile(instance: instance),
                  if (index < widget.instances.length - 1)
                    const Divider(indent: 68, height: 1),
                ],
              ],
            ),
          ),
        if (canCreate) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _create(config),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.appsInstanceCreate),
          ),
        ],
      ],
    );
  }

  /// Initializes the platform against a pool. Server-wide, and undoing it means
  /// recreating every instance, so it takes a confirmation naming the pool.
  Future<void> _choosePool() async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(serverActionControllerProvider.notifier);
    final choices = await controller.loadVirtPoolChoices();
    if (!mounted || choices == null) return;

    // The server offers a synthetic "[DISABLED]" entry to turn the platform
    // off; that is not a pool and must not appear as one.
    final pools = choices.keys
        .where((key) => !key.startsWith('['))
        .toList(growable: false);
    if (pools.isEmpty) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(
              l10n.appsInstancesPoolTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final pool in pools)
            ListTile(
              leading: const Icon(Icons.dns_outlined),
              title: Text(choices[pool] ?? pool),
              onTap: () => Navigator.pop(context, pool),
            ),
        ],
      ),
    );
    if (selected == null || !mounted) return;

    final serverName =
        ref.read(connectionControllerProvider).profile?.name ??
        l10n.systemServerFallback;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.appsInstancesPoolTitle,
      server: serverName,
      target: selected,
      actionLabel: l10n.appsInstancesChoosePool,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.dataset_outlined,
          text: l10n.appsInstancesPoolConsequence(selected),
        ),
      ],
    );
    if (!confirmed || !mounted) return;

    final receipt = await controller.updateVirtStoragePool(selected);
    if (!mounted) return;
    final error = ref.read(serverActionControllerProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          receipt == null
              ? error ?? l10n.appsOperationFailed
              : l10n.appsInstancesPoolApplied(selected),
        ),
        showCloseIcon: receipt == null,
      ),
    );
    if (receipt != null) await _loadConfig();
  }

  Future<void> _create(VirtGlobalConfig? config) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(serverActionControllerProvider.notifier);
    final images = await controller.loadVirtImageChoices();
    if (!mounted) return;
    if (images == null || images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(serverActionControllerProvider).errorMessage ??
                l10n.appsOperationFailed,
          ),
          showCloseIcon: true,
        ),
      );
      return;
    }

    final request = await showModalBottomSheet<VirtInstanceCreateConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => CreateInstanceSheet(
        images: images.where((image) => image.supportsContainer).toList(),
        storagePool: config?.pool,
      ),
    );
    if (request == null || !mounted) return;

    final receipt = await controller.createVirtInstance(request);
    if (!mounted) return;
    final error = ref.read(serverActionControllerProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          receipt == null
              ? error ?? l10n.appsOperationFailed
              : l10n.appsInstanceCreated(request.name),
        ),
        showCloseIcon: receipt == null,
      ),
    );
  }
}

class _InstanceTile extends StatelessWidget {
  const _InstanceTile({required this.instance});

  final VirtInstance instance;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final kind = instance.isVirtualMachine
        ? l10n.appsInstanceKindVm
        : l10n.appsInstanceKindContainer;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      leading: CircleAvatar(
        child: Icon(
          instance.isVirtualMachine
              ? Icons.dvr_rounded
              : instance.isRunning
              ? Icons.widgets_rounded
              : Icons.inventory_2_outlined,
        ),
      ),
      title: Text(instance.name),
      subtitle: Text(
        '${l10n.appRuntimeState(instance.status)} · $kind'
        '${instance.imageDescription == null ? '' : ' · ${instance.imageDescription}'}',
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (context) => InstanceDetailsSheet(instance: instance),
      ),
    );
  }
}

/// Verbs the server actually advertises for an instance in its current state.
Set<InstanceVerb> instanceVerbsFor(
  VirtInstance instance, {
  required bool Function(String method) supports,
}) {
  return {
    if (supports('virt.instance.start')) InstanceVerb.start,
    if (supports('virt.instance.stop')) ...[
      InstanceVerb.stop,
      InstanceVerb.powerOff,
    ],
    if (supports('virt.instance.restart')) InstanceVerb.restart,
  };
}
