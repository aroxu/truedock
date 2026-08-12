import 'package:flutter/material.dart';
import '../../../core/widgets/truedock_dropdown.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/service_configuration.dart';

extension ServiceLocalizations on AppLocalizations {
  String serviceName(ConfigurableService service) => switch (service) {
    ConfigurableService.ssh => sysServiceNameSsh,
    ConfigurableService.smb => sysServiceNameSmb,
    ConfigurableService.nfs => sysServiceNameNfs,
    ConfigurableService.ftp => sysServiceNameFtp,
    ConfigurableService.snmp => sysServiceNameSnmp,
  };

  /// Human label for an API field key.
  ///
  /// Falls back to the raw key rather than throwing: a field added to
  /// [serviceFields] without a matching string still renders, which is better
  /// than a crash in a settings sheet.
  String serviceFieldLabel(String key) => switch (key) {
    'tcpport' => sysServiceFieldTcpport,
    'passwordauth' => sysServiceFieldPasswordauth,
    'kerberosauth' => sysServiceFieldKerberosauth,
    'tcpfwd' => sysServiceFieldTcpfwd,
    'compression' => sysServiceFieldCompression,
    'netbiosname' => sysServiceFieldNetbiosname,
    'workgroup' => sysServiceFieldWorkgroup,
    'description' => sysServiceFieldDescription,
    'encryption' => sysServiceFieldEncryption,
    'localmaster' => sysServiceFieldLocalmaster,
    'enable_smb1' => sysServiceFieldEnableSmb1,
    'ntlmv1_auth' => sysServiceFieldNtlmv1Auth,
    'servers' => sysServiceFieldServers,
    'allow_nonroot' => sysServiceFieldAllowNonroot,
    'v4_domain' => sysServiceFieldV4Domain,
    'mountd_port' => sysServiceFieldMountdPort,
    'rdma' => sysServiceFieldRdma,
    'port' => sysServiceFieldTcpport,
    'clients' => sysServiceFieldClients,
    'loginattempt' => sysServiceFieldLoginattempt,
    'timeout' => sysServiceFieldTimeout,
    'tls' => sysServiceFieldTls,
    'onlyanonymous' => sysServiceFieldOnlyanonymous,
    'onlylocal' => sysServiceFieldOnlylocal,
    'defaultroot' => sysServiceFieldDefaultroot,
    'resume' => sysServiceFieldResume,
    'banner' => sysServiceFieldBanner,
    'community' => sysServiceFieldCommunity,
    'contact' => sysServiceFieldContact,
    'location' => sysServiceFieldLocation,
    'loglevel' => sysServiceFieldLoglevel,
    'traps' => sysServiceFieldTraps,
    'zilstat' => sysServiceFieldZilstat,
    'v3' => sysServiceFieldV3,
    'v3_username' => sysServiceFieldV3Username,
    'v3_authtype' => sysServiceFieldV3Authtype,
    'v3_password' => sysServiceFieldV3Password,
    'v3_privproto' => sysServiceFieldV3Privproto,
    'v3_privpassphrase' => sysServiceFieldV3Privpassphrase,
    _ => key,
  };

  String serviceValidationMessage(ServiceValidationIssue issue) {
    final field = serviceFieldLabel(issue.field);
    return switch (issue.code) {
      ServiceValidationCode.required => sysServiceValidationRequired(field),
      ServiceValidationCode.integerRange => sysServiceValidationRange(
        field,
        issue.minimum ?? 0,
        issue.maximum ?? 0,
      ),
      ServiceValidationCode.invalidText => sysServiceValidationInvalid(field),
    };
  }
}

/// Edits one service's configuration.
///
/// The form is generated from [serviceFields] rather than hand-built per
/// service, because all five surfaces are the same shape: read a flat object,
/// send back only what changed. Hand-writing five nearly identical sheets is how
/// one of them ends up sending a field the others don't.
class ServiceConfigSheet extends StatefulWidget {
  const ServiceConfigSheet({
    required this.configuration,
    required this.running,
    super.key,
  });

  final ServiceConfiguration configuration;

  /// Whether the service is currently running, which decides whether the change
  /// interrupts clients now or waits for the next start.
  final bool running;

  @override
  State<ServiceConfigSheet> createState() => _ServiceConfigSheetState();
}

