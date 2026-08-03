import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// TrueDock's common Material 3 single-choice control.
///
/// The field stays compact in a form while choices open in a searchable,
/// 60%-height sheet. This avoids narrow popup menus, clipped administrative
/// labels, and inconsistent selection affordances across features.
class TrueDockDropdownButtonFormField<T> extends StatelessWidget {
  const TrueDockDropdownButtonFormField({
    required this.items,
    required this.onChanged,
    this.initialValue,
    this.value,
    this.decoration = const InputDecoration(),
    this.isExpanded = false,
    this.validator,
    this.onSaved,
    this.autovalidateMode,
    this.hint,
    this.disabledHint,
    this.selectedItemBuilder,
    super.key,
  });

  final T? initialValue;
  final T? value;
  final List<DropdownMenuItem<T>>? items;
  final ValueChanged<T?>? onChanged;
  final InputDecoration decoration;
  final bool isExpanded;
  final FormFieldValidator<T>? validator;
  final FormFieldSetter<T>? onSaved;
  final AutovalidateMode? autovalidateMode;
  final Widget? hint;
  final Widget? disabledHint;
  final DropdownButtonBuilder? selectedItemBuilder;

  @override
  Widget build(BuildContext context) => FormField<T>(
    initialValue: initialValue ?? value,
    validator: validator,
    onSaved: onSaved,
    autovalidateMode: autovalidateMode,
    builder: (field) {
      final selected = _findItem(items, field.value);
      final enabled =
          onChanged != null && (items?.any((item) => item.enabled) ?? false);
      return _TrueDockSelectionField<T>(
        value: field.value,
        items: items ?? const [],
        enabled: enabled,
        decoration: decoration.copyWith(
          errorText: field.errorText ?? decoration.errorText,
        ),
        hint: enabled ? hint : disabledHint ?? hint,
        selectedChild: selected?.child,
        onSelected: (choice) {
          field.didChange(choice);
          onChanged?.call(choice);
        },
      );
    },
  );
}

class TrueDockDropdownButton<T> extends StatelessWidget {
  const TrueDockDropdownButton({
    required this.items,
    required this.onChanged,
    this.value,
    this.hint,
    this.disabledHint,
    this.isExpanded = false,
    super.key,
  });

  final T? value;
  final List<DropdownMenuItem<T>>? items;
  final ValueChanged<T?>? onChanged;
  final Widget? hint;
  final Widget? disabledHint;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final selected = _findItem(items, value);
    final enabled =
        onChanged != null && (items?.any((item) => item.enabled) ?? false);
    return _CompactSelectionField<T>(
      value: value,
      items: items ?? const [],
      enabled: enabled,
      onSelected: onChanged,
      child: selected?.child ?? (enabled ? hint : disabledHint ?? hint),
    );
  }
}

class TrueDockDropdownMenu<T> extends StatefulWidget {
  const TrueDockDropdownMenu({
    required this.dropdownMenuEntries,
    this.initialSelection,
    this.onSelected,
    this.label,
    this.enabled = true,
    this.enableFilter = false,
    this.requestFocusOnTap,
    this.expandedInsets,
    this.trailingIcon,
    this.selectedTrailingIcon,
    super.key,
  });

  final T? initialSelection;
  final ValueChanged<T?>? onSelected;
  final Widget? label;
  final bool enabled;
  final bool enableFilter;
  final bool? requestFocusOnTap;
  final EdgeInsetsGeometry? expandedInsets;
  final Widget? trailingIcon;
  final Widget? selectedTrailingIcon;
  final List<DropdownMenuEntry<T>> dropdownMenuEntries;

  @override
  State<TrueDockDropdownMenu<T>> createState() =>
      _TrueDockDropdownMenuState<T>();
}

class _TrueDockDropdownMenuState<T> extends State<TrueDockDropdownMenu<T>> {
  late T? _value = widget.initialSelection;

  @override
  void didUpdateWidget(covariant TrueDockDropdownMenu<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSelection != widget.initialSelection) {
      _value = widget.initialSelection;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final entry in widget.dropdownMenuEntries)
        DropdownMenuItem<T>(
          value: entry.value,
          enabled: entry.enabled,
          child: entry.labelWidget ?? Text(entry.label),
        ),
    ];
    final selected = _findItem(items, _value);
    return _TrueDockSelectionField<T>(
      value: _value,
      items: items,
      enabled: widget.enabled && widget.onSelected != null,
      decoration: InputDecoration(
        label: widget.label,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      selectedChild: selected?.child,
      onSelected: (value) {
        setState(() => _value = value);
        widget.onSelected?.call(value);
      },
    );
  }
}

