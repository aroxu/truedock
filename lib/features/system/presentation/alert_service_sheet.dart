import 'package:flutter/material.dart';
import '../../../core/widgets/truedock_dropdown.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/alert_service_configuration.dart';

extension AlertServiceLocalizations on AppLocalizations {
  /// Product names stay unchanged; generic protocol names use locale text.
  String alertKindLabel(AlertServiceKind kind) => switch (kind) {
    AlertServiceKind.mail => sysAlertKindEmail,
    AlertServiceKind.slack => 'Slack',
    AlertServiceKind.telegram => 'Telegram',
    AlertServiceKind.pagerDuty => 'PagerDuty',
    AlertServiceKind.mattermost => 'Mattermost',
    AlertServiceKind.opsGenie => 'OpsGenie',
    AlertServiceKind.victorOps => 'VictorOps',
    AlertServiceKind.awsSns => 'AWS SNS',
    AlertServiceKind.influxDb => 'InfluxDB',
    AlertServiceKind.snmpTrap => sysAlertKindSnmpTrap,
  };

  String alertLevelLabel(AlertLevel level) => switch (level) {
    AlertLevel.info => sysAlertLevelInfo,
    AlertLevel.notice => sysAlertLevelNotice,
    AlertLevel.warning => sysAlertLevelWarning,
    AlertLevel.error => sysAlertLevelError,
    AlertLevel.critical => sysAlertLevelCritical,
    AlertLevel.alert => sysAlertLevelAlert,
    AlertLevel.emergency => sysAlertLevelEmergency,
  };

  /// Human label for an alert attribute key.
  ///
  /// Falls back to the raw key rather than throwing, so an attribute added to
  /// [alertServiceFields] without a string still renders.
  String alertFieldLabel(String key) => switch (key) {
    'email' => sysAlertFieldEmail,
    'url' => sysAlertFieldUrl,
    'bot_token' => sysAlertFieldBotToken,
    'chat_ids' => sysAlertFieldChatIds,
    'service_key' => sysAlertFieldServiceKey,
    'client_name' => sysAlertFieldClientName,
    'username' => sysAlertFieldUsername,
    'channel' => sysAlertFieldChannel,
    'icon_url' => sysAlertFieldIconUrl,
    'api_key' => sysAlertFieldApiKey,
    'api_url' => sysAlertFieldApiUrl,
    'routing_key' => sysAlertFieldRoutingKey,
    'region' => sysAlertFieldRegion,
    'topic_arn' => sysAlertFieldTopicArn,
    'aws_access_key_id' => sysAlertFieldAwsAccessKeyId,
    'aws_secret_access_key' => sysAlertFieldAwsSecretAccessKey,
    'host' => sysAlertFieldHost,
    'password' => sysAlertFieldPassword,
    'database' => sysAlertFieldDatabase,
    'series_name' => sysAlertFieldSeriesName,
    'port' => sysAlertFieldPort,
    'community' => sysAlertFieldCommunity,
    'v3_username' => sysAlertFieldV3Username,
    'v3_authkey' => sysAlertFieldV3Authkey,
    'v3_authprotocol' => sysAlertFieldV3Authprotocol,
    'v3_privkey' => sysAlertFieldV3Privkey,
    _ => key,
  };

  String alertValidationMessage(AlertServiceValidationIssue issue) {
    final field = alertFieldLabel(issue.field ?? '');
    return switch (issue.code) {
      AlertServiceValidationCode.nameRequired => sysAlertServiceValidationName,
      AlertServiceValidationCode.attributeRequired =>
        sysAlertServiceValidationRequired(field),
      AlertServiceValidationCode.attributeInvalidInteger =>
        sysAlertServiceValidationInteger(field),
      AlertServiceValidationCode.attributeInvalidUrl =>
        sysAlertServiceValidationUrl(field),
    };
  }
}

/// Result of the sheet: the configuration, and whether the user asked to test
/// it rather than save it.
@immutable
class AlertServiceSheetResult {
  const AlertServiceSheetResult({
    required this.configuration,
    this.test = false,
  });

  final AlertServiceConfiguration configuration;
  final bool test;
}

/// Creates or edits an alert destination.
///
/// The attribute form is generated from [alertServiceFields] because the API
/// discriminates `attributes` on a type string and validates against one exact
/// variant: a hand-built form per destination would eventually send a key from
/// the wrong variant, which fails the whole call.
class AlertServiceSheet extends StatefulWidget {
  const AlertServiceSheet({this.existing, super.key});

  /// Null when creating.
  final AlertServiceEntry? existing;

  @override
  State<AlertServiceSheet> createState() => _AlertServiceSheetState();
}

