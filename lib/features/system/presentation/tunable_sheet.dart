import 'package:flutter/material.dart';
import '../../../core/widgets/truedock_dropdown.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/tunable_configuration.dart';

class TunableSheet extends StatefulWidget {
  const TunableSheet({required this.baseline, this.editing = false, super.key});

  final TunableConfiguration baseline;
  final bool editing;

  @override
  State<TunableSheet> createState() => _TunableSheetState();
}

class _TunableSheetState extends State<TunableSheet> {
  late final TextEditingController _variable;
  late final TextEditingController _value;
  late final TextEditingController _comment;
  late TunableConfiguration _configuration;
  List<TunableValidationIssue> _issues = const [];

  @override
  void initState() {
    super.initState();
    _configuration = widget.baseline;
    _variable = TextEditingController(text: widget.baseline.variable);
    _value = TextEditingController(text: widget.baseline.value);
    _comment = TextEditingController(text: widget.baseline.comment);
  }

  @override
  void dispose() {
    _variable.dispose();
    _value.dispose();
    _comment.dispose();
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
              Text(
                widget.editing
                    ? l10n.sysTunableEditTitle
                    : l10n.sysTunableCreateTitle,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 18),
              TrueDockDropdownMenu<TunableType>(
                enabled: !widget.editing,
                expandedInsets: EdgeInsets.zero,
                initialSelection: _configuration.type,
                label: Text(l10n.sysTunableType),
                dropdownMenuEntries: [
                  for (final type in TunableType.values)
                    DropdownMenuEntry(
                      value: type,
                      label: _typeLabel(l10n, type),
                    ),
                ],
                onSelected: (type) {
                  if (type != null) {
                    setState(
                      () =>
                          _configuration = _configuration.copyWith(type: type),
                    );
                  }
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _variable,
                enabled: !widget.editing,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.sysTunableVariable,
                  helperText: _variableHelper(l10n, _configuration.type),
                  helperMaxLines: 10,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _value,
                autocorrect: false,
                minLines: _configuration.type == TunableType.udev ? 3 : 1,
                maxLines: _configuration.type == TunableType.udev ? 8 : 3,
                decoration: InputDecoration(labelText: l10n.sysTunableValue),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _comment,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(labelText: l10n.sysTunableComment),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _configuration.enabled,
                onChanged: (value) => setState(
                  () =>
                      _configuration = _configuration.copyWith(enabled: value),
                ),
                title: Text(l10n.sysTunableEnabled),
              ),
              if (_configuration.type == TunableType.zfs)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _configuration.updateInitramfs,
                  onChanged: (value) => setState(
                    () => _configuration = _configuration.copyWith(
                      updateInitramfs: value,
                    ),
                  ),
                  title: Text(l10n.sysTunableUpdateInitramfs),
                  subtitle: Text(l10n.sysTunableUpdateInitramfsSubtitle),
                ),
              for (final issue in _issues)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(switch (issue.code) {
                    TunableValidationCode.variableRequired =>
                      l10n.sysTunableValidationVariable,
                    TunableValidationCode.valueRequired =>
                      l10n.sysTunableValidationValue,
                  }, style: TextStyle(color: theme.colorScheme.error)),
                ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.actionCancel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _submit,
                      child: Text(l10n.actionReview),
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

  String _typeLabel(AppLocalizations l10n, TunableType type) => switch (type) {
    TunableType.sysctl => l10n.sysTunableTypeSysctl,
    TunableType.udev => l10n.sysTunableTypeUdev,
    TunableType.zfs => l10n.sysTunableTypeZfs,
  };

  String _variableHelper(AppLocalizations l10n, TunableType type) =>
      switch (type) {
        TunableType.sysctl => l10n.sysTunableVariableSysctlHelper,
        TunableType.udev => l10n.sysTunableVariableUdevHelper,
        TunableType.zfs => l10n.sysTunableVariableZfsHelper,
      };

  void _submit() {
    final next = _configuration.copyWith(
      variable: _variable.text,
      value: _value.text,
      comment: _comment.text,
    );
    final issues = next.validate();
    if (issues.isNotEmpty) {
      setState(() => _issues = issues);
      return;
    }
    Navigator.pop(context, next);
  }
}
