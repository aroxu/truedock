import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/app_configuration.dart';
import '../domain/app_installation.dart';
import '../domain/apps_catalog.dart';
import 'apps_localizations.dart';

class AppInstallationSheet extends StatefulWidget {
  const AppInstallationSheet({
    required this.app,
    required this.details,
    this.configuration,
    super.key,
  });

  final CatalogApp app;
  final CatalogAppInstallationDetails details;

  /// When supplied, the sheet runs in reconfiguration mode: the app instance
  /// name and catalog version are locked to the installed app, the editor is
  /// seeded with the current [AppConfiguration.values], and the result is an
  /// [AppSheetUpdate] instead of an [AppSheetInstall].
  final AppConfiguration? configuration;

  @override
  State<AppInstallationSheet> createState() => _AppInstallationSheetState();
}

class _AppInstallationSheetState extends State<AppInstallationSheet> {
  final _appNameController = TextEditingController();
  final _errors = <String, AppValidationIssue>{};
  late CatalogAppVersion _version;
  late Map<String, Object?> _values;
  bool _reviewing = false;

  @override
  void initState() {
    super.initState();
    final config = widget.configuration;
    if (config != null) {
      _version = _matchingVersion(config) ?? widget.details.preferredVersion!;
      _values = _copyMap(config.values);
      _appNameController.text = config.name;
    } else {
      _version = widget.details.preferredVersion!;
      _values = _copyMap(_version.initialValues);
      _appNameController.text = _suggestedName(widget.app.name);
    }
  }

  /// In update mode, lock onto the catalog version that matches the installed
  /// app so the editor shows questions for the version actually deployed.
  CatalogAppVersion? _matchingVersion(AppConfiguration config) {
    final target = config.version;
    if (target == null) return null;
    for (final candidate in widget.details.versions) {
      if (candidate.version == target) return candidate;
    }
    return null;
  }

  bool get _isUpdate => widget.configuration != null;

