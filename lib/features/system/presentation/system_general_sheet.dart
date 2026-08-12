import 'package:flutter/material.dart';
import '../../../core/widgets/truedock_dropdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../actions/presentation/server_action_controller.dart';
import 'system_general_localizations.dart';
import '../domain/system_general_configuration.dart';

/// Editor for hostname, timezone, and syslog level across their respective
/// TrueNAS 25.10 namespaces.
///
/// Returns the next [SystemGeneralConfiguration] after a review step. The
/// caller computes the diff against the baseline and sends only the changed
/// fields. Timezone choices are loaded from `system.general.timezone_choices`.
class SystemGeneralSheet extends ConsumerStatefulWidget {
  const SystemGeneralSheet({
    required this.baseline,
    this.embedded = false,
    this.onSubmitted,
    super.key,
  });

  final SystemGeneralConfiguration baseline;
  final bool embedded;
  final ValueChanged<SystemGeneralConfiguration>? onSubmitted;

  @override
  ConsumerState<SystemGeneralSheet> createState() => _SystemGeneralSheetState();
}

class _SystemGeneralSheetState extends ConsumerState<SystemGeneralSheet> {
  late final TextEditingController _hostnameController;

  late SystemGeneralConfiguration _configuration;
  List<({String id, String label})>? _timezoneChoices;
  bool _timezonesLoading = true;
  bool _reviewing = false;
  Map<String, SystemGeneralValidationCode> _errors = const {};

  @override
  void initState() {
    super.initState();
    _configuration = widget.baseline;
    _hostnameController = TextEditingController(text: widget.baseline.hostname);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadTimezones();
    });
  }

  @override
  void dispose() {
    _hostnameController.dispose();
    super.dispose();
  }

  Future<void> _loadTimezones() async {
    final choices = await ref
        .read(serverActionControllerProvider.notifier)
        .getSystemTimezoneChoices();
    if (!mounted) return;
    setState(() {
      _timezoneChoices = choices;
      _timezonesLoading = false;
    });
  }

  void _syncConfiguration() {
    _configuration = _configuration.copyWith(
      hostname: _hostnameController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.embedded) ...[
          Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.settings_outlined,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _reviewing
                      ? l10n.sysGeneralReviewTitle
                      : l10n.sysGeneralFormTitle,
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                tooltip: l10n.actionClose,
              ),
            ],
          ),
          const SizedBox(height: 18),
        ],
        if (widget.embedded)
          (_reviewing ? _review(theme, l10n) : _form(theme, l10n))
        else
          Expanded(
            child: _reviewing ? _review(theme, l10n) : _form(theme, l10n),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (_reviewing)
              TextButton.icon(
                onPressed: () => setState(() => _reviewing = false),
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(l10n.actionBack),
              )
            else if (!widget.embedded)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.actionCancel),
              ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _reviewing ? _submit : _validate,
              icon: Icon(
                _reviewing ? Icons.save_outlined : Icons.arrow_forward_rounded,
              ),
              label: Text(
                _reviewing ? l10n.actionSaveChanges : l10n.actionReview,
              ),
            ),
          ],
        ),
      ],
    );
    if (widget.embedded) return content;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .7,
          child: content,
        ),
      ),
    );
  }

  Widget _form(ThemeData theme, AppLocalizations l10n) {
    return ListView(
      shrinkWrap: widget.embedded,
      primary: !widget.embedded,
      physics: widget.embedded ? const NeverScrollableScrollPhysics() : null,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        TextField(
          controller: _hostnameController,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.sysGeneralHostnameLabel,
            prefixIcon: const Icon(Icons.dns_outlined),
          ),
        ),
        if (_errors['hostname'] != null) ...[
          const SizedBox(height: 6),
          Text(
            l10n.systemGeneralValidationMessage(_errors['hostname']!),
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 18),
        Text(l10n.sysGeneralTimezoneTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        if (_timezonesLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_timezoneChoices == null || _timezoneChoices!.isEmpty)
          TextField(
            controller: TextEditingController(text: _configuration.timezone),
            decoration: InputDecoration(
              labelText: l10n.sysGeneralTimezoneLabel,
              prefixIcon: const Icon(Icons.schedule_outlined),
              helperText: l10n.sysGeneralTimezoneHelper,
            ),
            onChanged: (value) => setState(
              () => _configuration = _configuration.copyWith(timezone: value),
            ),
          )
        else
          TrueDockDropdownButtonFormField<String>(
            initialValue:
                _timezoneChoices!.any((tz) => tz.id == _configuration.timezone)
                ? _configuration.timezone
                : null,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.sysGeneralTimezoneLabel,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final tz in _timezoneChoices!)
                DropdownMenuItem(value: tz.id, child: Text(tz.label)),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(
                () => _configuration = _configuration.copyWith(timezone: value),
              );
            },
          ),
        if (_errors['timezone'] != null) ...[
          const SizedBox(height: 6),
          Text(
            l10n.systemGeneralValidationMessage(_errors['timezone']!),
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 18),
        Text(l10n.sysGeneralSyslogTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        TrueDockDropdownButtonFormField<SystemSyslogLevel>(
          initialValue: _configuration.syslogLevel,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.sysGeneralSyslogLabel,
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final level in SystemSyslogLevel.values)
              DropdownMenuItem(
                value: level,
                child: Text(l10n.syslogLabel(level)),
              ),
          ],
          onChanged: (level) {
            if (level == null) return;
            setState(
              () =>
                  _configuration = _configuration.copyWith(syslogLevel: level),
            );
          },
        ),
      ],
    );
  }

  Widget _review(ThemeData theme, AppLocalizations l10n) {
    _syncConfiguration();
    final diff = _configuration.changedFields(widget.baseline);
    final keys = diff.keys.toList()..sort();
    return ListView(
      shrinkWrap: widget.embedded,
      primary: !widget.embedded,
      physics: widget.embedded ? const NeverScrollableScrollPhysics() : null,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReviewRow(
                label: l10n.sysGeneralReviewHostname,
                value: _configuration.hostname,
              ),
              _ReviewRow(
                label: l10n.sysGeneralReviewTimezone,
                value: _configuration.timezone,
              ),
              _ReviewRow(
                label: l10n.sysGeneralReviewSyslog,
                value: l10n.syslogLabel(_configuration.syslogLevel),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (keys.isEmpty)
          _Notice(message: l10n.sysGeneralNoFieldsChanged)
        else ...[
          _Notice(message: l10n.sysGeneralHostnameNotice),
          const SizedBox(height: 12),
          Text(l10n.sysGeneralChangedFields, style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          for (final key in keys)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(key),
                ],
              ),
            ),
        ],
      ],
    );
  }

  void _validate() {
    _syncConfiguration();
    final errors = validateSystemGeneralConfiguration(_configuration);
    setState(() {
      _errors = errors;
      _reviewing = errors.isEmpty;
    });
  }

  void _submit() {
    _syncConfiguration();
    if (widget.onSubmitted case final callback?) {
      callback(_configuration);
    } else {
      Navigator.of(context).pop(_configuration);
    }
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
