import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/network_configuration.dart';

/// Renders a global-network validation issue.
String networkValidationMessage(
  AppLocalizations l10n,
  NetworkValidationIssue issue,
) => switch (issue.code) {
  NetworkValidationCode.hostnameRequired =>
    l10n.sysNetValidationHostnameRequired,
  NetworkValidationCode.hostnameInvalid => l10n.sysNetValidationHostnameInvalid,
  NetworkValidationCode.domainInvalid => l10n.sysNetValidationDomain,
  NetworkValidationCode.gatewayInvalid => l10n.sysNetValidationGateway,
  NetworkValidationCode.ipv6GatewayInvalid => l10n.sysNetValidationIpv6Gateway,
  NetworkValidationCode.nameserverInvalid => l10n.sysNetValidationNameserver,
  NetworkValidationCode.proxyInvalid => l10n.sysNetValidationProxy,
};

/// Edits the server's global network settings: hostname, domain, default
/// gateway, nameservers, and HTTP proxy.
///
/// Shows the configured value alongside the one actually in effect, because on
/// DHCP those differ: the configured fields are empty while the system runs on a
/// leased gateway and nameservers. Presenting only the configured side makes a
/// working server look unconfigured; presenting only the effective side makes a
/// lease look like a saved setting.
class NetworkGlobalSheet extends StatefulWidget {
  const NetworkGlobalSheet({required this.baseline, this.summary, super.key});

  final NetworkConfiguration baseline;

  /// Live interface/route/DNS view, shown read-only for context.
  final NetworkSummary? summary;

  @override
  State<NetworkGlobalSheet> createState() => _NetworkGlobalSheetState();
}

class _NetworkGlobalSheetState extends State<NetworkGlobalSheet> {
  late final TextEditingController _hostname;
  late final TextEditingController _domain;
  late final TextEditingController _gateway;
  late final TextEditingController _ipv6Gateway;
  late final TextEditingController _nameserver1;
  late final TextEditingController _nameserver2;
  late final TextEditingController _nameserver3;
  late final TextEditingController _proxy;
  List<NetworkValidationIssue> _issues = const [];

  @override
  void initState() {
    super.initState();
    final baseline = widget.baseline;
    _hostname = TextEditingController(text: baseline.hostname);
    _domain = TextEditingController(text: baseline.domain);
    _gateway = TextEditingController(text: baseline.ipv4Gateway);
    _ipv6Gateway = TextEditingController(text: baseline.ipv6Gateway);
    _nameserver1 = TextEditingController(text: baseline.nameserver1);
    _nameserver2 = TextEditingController(text: baseline.nameserver2);
    _nameserver3 = TextEditingController(text: baseline.nameserver3);
    _proxy = TextEditingController(text: baseline.httpProxy);
  }

  @override
  void dispose() {
    _hostname.dispose();
    _domain.dispose();
    _gateway.dispose();
    _ipv6Gateway.dispose();
    _nameserver1.dispose();
    _nameserver2.dispose();
    _nameserver3.dispose();
    _proxy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final baseline = widget.baseline;
    final summary = widget.summary;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.sysNetGlobalTitle,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.sysNetClearHelp,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (baseline.isDhcpDerived) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(l10n.sysNetFromDhcp)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              TextField(
                controller: _hostname,
                autocorrect: false,
                decoration: InputDecoration(labelText: l10n.sysNetHostname),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _domain,
                autocorrect: false,
                decoration: InputDecoration(labelText: l10n.sysNetDomain),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _gateway,
                autocorrect: false,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.sysNetGateway,
                  helperText: _effectiveHint(
                    l10n,
                    baseline.ipv4Gateway,
                    baseline.effective.ipv4Gateway,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _ipv6Gateway,
                autocorrect: false,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: l10n.sysNetIpv6Gateway,
                  helperText: _effectiveHint(
                    l10n,
                    baseline.ipv6Gateway,
                    baseline.effective.ipv6Gateway,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              for (final (index, controller) in [
                _nameserver1,
                _nameserver2,
                _nameserver3,
              ].indexed) ...[
                TextField(
                  controller: controller,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: l10n.sysNetNameserver(index + 1),
                    helperText: _effectiveHint(
                      l10n,
                      controller.text,
                      index < baseline.effective.nameservers.length
                          ? baseline.effective.nameservers[index]
                          : '',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              TextField(
                controller: _proxy,
                autocorrect: false,
                decoration: InputDecoration(labelText: l10n.sysNetHttpProxy),
              ),
              if (summary != null) ...[
                const SizedBox(height: 20),
                Text(l10n.sysNetInEffect, style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                if (summary.defaultRoutes.isNotEmpty)
                  _ReadOnlyRow(
                    label: l10n.sysNetDefaultRoutes,
                    value: summary.defaultRoutes.join(', '),
                  ),
                if (summary.nameservers.isNotEmpty)
                  _ReadOnlyRow(
                    label: l10n.sysNetNameserver(1),
                    value: summary.nameservers.join(', '),
                  ),
                for (final entry in summary.interfaces.entries)
                  _ReadOnlyRow(
                    label: entry.key,
                    value: entry.value.isEmpty
                        ? l10n.sysNetNotSet
                        : entry.value.join(', '),
                  ),
              ],
              for (final issue in _issues)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    networkValidationMessage(l10n, issue),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        l10n.actionCancel,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _submit,
                      child: Text(
                        l10n.actionSaveChanges,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Names the value in effect when it differs from what is configured, so an
  /// empty field does not read as "nothing is set".
  String? _effectiveHint(
    AppLocalizations l10n,
    String configured,
    String effective,
  ) {
    if (effective.isEmpty || effective == configured) return null;
    return '${l10n.sysNetInEffect}: $effective';
  }

  void _submit() {
    final edit = NetworkConfigurationEdit.diff(
      baseline: widget.baseline,
      hostname: _hostname.text.trim(),
      domain: _domain.text.trim(),
      ipv4Gateway: _gateway.text.trim(),
      ipv6Gateway: _ipv6Gateway.text.trim(),
      nameserver1: _nameserver1.text.trim(),
      nameserver2: _nameserver2.text.trim(),
      nameserver3: _nameserver3.text.trim(),
      httpProxy: _proxy.text.trim(),
    );
    final issues = edit.validate();
    if (issues.isNotEmpty) {
      setState(() => _issues = issues);
      return;
    }
    Navigator.pop(context, edit);
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
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