class _ServiceConfigSheetState extends State<ServiceConfigSheet> {
  final _text = <String, TextEditingController>{};
  final _flags = <String, bool>{};
  final _choices = <String, String>{};
  List<ServiceValidationIssue> _issues = const [];

  @override
  void initState() {
    super.initState();
    final configuration = widget.configuration;
    for (final field in configuration.fields) {
      switch (field.kind) {
        case ServiceFieldKind.text:
        case ServiceFieldKind.integer:
          // A secret is never prefilled: the server may return it, but showing
          // it would put a shared secret on screen and risk resending a
          // placeholder as the real value.
          _text[field.key] = TextEditingController(
            text: field.secret ? '' : configuration.text(field.key),
          );
        case ServiceFieldKind.toggle:
          _flags[field.key] = configuration.flag(field.key);
        case ServiceFieldKind.choice:
          _choices[field.key] = configuration.text(field.key);
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _text.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final configuration = widget.configuration;
    final hasSecret = configuration.fields.any((field) => field.secret);
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
                l10n.sysServiceEditTitle(
                  l10n.serviceName(configuration.service),
                ),
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.sysServiceRestartNotice,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (hasSecret) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.sysServiceSecretNotice,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 18),
              for (final field in configuration.fields)
                _buildField(context, l10n, field),
              for (final issue in _issues)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.serviceValidationMessage(issue),
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
                        l10n.sysServiceApplyAction,
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

  Widget _buildField(
    BuildContext context,
    AppLocalizations l10n,
    ServiceField field,
  ) {
    final label = l10n.serviceFieldLabel(field.key);
    switch (field.kind) {
      case ServiceFieldKind.toggle:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _flags[field.key] ?? false,
          onChanged: (value) => setState(() => _flags[field.key] = value),
          title: Text(label),
        );
      case ServiceFieldKind.choice:
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: TrueDockDropdownMenu<String>(
            expandedInsets: EdgeInsets.zero,
            initialSelection: _choices[field.key],
            label: Text(label),
            dropdownMenuEntries: [
              for (final choice in field.choices)
                DropdownMenuEntry(
                  value: choice,
                  // An empty choice is the server's "unset"; naming it keeps the
                  // menu from showing a blank row.
                  label: choice.isEmpty ? l10n.sysServiceChoiceDefault : choice,
                ),
            ],
            onSelected: (value) {
              if (value != null) setState(() => _choices[field.key] = value);
            },
          ),
        );
      case ServiceFieldKind.text:
      case ServiceFieldKind.integer:
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: TextField(
            controller: _text[field.key],
            autocorrect: false,
            obscureText: field.secret,
            enableSuggestions: !field.secret,
            keyboardType: field.kind == ServiceFieldKind.integer
                ? TextInputType.number
                : TextInputType.text,
            decoration: InputDecoration(labelText: label),
          ),
        );
    }
  }

  void _submit() {
    final configuration = widget.configuration;
    final changes = <String, Object?>{};

    for (final field in configuration.fields) {
      switch (field.kind) {
        case ServiceFieldKind.toggle:
          final value = _flags[field.key] ?? false;
          if (value != configuration.flag(field.key)) {
            changes[field.key] = value;
          }
        case ServiceFieldKind.choice:
          final value = _choices[field.key] ?? '';
          if (value != configuration.text(field.key)) {
            // A nullable choice sends null rather than "" to unset it, which is
            // what the schema documents for v3_privproto.
            changes[field.key] = field.nullable && value.isEmpty ? null : value;
          }
        case ServiceFieldKind.integer:
          final raw = _text[field.key]?.text.trim() ?? '';
          final current = configuration.integer(field.key);
          if (raw.isEmpty) {
            // Only send a clear when there was something to clear.
            if (current != null) changes[field.key] = null;
            break;
          }
          final parsed = int.tryParse(raw);
          if (parsed != current) changes[field.key] = parsed ?? raw;
        case ServiceFieldKind.text:
          final raw = _text[field.key]?.text ?? '';
          if (field.secret) {
            // Empty means "keep the stored secret", so nothing is sent.
            if (raw.isNotEmpty) changes[field.key] = raw;
            break;
          }
          if (raw != configuration.text(field.key)) changes[field.key] = raw;
      }
    }

    final edit = ServiceConfigurationEdit(
      service: configuration.service,
      changes: changes,
    );
    final issues = edit.validate();
    if (issues.isNotEmpty) {
      setState(() => _issues = issues);
      return;
    }
    Navigator.pop(context, edit);
  }
}
