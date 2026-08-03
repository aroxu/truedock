import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
const _digits = '23456789';
const _characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/// Creates an easy-to-read confirmation such as `A7K2-P9M4`.
///
/// Each four-character group always contains at least one letter and one
/// number. Ambiguous characters such as I, O, 0, and 1 are excluded.
String generateDeviceDataResetCode({Random? random}) {
  final source = random ?? Random.secure();
  String group() {
    final values = <String>[
      _letters[source.nextInt(_letters.length)],
      _digits[source.nextInt(_digits.length)],
      _characters[source.nextInt(_characters.length)],
      _characters[source.nextInt(_characters.length)],
    ]..shuffle(source);
    return values.join();
  }

  return '${group()}-${group()}';
}

bool matchesDeviceDataResetCode(String input, String expected) =>
    input.trim().toUpperCase() == expected;

/// Keeps reset confirmation input in the same `XXXX-XXXX` shape as the code.
class DeviceDataResetCodeFormatter extends TextInputFormatter {
  const DeviceDataResetCodeFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final compact = newValue.text.toUpperCase().replaceAll(
      RegExp('[^A-Z0-9]'),
      '',
    );
    final limited = compact.substring(0, min(compact.length, 8));
    final formatted = limited.length <= 4
        ? limited
        : '${limited.substring(0, 4)}-${limited.substring(4)}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Eight-cell security-code input with a fixed separator between both groups.
class DeviceDataResetCodeField extends StatefulWidget {
  const DeviceDataResetCodeField({
    required this.controller,
    required this.semanticLabel,
    super.key,
    this.enabled = true,
    this.autofocus = false,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String semanticLabel;
  final bool enabled;
  final bool autofocus;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<DeviceDataResetCodeField> createState() =>
      _DeviceDataResetCodeFieldState();
}

class _DeviceDataResetCodeFieldState extends State<DeviceDataResetCodeField> {
  late final FocusNode _focusNode = FocusNode()..addListener(_refresh);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant DeviceDataResetCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _focusNode
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final compact = widget.controller.text.replaceAll('-', '');
    final activeIndex = compact.length.clamp(0, 7);
    return Semantics(
      label: widget.semanticLabel,
      value: widget.controller.text,
      textField: true,
      enabled: widget.enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? _focusNode.requestFocus : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ExcludeSemantics(
                  child: Row(
                    children: [
                      for (var index = 0; index < 4; index++) ...[
                        if (index > 0) const SizedBox(width: 6),
                        Expanded(
                          child: _ResetCodeCell(
                            value: index < compact.length ? compact[index] : '',
                            active: _focusNode.hasFocus && activeIndex == index,
                            enabled: widget.enabled,
                          ),
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '-',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      for (var index = 4; index < 8; index++) ...[
                        if (index > 4) const SizedBox(width: 6),
                        Expanded(
                          child: _ResetCodeCell(
                            value: index < compact.length ? compact[index] : '',
                            active: _focusNode.hasFocus && activeIndex == index,
                            enabled: widget.enabled,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  width: 1,
                  height: 1,
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      autofocus: widget.autofocus,
                      autocorrect: false,
                      enableSuggestions: false,
                      keyboardType: TextInputType.visiblePassword,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: const [DeviceDataResetCodeFormatter()],
                      textInputAction: TextInputAction.done,
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.errorText!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResetCodeCell extends StatelessWidget {
  const _ResetCodeCell({
    required this.value,
    required this.active,
    required this.enabled,
  });

  final String value;
  final bool active;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: enabled
            ? colors.surfaceContainerHighest
            : colors.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? colors.primary : colors.outlineVariant,
          width: active ? 2 : 1,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.16),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 120),
        child: Text(
          value,
          key: ValueKey(value),
          maxLines: 1,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: enabled ? colors.onSurface : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
