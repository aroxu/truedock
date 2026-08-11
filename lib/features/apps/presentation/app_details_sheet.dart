import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../resources/domain/server_resources.dart';
import '../../../l10n/app_localizations.dart';
import 'apps_localizations.dart';
import 'app_stats_provider.dart';

class AppDetailsSheet extends ConsumerWidget {
  const AppDetailsSheet({required this.app, required this.canEdit, super.key});

  final InstalledApp app;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final stats = ref.watch(appStatsProvider(app.id));
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .88,
      minChildSize: .55,
      maxChildSize: .96,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Row(
            children: [
              CircleAvatar(
                child: Icon(
                  app.state == 'RUNNING'
                      ? Icons.play_arrow_rounded
                      : Icons.stop_rounded,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.name, style: theme.textTheme.headlineSmall),
                    Text(
                      '${l10n.appRuntimeState(app.state)} · ${l10n.appVersionLabel(app.version)}',
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: canEdit ? () => Navigator.pop(context, true) : null,
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.appsEdit),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            l10n.appsDetailsLiveResources,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          stats.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => _Notice(
              icon: Icons.info_outline_rounded,
              text: l10n.appsDetailsStatsFailed(l10n.appsOperationFailed),
            ),
            data: (value) => Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        icon: Icons.speed_rounded,
                        label: l10n.appsDetailsCpu,
                        value: '${value.cpuUsage.toStringAsFixed(1)}%',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Metric(
                        icon: Icons.memory_rounded,
                        label: l10n.appsDetailsMemory,
                        value: formatBytes(value.memoryBytes),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        icon: Icons.download_rounded,
                        label: l10n.appsDetailsDiskRead,
                        value: formatBytes(value.blockReadBytes),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Metric(
                        icon: Icons.upload_rounded,
                        label: l10n.appsDetailsDiskWrite,
                        value: formatBytes(value.blockWriteBytes),
                      ),
                    ),
                  ],
                ),
                for (final network in value.networks) ...[
                  const SizedBox(height: 10),
                  _DetailTile(
                    icon: Icons.lan_outlined,
                    title: network.interfaceName,
                    subtitle: l10n.appsDetailsNetworkRate(
                      '${formatBytes(network.receivedBytesPerSecond)}/s',
                      '${formatBytes(network.sentBytesPerSecond)}/s',
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text(l10n.appsDetailsWorkloads, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          _DetailTile(
            icon: Icons.view_in_ar_outlined,
            title: l10n.appsDetailsContainerCount(app.workloads.containerCount),
            subtitle: app.workloads.containers.isEmpty
                ? l10n.appsDetailsNoContainerInfo
                : app.workloads.containers
                      .map(
                        (item) =>
                            '${item.serviceName} · ${l10n.appRuntimeState(item.state)}',
                      )
                      .join('\n'),
          ),
          if (app.workloads.images.isNotEmpty)
            _DetailTile(
              icon: Icons.layers_outlined,
              title: l10n.appsDetailsImages,
              subtitle: app.workloads.images.map(l10n.appImageLabel).join('\n'),
            ),
          if (app.workloads.ports.isNotEmpty)
            _DetailTile(
              icon: Icons.cable_outlined,
              title: l10n.appsDetailsPorts,
              subtitle: app.workloads.ports
                  .map(
                    (port) =>
                        '${port.hostIp}:${port.hostPort} → ${port.containerPort}/${port.protocol}',
                  )
                  .join('\n'),
            ),
          if (app.workloads.volumes.isNotEmpty)
            _DetailTile(
              icon: Icons.folder_copy_outlined,
              title: l10n.appsDetailsStorage,
              subtitle: app.workloads.volumes
                  .map(
                    (volume) =>
                        '${volume.source} → ${volume.destination} ${volume.mode}',
                  )
                  .join('\n'),
            ),
          if (app.workloads.networks.isNotEmpty)
            _DetailTile(
              icon: Icons.hub_outlined,
              title: l10n.appsDetailsNetworks,
              subtitle: app.workloads.networks.join('\n'),
            ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(label),
        ],
      ),
    ),
  );
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    clipBehavior: Clip.antiAlias,
    child: ListTile(leading: Icon(icon), title: Text(text)),
  );
}