  @override
  void dispose() {
    _appNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .94,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colors.primaryContainer,
                    child: Icon(
                      _reviewing
                          ? Icons.fact_check_outlined
                          : Icons.download_outlined,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _reviewing
                              ? l10n.appsInstallReviewTitle
                              : _isUpdate
                              ? l10n.appsInstallReconfigureTitle(
                                  widget.configuration!.name,
                                )
                              : l10n.appsInstallInstallTitle(widget.app.title),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          l10n.appsInstallSubtitle(
                            widget.details.train,
                            _version.humanVersion,
                          ),
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: l10n.appsInstallClose,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(child: _reviewing ? _buildReview() : _buildForm()),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_reviewing)
                    TextButton.icon(
                      onPressed: () => setState(() => _reviewing = false),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text(l10n.appsInstallBack),
                    )
                  else
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.appsInstallCancel),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _version.canInstall
                        ? (_reviewing ? _submit : _review)
                        : null,
                    icon: Icon(
                      _reviewing
                          ? Icons.download_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(
                      _reviewing
                          ? (_isUpdate
                                ? l10n.appsInstallReconfigureAction
                                : l10n.appsInstallInstallAction)
                          : l10n.appsInstallReview,
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

  Widget _buildForm() {
    final l10n = AppLocalizations.of(context);
    final nameIssue = _errors['app_name'];
    final grouped = <String, List<AppQuestion>>{};
    for (final question in _version.questions) {
      grouped
          .putIfAbsent(question.group ?? l10n.appsInstallDefaultGroup, () => [])
          .add(question);
    }
    final groupMetadata = {
      for (final group in _version.groups) group.name: group,
    };
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (_isUpdate)
          _InfoField(
            label: l10n.appsInstallInstanceInfoLabel,
            value: _appNameController.text,
          )
        else ...[
          TextField(
            controller: _appNameController,
            autocorrect: false,
            textCapitalization: TextCapitalization.none,
            decoration: InputDecoration(
              labelText: l10n.appsInstallInstanceNameLabel,
              helperText: l10n.appsInstallInstanceNameHelper,
              errorText: nameIssue == null
                  ? null
                  : l10n.appValidationMessage(nameIssue),
              prefixIcon: const Icon(Icons.badge_outlined),
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_errors.remove('app_name') != null) setState(() {});
            },
          ),
          const SizedBox(height: 16),
          _AppOptionField<CatalogAppVersion>(
            key: const ValueKey('catalog-version-picker'),
            label: l10n.appsInstallCatalogVersionLabel,
            icon: Icons.tag_rounded,
            value: _version,
            options: [
              for (final version in widget.details.versions)
                _AppPickerOption(
                  value: version,
                  label: version.humanVersion,
                  subtitle: version.canInstall
                      ? null
                      : l10n.appsInstallVersionUnavailableSuffix,
                  enabled: version.canInstall,
                ),
            ],
            onChanged: (version) {
              setState(() {
                _version = version;
                _values = _copyMap(version.initialValues);
                _errors.clear();
              });
            },
          ),
          if (!_version.canInstall) ...[
            const SizedBox(height: 12),
            _Notice(
              message:
                  _version.healthError ?? l10n.appsInstallVersionUnsupported,
              error: true,
            ),
          ],
        ],
        const SizedBox(height: 20),
        for (final entry in grouped.entries) ...[
          _AppConfigurationSection(
            key: ValueKey('app-group-${entry.key}'),
            identifier: entry.key,
            title: l10n.appCatalogText(entry.key),
            description: switch (groupMetadata[entry.key]?.description) {
              final description? => l10n.appCatalogText(description),
              _ => null,
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final question in entry.value)
                  if (question.isVisible(_values) && !question.hidden) ...[
                    _QuestionField(
                      question: question,
                      values: _values,
                      path: question.variable,
                      errors: _errors,
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                  ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_version.questions.isEmpty)
          _Notice(message: l10n.appsInstallNoQuestions),
      ],
    );
  }

  Widget _buildReview() {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              _ReviewRow(
                label: l10n.appsInstallReviewServerAction,
                value: _isUpdate
                    ? l10n.appsInstallReviewActionReconfigure
                    : l10n.appsInstallReviewActionInstall,
              ),
              if (_isUpdate)
                _ReviewRow(
                  label: l10n.appsInstallReviewApp,
                  value: widget.configuration!.name,
                )
              else
                _ReviewRow(
                  label: l10n.appsInstallReviewApp,
                  value: widget.app.title,
                ),
              _ReviewRow(
                label: l10n.appsInstallReviewInstance,
                value: _appNameController.text,
              ),
              _ReviewRow(
                label: l10n.appsInstallReviewTrain,
                value: widget.details.train,
              ),
              _ReviewRow(
                label: l10n.appsInstallReviewVersion,
                value: _version.humanVersion,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Notice(
          message: _isUpdate
              ? l10n.appsInstallReviewNoticeUpdate
              : l10n.appsInstallReviewNoticeInstall,
        ),
        const SizedBox(height: 12),
        _Notice(
          message: l10n.appsInstallSecretsNotice,
          icon: Icons.shield_outlined,
        ),
      ],
    );
  }

  void _review() {
    final errors = <String, AppValidationIssue>{};
    final name = _appNameController.text.trim();
    if (!RegExp(r'^[a-z]([-a-z0-9]*[a-z0-9])?$').hasMatch(name) ||
        name.length > 40) {
      errors['app_name'] = const AppValidationIssue(
        AppValidationCode.nameFormat,
      );
    }
    _validateQuestions(_version.questions, _values, '', errors);
    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
      _reviewing = errors.isEmpty;
    });
  }

  void _submit() {
    final values = _version.installationValues(_values);
    if (_isUpdate) {
      Navigator.pop(context, AppSheetUpdate(AppUpdateRequest(values: values)));
      return;
    }
    Navigator.pop(
      context,
      AppSheetInstall(
        AppInstallRequest(
          appName: _appNameController.text.trim(),
          catalogApp: widget.details.name,
          train: widget.details.train,
          version: _version.version,
          values: values,
        ),
      ),
    );
  }
}

class _QuestionField extends StatelessWidget {
  const _QuestionField({
    required this.question,
    required this.values,
    required this.path,
    required this.errors,
    required this.onChanged,
  });