class _AlertServiceSheetState extends State<AlertServiceSheet> {
  late final TextEditingController _name;
  final _attributes = <String, TextEditingController>{};
  final _choices = <String, String>{};
  late AlertServiceKind _kind;
  late AlertLevel _level;
  late bool _enabled;
  List<AlertServiceValidationIssue> _issues = const [];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _kind = existing?.kind ?? AlertServiceKind.mail;
    _level = existing?.level ?? AlertLevel.warning;
    _enabled = existing?.enabled ?? true;
    _seedControllers();
  }

  /// Builds controllers for the current destination's attributes, seeding them
  /// from the existing entry when the type still matches.
  void _seedControllers() {
    final existing = widget.existing;
    final sameKind = existing?.kind == _kind;
    for (final field in alertServiceFields[_kind] ?? const []) {
      // A credential is never prefilled: the server returns it, but showing it
      // would put it on screen and risk resending a placeholder.
      final seed = sameKind && !field.secret
          ? existing!.attribute(field.key)
          : '';
      if (field.choices.isNotEmpty) {
        _choices[field.key] = seed;
      } else {
        _attributes[field.key] = TextEditingController(text: seed);
      }
    }
  }

  void _changeKind(AlertServiceKind kind) {
    setState(() {
      _kind = kind;
      // Attributes belong to one variant only, so switching type discards the
      // previous set rather than carrying keys the new variant rejects.
      for (final controller in _attributes.values) {
        controller.dispose();
      }
      _attributes.clear();
      _choices.clear();
      _issues = const [];
      _seedControllers();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    for (final controller in _attributes.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fields = alertServiceFields[_kind] ?? const <AlertServiceField>[];
    final hasSecret = fields.any((field) => field.secret);
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
                widget.existing == null
                    ? l10n.sysAlertServiceCreateTitle
                    : l10n.sysAlertServiceEditTitle(widget.existing!.name),
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: l10n.sysAlertServiceName,
                ),
              ),
              const SizedBox(height: 14),
              TrueDockDropdownMenu<AlertServiceKind>(
                expandedInsets: EdgeInsets.zero,
                initialSelection: _kind,
                label: Text(l10n.sysAlertServiceKind),
                dropdownMenuEntries: [
                  for (final kind in AlertServiceKind.values)
                    DropdownMenuEntry(
                      value: kind,
                      label: l10n.alertKindLabel(kind),
                    ),
                ],
                onSelected: (value) {
                  if (value != null) _changeKind(value);
                },
              ),
              const SizedBox(height: 14),
              TrueDockDropdownMenu<AlertLevel>(
                expandedInsets: EdgeInsets.zero,
                initialSelection: _level,
                label: Text(l10n.sysAlertServiceLevel),
                dropdownMenuEntries: [
                  for (final level in AlertLevel.values)
                    DropdownMenuEntry(
                      value: level,
                      label: l10n.alertLevelLabel(level),
                    ),
                ],
                onSelected: (value) {
                  if (value != null) setState(() => _level = value);
                },
              ),
              if (hasSecret) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.sysAlertServiceSecretNotice,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 14),
              for (final field in fields) _buildField(context, l10n, field),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _enabled,
                onChanged: (value) => setState(() => _enabled = value),
                title: Text(l10n.sysAlertServiceEnabled),
              ),
              for (final issue in _issues)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.alertValidationMessage(issue),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              const SizedBox(height: 14),
              // Testing before saving is the point: a wrong webhook or token
              // only fails at delivery time, so proving it while the values are
              // still on screen is the only cheap moment to find out.
              OutlinedButton.icon(
                onPressed: () => _submit(test: true),
                icon: const Icon(Icons.send_outlined),
                label: Text(
                  l10n.sysAlertServiceTest,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 14),
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
                      onPressed: () => _submit(),
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

  Widget _buildField(
    BuildContext context,
    AppLocalizations l10n,
    AlertServiceField field,
  ) {
    final label = l10n.alertFieldLabel(field.key);
    if (field.choices.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TrueDockDropdownMenu<String>(
          expandedInsets: EdgeInsets.zero,
          initialSelection: _choices[field.key] ?? '',
          label: Text(label),
          dropdownMenuEntries: [
            for (final choice in field.choices)
              DropdownMenuEntry(
                value: choice,
                label: choice.isEmpty ? l10n.sysServiceChoiceNone : choice,
              ),
          ],
          onSelected: (value) {
            if (value != null) setState(() => _choices[field.key] = value);
          },
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: _attributes[field.key],
        autocorrect: false,
        obscureText: field.secret,
        enableSuggestions: !field.secret,
        keyboardType: field.integer || field.integerList
            ? TextInputType.number
            : TextInputType.text,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  void _submit({bool test = false}) {
    final attributes = <String, String>{
      for (final entry in _attributes.entries) entry.key: entry.value.text,
      for (final entry in _choices.entries) entry.key: entry.value,
    };
    final configuration = AlertServiceConfiguration(
      name: _name.text,
      kind: _kind,
      level: _level,
      attributes: attributes,
      enabled: _enabled,
    );
    final issues = configuration.validate();
    if (issues.isNotEmpty) {
      setState(() => _issues = issues);
      return;
    }
    Navigator.pop(
      context,
      AlertServiceSheetResult(configuration: configuration, test: test),
    );
  }
}