class _TrueDockSelectionField<T> extends StatelessWidget {
  const _TrueDockSelectionField({
    required this.value,
    required this.items,
    required this.enabled,
    required this.decoration,
    required this.onSelected,
    this.hint,
    this.selectedChild,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final bool enabled;
  final InputDecoration decoration;
  final ValueChanged<T?> onSelected;
  final Widget? hint;
  final Widget? selectedChild;

  @override
  Widget build(BuildContext context) {
    final effectiveDecoration = decoration.copyWith(
      enabled: enabled,
      filled: decoration.filled ?? true,
      fillColor:
          decoration.fillColor ??
          Theme.of(context).colorScheme.surfaceContainerHigh,
      suffixIcon:
          decoration.suffixIcon ??
          const Icon(Icons.keyboard_arrow_down_rounded),
      border:
          decoration.border ??
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: enabled ? () => _openChoiceSheet(context) : null,
        child: InputDecorator(
          isEmpty: selectedChild == null,
          decoration: effectiveDecoration,
          child: ClipRect(
            child: DefaultTextStyle.merge(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              child:
                  selectedChild ??
                  hint ??
                  Text(AppLocalizations.of(context).dropdownSelect),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openChoiceSheet(BuildContext context) async {
    final selected = await _showTrueDockChoiceSheet<T>(
      context,
      title:
          decoration.label ??
          Text(
            decoration.labelText ?? AppLocalizations.of(context).dropdownSelect,
          ),
      description: decoration.helperText,
      items: items,
      value: value,
    );
    if (selected.didSelect) onSelected(selected.value);
  }
}

class _CompactSelectionField<T> extends StatelessWidget {
  const _CompactSelectionField({
    required this.value,
    required this.items,
    required this.enabled,
    required this.onSelected,
    this.child,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final bool enabled;
  final ValueChanged<T?>? onSelected;
  final Widget? child;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: enabled
        ? () async {
            final result = await _showTrueDockChoiceSheet<T>(
              context,
              title: Text(AppLocalizations.of(context).dropdownSelect),
              items: items,
              value: value,
            );
            if (result.didSelect) onSelected?.call(result.value);
          }
        : null,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: child ?? Text(AppLocalizations.of(context).dropdownSelect),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
        ],
      ),
    ),
  );
}

DropdownMenuItem<T>? _findItem<T>(List<DropdownMenuItem<T>>? items, T? value) {
  if (items == null) return null;
  for (final item in items) {
    if (item.value == value) return item;
  }
  return null;
}

class _ChoiceResult<T> {
  const _ChoiceResult(this.value, {required this.didSelect});
  final T? value;
  final bool didSelect;
}

Future<_ChoiceResult<T>> _showTrueDockChoiceSheet<T>(
  BuildContext context, {
  required Widget title,
  required List<DropdownMenuItem<T>> items,
  required T? value,
  String? description,
}) async {
  final selected = await showModalBottomSheet<DropdownMenuItem<T>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _TrueDockChoiceSheet<T>(
      title: title,
      description: description,
      items: items,
      value: value,
    ),
  );
  return _ChoiceResult(selected?.value, didSelect: selected != null);
}

class _TrueDockChoiceSheet<T> extends StatefulWidget {
  const _TrueDockChoiceSheet({
    required this.title,
    required this.items,
    required this.value,
    this.description,
  });

  final Widget title;
  final String? description;
  final List<DropdownMenuItem<T>> items;
  final T? value;

  @override
  State<_TrueDockChoiceSheet<T>> createState() =>
      _TrueDockChoiceSheetState<T>();
}

class _TrueDockChoiceSheetState<T> extends State<_TrueDockChoiceSheet<T>> {
  final _search = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final searchable = widget.items.length >= 7;
    final filtered = searchable && _query.trim().isNotEmpty
        ? widget.items
              .where(
                (item) => _plainText(
                  item.child,
                ).toLowerCase().contains(_query.trim().toLowerCase()),
              )
              .toList()
        : widget.items;
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
                      DefaultTextStyle(
                        style: theme.textTheme.titleLarge!,
                        child: widget.title,
                      ),
                      Text(
                        l10n.dropdownOptionCount(filtered.length),
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
                  tooltip: l10n.actionClose,
                ),
              ],
            ),
            if (widget.description case final description?) ...[
              const SizedBox(height: 8),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            if (searchable) ...[
              const SizedBox(height: 14),
              TextField(
                key: const ValueKey('truedock-dropdown-search'),
                controller: _search,
                decoration: InputDecoration(
                  hintText: l10n.dropdownSearch,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _search.clear();
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
                  ? Center(child: Text(l10n.dropdownNoMatches))
                  : ListView.separated(
                      key: const ValueKey('truedock-dropdown-list'),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final selected = item.value == widget.value;
                        return Material(
                          color: selected
                              ? theme.colorScheme.secondaryContainer
                              : theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(18),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            enabled: item.enabled,
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
                            title: DefaultTextStyle.merge(
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              child: item.child,
                            ),
                            trailing: selected
                                ? Icon(
                                    Icons.done_rounded,
                                    color: theme.colorScheme.primary,
                                  )
                                : null,
                            onTap: item.enabled
                                ? () => Navigator.pop(context, item)
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

String _plainText(Widget widget) {
  if (widget is Text) {
    return widget.data ?? widget.textSpan?.toPlainText() ?? '';
  }
  return widget.toStringShort();
}