  final AppQuestion question;
  final Map<String, Object?> values;
  final String path;
  final Map<String, AppValidationIssue> errors;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final issue = errors[path];
    final error = issue == null ? null : l10n.appValidationMessage(issue);
    final value = values[question.variable];
    if (question.options.isNotEmpty) {
      return _AppOptionField<Object?>(
        key: ValueKey('app-option-$path'),
        label: l10n.appCatalogText(question.label),
        description: switch (question.description) {
          final description? => l10n.appCatalogText(description),
          _ => null,
        },
        error: error,
        icon: Icons.tune_rounded,
        value: question.options.any((option) => option.value == value)
            ? value
            : null,
        options: [
          for (final option in question.options)
            _AppPickerOption(
              value: option.value,
              label: l10n.appCatalogText(option.label),
            ),
        ],
        onChanged: (value) {
          values[question.variable] = value;
          errors.remove(path);
          onChanged();
        },
      );
    }
    return switch (question.type) {
      AppQuestionType.boolean => Material(
        type: MaterialType.transparency,
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          title: Text(l10n.appCatalogText(question.label)),
          subtitle: question.description == null
              ? (error == null
                    ? null
                    : Text(
                        error,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ))
              : Text(l10n.appCatalogText(question.description!)),
          value: value == true,
          onChanged: (enabled) {
            values[question.variable] = enabled;
            errors.remove(path);
            onChanged();
          },
        ),
      ),
      AppQuestionType.dictionary => _DictionaryField(
        question: question,
        values: _ensureMap(values, question),
        path: path,
        errors: errors,
        onChanged: onChanged,
      ),
      AppQuestionType.list => _ListField(
        question: question,
        values: values,
        path: path,
        errors: errors,
        onChanged: onChanged,
      ),
      AppQuestionType.unsupported => _Notice(
        message:
            '${l10n.appCatalogText(question.label)}: '
            '${l10n.appsValidationUnsupportedField}',
        error: true,
      ),
      _ => TextFormField(
        key: ValueKey(path),
        initialValue: value == null ? '' : '$value',
        obscureText: question.private,
        enableSuggestions: !question.private,
        autocorrect: !question.private,
        keyboardType: question.type == AppQuestionType.integer
            ? const TextInputType.numberWithOptions(signed: true)
            : question.type == AppQuestionType.text
            ? TextInputType.multiline
            : question.type == AppQuestionType.uri
            ? TextInputType.url
            : TextInputType.text,
        minLines: question.type == AppQuestionType.text ? 3 : 1,
        maxLines: question.private
            ? 1
            : question.type == AppQuestionType.text
            ? 8
            : 1,
        decoration: _decoration(
          context,
          question,
          error,
          suffixIcon: question.private ? Icons.visibility_off_outlined : null,
        ),
        onChanged: (text) {
          values[question.variable] = question.type == AppQuestionType.integer
              ? int.tryParse(text) ?? text
              : text;
          errors.remove(path);
          onChanged();
        },
      ),
    };
  }
}

class _DictionaryField extends StatelessWidget {
  const _DictionaryField({
    required this.question,
    required this.values,
    required this.path,
    required this.errors,
    required this.onChanged,
  });

  final AppQuestion question;
  final Map<String, Object?> values;
  final String path;
  final Map<String, AppValidationIssue> errors;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final visible = question.children
        .where((child) => child.isVisible(values) && !child.hidden)
        .toList(growable: false);
    final fields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final child in visible) ...[
          _QuestionField(
            question: child,
            values: values,
            path: '$path.${child.variable}',
            errors: errors,
            onChanged: onChanged,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
    if (question.label.isEmpty) return fields;
    return _AppConfigurationSection(
      key: ValueKey('app-category-$path'),
      identifier: question.label,
      title: AppLocalizations.of(context).appCatalogText(question.label),
      description: switch (question.description) {
        final description? => AppLocalizations.of(
          context,
        ).appCatalogText(description),
        _ => null,
      },
      tonal: true,
      child: fields,
    );
  }
}

