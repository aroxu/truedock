import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/mail_configuration.dart';

/// Renders a mail validation issue.
String mailValidationMessage(
  AppLocalizations l10n,
  MailValidationIssue issue,
) => switch (issue.code) {
  MailValidationCode.fromAddressRequired => l10n.sysMailValidationFromRequired,
  MailValidationCode.fromAddressInvalid => l10n.sysMailValidationFromInvalid,
  MailValidationCode.serverRequired => l10n.sysMailValidationServer,
  MailValidationCode.portRange => l10n.sysMailValidationPort(
    issue.bound ?? 65535,
  ),
  MailValidationCode.usernameWithoutPassword => l10n.sysMailValidationPassword,
};

extension _MailLocalizations on AppLocalizations {
  String mailSecurityLabel(MailSecurity security) => switch (security) {
    MailSecurity.plain => sysMailSecurityPlain,
    MailSecurity.ssl => sysMailSecuritySsl,
    MailSecurity.tls => sysMailSecurityTls,
  };
}

/// Edits the outgoing mail settings used for alerts.
///
/// The password field starts empty and stays empty unless the user types one,
/// because `mail.config` never returns it. Prefilling a placeholder would risk
/// sending that placeholder as the real password.
class MailSheet extends StatefulWidget {
  const MailSheet({required this.baseline, super.key});

  final MailConfiguration baseline;

  @override
  State<MailSheet> createState() => _MailSheetState();
}

class _MailSheetState extends State<MailSheet> {
  late final TextEditingController _fromEmail;
  late final TextEditingController _fromName;
  late final TextEditingController _server;
  late final TextEditingController _port;
  late final TextEditingController _username;
  final _password = TextEditingController();
  late MailSecurity _security;
  late bool _authenticate;
  var _obscurePassword = true;
  List<MailValidationIssue> _issues = const [];

  @override
  void initState() {
    super.initState();
    final baseline = widget.baseline;
    _fromEmail = TextEditingController(text: baseline.fromEmail);
    _fromName = TextEditingController(text: baseline.fromName);
    _server = TextEditingController(text: baseline.outgoingServer);
    _port = TextEditingController(text: '${baseline.port}');
    _username = TextEditingController(text: baseline.username ?? '');
    _security = baseline.security;
    _authenticate = baseline.smtpAuthentication;
  }

  @override
  void dispose() {
    _fromEmail.dispose();
    _fromName.dispose();
    _server.dispose();
    _port.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
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
              Text(l10n.sysMailEditTitle, style: theme.textTheme.headlineSmall),
              if (widget.baseline.usesOauth) ...[
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
                      Expanded(child: Text(l10n.sysMailOauthNotice)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              TextField(
                controller: _fromEmail,
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: l10n.sysMailFromAddress),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _fromName,
                decoration: InputDecoration(labelText: l10n.sysMailFromName),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _server,
                autocorrect: false,
                decoration: InputDecoration(labelText: l10n.sysMailServer),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _port,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.sysMailPort),
              ),
              const SizedBox(height: 18),
              Text(l10n.sysMailSecurity, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<MailSecurity>(
                segments: [
                  for (final security in MailSecurity.values)
                    ButtonSegment(
                      value: security,
                      label: Text(l10n.mailSecurityLabel(security)),
                    ),
                ],
                selected: {_security},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    setState(() => _security = selection.first),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _authenticate,
                onChanged: (value) => setState(() => _authenticate = value),
                title: Text(l10n.sysMailAuthentication),
              ),
              if (_authenticate) ...[
                TextField(
                  controller: _username,
                  autocorrect: false,
                  decoration: InputDecoration(labelText: l10n.sysMailUsername),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _password,
                  obscureText: _obscurePassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: l10n.sysMailPassword,
                    helperText: l10n.sysMailPasswordHelper,
                    helperMaxLines: 10,
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      tooltip: _obscurePassword
                          ? l10n.authShowCredential
                          : l10n.authHideCredential,
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
              ],
              for (final issue in _issues)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    mailValidationMessage(l10n, issue),
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

  void _submit() {
    final baseline = widget.baseline;
    final port = int.tryParse(_port.text.trim());
    final username = _username.text.trim();
    final password = _password.text;
    final edit = MailConfigurationEdit(
      fromEmail: _fromEmail.text.trim() == baseline.fromEmail
          ? null
          : _fromEmail.text.trim(),
      fromName: _fromName.text.trim() == baseline.fromName
          ? null
          : _fromName.text.trim(),
      outgoingServer: _server.text.trim() == baseline.outgoingServer
          ? null
          : _server.text.trim(),
      port: port == baseline.port ? null : port,
      security: _security == baseline.security ? null : _security,
      smtpAuthentication: _authenticate == baseline.smtpAuthentication
          ? null
          : _authenticate,
      username: username == (baseline.username ?? '') ? null : username,
      // Only ever sent when the user actually typed one, so a stored password
      // is never overwritten with a blank.
      password: password.isEmpty ? null : password,
    );
    final issues = edit.validateAgainst(baseline);
    if (issues.isNotEmpty) {
      setState(() => _issues = issues);
      return;
    }
    Navigator.pop(context, edit);
  }
}
