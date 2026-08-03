import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/connection/presentation/connection_controller.dart';

class ResourceLandingScreen extends ConsumerWidget {
  const ResourceLandingScreen({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.features,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<({IconData icon, String title, String subtitle})> features;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final connection = ref.watch(connectionControllerProvider);
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(title: Text(title)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          sliver: SliverList.list(
            children: [
              _Header(icon: icon, description: description),
              const SizedBox(height: 24),
              if (!connection.isConnected) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.coreLandingConnectToLoad(title),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(l10n.coreLandingNoFakeData),
                        const SizedBox(height: 16),
                        FilledButton.tonalIcon(
                          onPressed: () => context.push('/servers/new'),
                          icon: const Icon(Icons.add_link_rounded),
                          label: Text(l10n.coreLandingConnectServer),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                l10n.coreLandingManage,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    for (var index = 0; index < features.length; index++) ...[
                      ListTile(
                        enabled: connection.isConnected,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 7,
                        ),
                        leading: Icon(features[index].icon),
                        title: Text(features[index].title),
                        subtitle: Text(features[index].subtitle),
                        trailing: const Icon(Icons.chevron_right_rounded),
                      ),
                      if (index != features.length - 1)
                        const Divider(indent: 68, height: 1),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.icon, required this.description});
  final IconData icon;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: colors.onSecondaryContainer),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