class _ListField extends StatelessWidget {
  const _ListField({
    required this.question,
    required this.values,
    required this.path,
    required this.errors,
    required this.onChanged,
  });

  final AppQuestion question;
  final Map<String, Object?> values;
  final String path;
  final Map<String, AppValidationIssue> errors;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final issue = errors[path];
    final error = issue == null ? null : l10n.appValidationMessage(issue);
    final list = _ensureList(values, question);
    final item = question.listItem;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.appCatalogText(question.label),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (question.description != null) ...[
            const SizedBox(height: 4),
            Text(l10n.appCatalogText(question.description!)),
          ],
          if (error != null) ...[
            const SizedBox(height: 4),
            Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 10),
          if (item == null)
            _Notice(message: l10n.appsInstallListNoItemType, error: true)
          else
            for (var index = 0; index < list.length; index++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: item.type == AppQuestionType.dictionary
                        ? _DictionaryField(
                            question: item,
                            values: _listMap(list, index, item),
                            path: '$path.$index',
                            errors: errors,
                            onChanged: onChanged,
                          )
                        : _ScalarListItem(
                            question: item,
                            list: list,
                            index: index,
                            path: '$path.$index',
                            error: switch (errors['$path.$index']) {
                              final itemIssue? => l10n.appValidationMessage(
                                itemIssue,
                              ),
                              _ => null,
                            },
                            onChanged: onChanged,
                          ),
                  ),
                  IconButton(
                    onPressed: () {
                      list.removeAt(index);
                      errors.remove(path);
                      onChanged();
                    },
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    tooltip: l10n.appsInstallRemoveItem,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: item == null
                  ? null
                  : () {
                      list.add(_newListItem(item));
                      errors.remove(path);
                      onChanged();
                    },
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.appsInstallAddItem),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScalarListItem extends StatelessWidget {
  const _ScalarListItem({
    required this.question,
    required this.list,
    required this.index,
    required this.path,
    required this.onChanged,
    this.error,
  });

  final AppQuestion question;
  final List<Object?> list;
  final int index;
  final String path;
  final String? error;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (question.type == AppQuestionType.boolean) {
      return Material(
        type: MaterialType.transparency,
        child: SwitchListTile(
          title: Text(l10n.appCatalogText(question.label)),
          value: list[index] == true,
          onChanged: (value) {
            list[index] = value;
            onChanged();
          },
        ),
      );
    }
    if (question.options.isNotEmpty) {
      return _AppOptionField<Object?>(
        key: ValueKey('app-option-$path'),
        label: l10n.appCatalogText(question.label),
        description: switch (question.description) {
          final description? => l10n.appCatalogText(description),
          _ => null,
        },
        error: error,
        icon: Icons.tune_rounded,
        value: list[index],
        options: [
          for (final option in question.options)
            _AppPickerOption(
              value: option.value,
              label: l10n.appCatalogText(option.label),
            ),
        ],
        onChanged: (value) {
          list[index] = value;
          onChanged();
        },
      );
    }
    return TextFormField(
      key: ValueKey(path),
      initialValue: list[index] == null ? '' : '${list[index]}',
      obscureText: question.private,
      decoration: _decoration(context, question, error),
      keyboardType: question.type == AppQuestionType.integer
          ? TextInputType.number
          : TextInputType.text,
      onChanged: (text) {
        list[index] = question.type == AppQuestionType.integer
            ? int.tryParse(text) ?? text
            : text;
        onChanged();
      },
    );
  }
}

class _AppPickerOption<T> {
  const _AppPickerOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.enabled = true,
  });

  final T value;
  final String label;
  final String? subtitle;
  final bool enabled;
}

class _AppOptionField<T> extends StatelessWidget {
  const _AppOptionField({
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
    this.description,
    this.error,
    super.key,
  });

