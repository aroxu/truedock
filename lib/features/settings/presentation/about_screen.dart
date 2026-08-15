import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show LicenseRegistry;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/domain/app_metadata.dart';
import '../../../l10n/app_localizations.dart';

/// In-app About page: identity, version, project links, and the open source
/// components TrueDock is built on.
///
/// Everything here is static local data, so the page renders identically with
/// or without a TrueNAS connection.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _AboutHeader(),
          const SizedBox(height: 28),
          _SectionLabel(l10n.aboutSectionApp),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  key: const ValueKey('about-version'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 6,
                  ),
                  leading: const Icon(Icons.info_outline_rounded),
                  title: Text(l10n.aboutVersionLabel),
                  subtitle: Text(
                    l10n.aboutVersionValue(appVersionName, appBuildNumber),
                  ),
                ),
                const Divider(indent: 68, height: 1),
                ListTile(
                  key: const ValueKey('about-license'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 6,
                  ),
                  leading: const Icon(Icons.gavel_rounded),
                  title: Text(l10n.aboutLicenseLabel),
                  subtitle: const Text(appLicenseSpdxId),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionLabel(l10n.aboutSectionProject),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  key: const ValueKey('about-repository'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 6,
                  ),
                  leading: const Icon(Icons.code_rounded),
                  title: Text(l10n.aboutRepositoryLabel),
                  subtitle: Text(l10n.aboutRepositorySubtitle),
                  trailing: const Icon(Icons.open_in_new_rounded),
                  onTap: () => openAboutLink(context, appRepositoryUrl),
                ),
                const Divider(indent: 68, height: 1),
                ListTile(
                  key: const ValueKey('about-open-source'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 6,
                  ),
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: Text(l10n.aboutSectionOpenSource),
                  subtitle: Text(l10n.aboutOpenSourceSubtitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const OpenSourceLicensesScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bundled third-party packages and the license each is distributed under.
class OpenSourceLicensesScreen extends StatelessWidget {
  const OpenSourceLicensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutSectionOpenSource)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            l10n.aboutOpenSourceIntro,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.aboutOpenSourceCount(openSourceComponents.length),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            key: const ValueKey('about-open-source-list'),
            child: Column(
              children: [
                for (final (index, component)
                    in openSourceComponents.indexed) ...[
                  if (index > 0) const Divider(indent: 18, height: 1),
                  ListTile(
                    key: ValueKey('about-package-${component.name}'),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 4,
                    ),
                    title: Text(component.name),
                    subtitle: Text(component.license),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            _PackageLicenseScreen(component: component),
                      ),
                    ),
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

class _PackageLicenseScreen extends StatelessWidget {
  const _PackageLicenseScreen({required this.component});

  final OpenSourceComponent component;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(component.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            tooltip: l10n.aboutPackageOpenPage,
            onPressed: () => openAboutLink(context, component.url),
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _loadLicenseText(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final text = snapshot.data;
          if (text == null || text.trim().isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.aboutPackageLicenseUnavailable,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<String> _loadLicenseText() async {
    final licenses = await LicenseRegistry.licenses.toList();
    final matching = licenses.where(
      (license) => license.packages.contains(component.name),
    );
    if (matching.isEmpty) return '';
    final paragraphs = matching.expand((license) => license.paragraphs);
    return paragraphs.map((p) => p.text).join('\n\n');
  }
}

/// Opens [url] in the platform browser, reporting failures instead of
/// leaving the tap silently unhandled.
Future<void> openAboutLink(BuildContext context, String url) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  var opened = false;
  try {
    opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  } on Object {
    opened = false;
  }
  if (opened) return;
  messenger.showSnackBar(SnackBar(content: Text(l10n.aboutLinkFailed)));
}

/// Logo, product name, tagline, and attribution shown at the top of the page.
class _AboutHeader extends StatelessWidget {
  const _AboutHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          // The logo artwork is solid white, so it needs a filled surface to
          // stay visible in light themes.
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            padding: const EdgeInsets.all(14),
            child: SvgPicture.asset(
              'assets/foreground.svg',
              key: const ValueKey('about-logo'),
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.appTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.aboutTagline,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.aboutMadeWith,
          key: const ValueKey('about-made-with'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) =>
      Text(label, style: Theme.of(context).textTheme.titleMedium);
}