  final String label;
  final String? description;
  final String? error;
  final IconData icon;
  final T? value;
  final List<_AppPickerOption<T>> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = _selectedOption;
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: label,
      value: selected?.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: options.any((option) => option.enabled)
            ? () => _openPicker(context)
            : null,
        child: InputDecorator(
          isEmpty: selected == null,
          decoration: InputDecoration(
            labelText: label,
            helperText: description,
            helperMaxLines: 10,
            errorText: error,
            errorMaxLines: 20,
            prefixIcon: Icon(icon),
            suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
            filled: true,
            fillColor: colors.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
          child: Text(
            selected?.label ?? l10n.appsInstallSelect,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: selected == null
                ? TextStyle(color: colors.onSurfaceVariant)
                : Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }

  _AppPickerOption<T>? get _selectedOption {
    for (final option in options) {
      if (option.value == value) return option;
    }
    return null;
  }

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<_AppPickerOption<T>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _AppOptionPickerSheet<T>(
        title: label,
        description: description,
        options: options,
        selectedValue: value,
      ),
    );
    if (selected != null) onChanged(selected.value);
  }
}

class _AppOptionPickerSheet<T> extends StatefulWidget {
  const _AppOptionPickerSheet({
    required this.title,
    required this.options,
    required this.selectedValue,
    this.description,
  });

  final String title;
  final String? description;
  final List<_AppPickerOption<T>> options;
  final T? selectedValue;

  @override
  State<_AppOptionPickerSheet<T>> createState() =>
      _AppOptionPickerSheetState<T>();
}

class _AppOptionPickerSheetState<T> extends State<_AppOptionPickerSheet<T>> {
  final _searchController = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final normalized = _query.trim().toLowerCase();
    final filtered = widget.options
        .where(
          (option) =>
              normalized.isEmpty ||
              option.label.toLowerCase().contains(normalized) ||
              (option.subtitle?.toLowerCase().contains(normalized) ?? false),
        )
        .toList(growable: false);
    final searchable = widget.options.length >= 7;

    return FractionallySizedBox(
      heightFactor: .60,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          12 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.tune_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: theme.textTheme.titleLarge),
                      Text(
                        l10n.appsInstallOptionCount(filtered.length),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: l10n.appsInstallClose,
                ),
              ],
            ),
            if (widget.description != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (searchable) ...[
              const SizedBox(height: 14),
              TextField(
                key: const ValueKey('app-option-search'),
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.appsInstallOptionSearch,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.clear_rounded),
                        ),
                  filled: true,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text(l10n.appsInstallNoMatchingOptions))
                  : ListView.separated(
                      key: const ValueKey('app-option-list'),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final option = filtered[index];
                        final selected = option.value == widget.selectedValue;
                        return Material(
                          color: selected
                              ? theme.colorScheme.secondaryContainer
                              : theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(18),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            enabled: option.enabled,
                            minTileHeight: 58,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: Icon(
                              selected
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color: selected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            title: Text(
                              option.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: option.subtitle == null
                                ? null
                                : Text(
                                    option.subtitle!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                            trailing: selected
                                ? Icon(
                                    Icons.done_rounded,
                                    color: theme.colorScheme.primary,
                                  )
                                : null,
                            onTap: option.enabled
                                ? () => Navigator.pop(context, option)
                                : null,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: colors.onSurfaceVariant)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppConfigurationSection extends StatefulWidget {
  const _AppConfigurationSection({
    required this.title,
    required this.child,
    this.description,
    this.identifier,
    this.tonal = false,
    super.key,
  });

  final String title;
  final String? description;
  final String? identifier;
  final Widget child;
  final bool tonal;

  @override
  State<_AppConfigurationSection> createState() =>
      _AppConfigurationSectionState();
}

class _AppConfigurationSectionState extends State<_AppConfigurationSection> {
  var _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final header = Semantics(
      button: true,
      expanded: _expanded,
      child: InkWell(
        key: ValueKey(
          'app-section-toggle-${widget.identifier ?? widget.title}',
        ),
        borderRadius: BorderRadius.circular(18),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: EdgeInsets.fromLTRB(widget.tonal ? 14 : 0, 10, 10, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: widget.tonal
                          ? theme.textTheme.titleMedium
                          : theme.textTheme.titleLarge,
                    ),
                    if (widget.description case final description?)
                      Text(
                        description,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: _expanded ? .5 : 0,
                duration: context.motionDuration(AppMotion.standard),
                curve: AppMotion.standardCurve,
                child: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
            ],
          ),
        ),
      ),
    );

    return Material(
      color: widget.tonal
          ? theme.colorScheme.surfaceContainerLow
          : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          AnimatedSize(
            duration: context.motionDuration(AppMotion.standard),
            curve: AppMotion.standardCurve,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: EdgeInsets.fromLTRB(
                      widget.tonal ? 16 : 0,
                      4,
                      widget.tonal ? 16 : 0,
                      widget.tonal ? 4 : 0,
                    ),
                    child: widget.child,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
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

class _Notice extends StatelessWidget {
  const _Notice({
    required this.message,
    this.error = false,
    this.icon = Icons.info_outline_rounded,
  });

  final String message;
  final bool error;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: error ? colors.errorContainer : colors.secondaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: error
                ? colors.onErrorContainer
                : colors.onSecondaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

InputDecoration _decoration(
  BuildContext context,
  AppQuestion question,
  String? error, {
  IconData? suffixIcon,
}) {
  final l10n = AppLocalizations.of(context);
  return InputDecoration(
    labelText: l10n.appCatalogText(question.label),
    helperText: switch (question.description) {
      final description? => l10n.appCatalogText(description),
      _ => null,
    },
    helperMaxLines: 10,
    errorText: error,
    errorMaxLines: 20,
    suffixIcon: suffixIcon == null ? null : Icon(suffixIcon),
    border: const OutlineInputBorder(),
  );
}

Map<String, Object?> _ensureMap(
  Map<String, Object?> values,
  AppQuestion question,
) {
  final current = values[question.variable];
  if (current is Map<String, Object?>) return current;
  if (current is Map) {
    final converted = Map<String, Object?>.from(current);
    values[question.variable] = converted;
    return converted;
  }
  final created = <String, Object?>{
    for (final child in question.children)
      if (child.initialValue() != null) child.variable: child.initialValue(),
  };
  values[question.variable] = created;
  return created;
}

List<Object?> _ensureList(Map<String, Object?> values, AppQuestion question) {
  final current = values[question.variable];
  if (current is List<Object?>) return current;
  if (current is List) {
    final converted = current.cast<Object?>();
    values[question.variable] = converted;
    return converted;
  }
  final created = <Object?>[];
  values[question.variable] = created;
  return created;
}

Map<String, Object?> _listMap(List<Object?> list, int index, AppQuestion item) {
  final current = list[index];
  if (current is Map<String, Object?>) return current;
  if (current is Map) {
    final converted = Map<String, Object?>.from(current);
    list[index] = converted;
    return converted;
  }
  final created = <String, Object?>{
    for (final child in item.children)
      if (child.initialValue() != null) child.variable: child.initialValue(),
  };
  list[index] = created;
  return created;
}

Object? _newListItem(AppQuestion question) => switch (question.type) {
  AppQuestionType.dictionary => <String, Object?>{
    for (final child in question.children)
      if (child.initialValue() != null) child.variable: child.initialValue(),
  },
  AppQuestionType.boolean => question.defaultValue ?? false,
  AppQuestionType.integer => question.defaultValue,
  _ => question.defaultValue ?? '',
};

void _validateQuestions(
  List<AppQuestion> questions,
  Map<String, Object?> values,
  String parentPath,
  Map<String, AppValidationIssue> errors,
) {
  for (final question in questions) {
    if (!question.isVisible(values)) continue;
    final path = parentPath.isEmpty
        ? question.variable
        : '$parentPath.${question.variable}';
    final hasValue = values.containsKey(question.variable);
    final value = values[question.variable];
    if (question.type == AppQuestionType.unsupported) {
      errors[path] = const AppValidationIssue(
        AppValidationCode.unsupportedField,
      );
      continue;
    }
    if (question.required &&
        (!hasValue ||
            value == null ||
            value is String && value.trim().isEmpty)) {
      errors[path] = const AppValidationIssue(AppValidationCode.fieldRequired);
      continue;
    }
    if (!hasValue || value == null) continue;
    if (question.type == AppQuestionType.integer && value is! int) {
      errors[path] = const AppValidationIssue(AppValidationCode.wholeNumber);
      continue;
    }
    if (value is num) {
      if (question.minimum != null && value < question.minimum!) {
        errors[path] = AppValidationIssue(
          AppValidationCode.minimumValue,
          bound: question.minimum,
        );
      } else if (question.maximum != null && value > question.maximum!) {
        errors[path] = AppValidationIssue(
          AppValidationCode.maximumValue,
          bound: question.maximum,
        );
      }
    }
    if (value is String) {
      if (question.minimumLength != null &&
          value.length < question.minimumLength!) {
        errors[path] = AppValidationIssue(
          AppValidationCode.minimumLength,
          bound: question.minimumLength,
        );
      } else if (question.maximumLength != null &&
          value.length > question.maximumLength!) {
        errors[path] = AppValidationIssue(
          AppValidationCode.maximumLength,
          bound: question.maximumLength,
        );
      } else if ((question.type == AppQuestionType.path ||
              question.type == AppQuestionType.hostPath) &&
          value.isNotEmpty &&
          !value.startsWith('/')) {
        errors[path] = const AppValidationIssue(AppValidationCode.absolutePath);
      } else if (question.type == AppQuestionType.uri &&
          value.isNotEmpty &&
          Uri.tryParse(value)?.hasScheme != true) {
        errors[path] = const AppValidationIssue(AppValidationCode.uriScheme);
      } else if (question.type == AppQuestionType.ipAddress &&
          value.isNotEmpty &&
          InternetAddress.tryParse(value) == null) {
        errors[path] = const AppValidationIssue(AppValidationCode.ipAddress);
      }
    }
    if (question.options.isNotEmpty &&
        !question.options.any((option) => option.value == value)) {
      errors[path] = const AppValidationIssue(AppValidationCode.chooseOption);
    }
    if (question.type == AppQuestionType.dictionary && value is Map) {
      _validateQuestions(
        question.children,
        Map<String, Object?>.from(value),
        path,
        errors,
      );
    }
    if (question.type == AppQuestionType.list && value is List) {
      if (question.minimum != null && value.length < question.minimum!) {
        errors[path] = AppValidationIssue(
          AppValidationCode.minimumItems,
          bound: question.minimum,
        );
      } else if (question.maximum != null && value.length > question.maximum!) {
        errors[path] = AppValidationIssue(
          AppValidationCode.maximumItems,
          bound: question.maximum,
        );
      }
      final item = question.listItem;
      if (item == null) {
        errors[path] = const AppValidationIssue(AppValidationCode.listNoSchema);
      } else {
        for (final entry in value.indexed) {
          final itemPath = '$path.${entry.$1}';
          if (item.type == AppQuestionType.dictionary && entry.$2 is Map) {
            _validateQuestions(
              item.children,
              Map<String, Object?>.from(entry.$2 as Map),
              itemPath,
              errors,
            );
          } else {
            _validateScalar(item, entry.$2, itemPath, errors);
          }
        }
      }
    }
  }
}

void _validateScalar(
  AppQuestion question,
  Object? value,
  String path,
  Map<String, AppValidationIssue> errors,
) {
  if (question.required &&
      (value == null || value is String && value.trim().isEmpty)) {
    errors[path] = const AppValidationIssue(AppValidationCode.itemRequired);
  } else if (question.type == AppQuestionType.integer && value is! int) {
    errors[path] = const AppValidationIssue(AppValidationCode.itemWholeNumber);
  }
}

Map<String, Object?> _copyMap(Map<String, Object?> source) =>
    source.map((key, value) => MapEntry(key, _copyValue(value)));

Object? _copyValue(Object? value) {
  if (value is Map) {
    return value.map<String, Object?>(
      (key, value) => MapEntry('$key', _copyValue(value)),
    );
  }
  if (value is List) return value.map(_copyValue).toList();
  return value;
}

String _suggestedName(String catalogName) {
  final normalized = catalogName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9-]'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (normalized.isEmpty || !RegExp(r'^[a-z]').hasMatch(normalized)) {
    return 'app';
  }
  return normalized.length > 40 ? normalized.substring(0, 40) : normalized;
}
