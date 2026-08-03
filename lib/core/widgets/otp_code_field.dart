import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Six-cell one-time-code input with no separator, entered one digit at a
/// time like [DeviceDataResetCodeField].
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
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

  static const length = 6;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  late final FocusNode _focusNode = FocusNode()..addListener(_refresh);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant OtpCodeField oldWidget) {
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
    final digits = widget.controller.text;
    final activeIndex = digits.length.clamp(0, OtpCodeField.length - 1);
    return Semantics(
      label: widget.semanticLabel,
      value: widget.controller.text,
      textField: true,
      enabled: widget.enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? _focusNode.requestFocus : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ExcludeSemantics(
                  child: Row(
                    children: [
                      for (
                        var index = 0;
                        index < OtpCodeField.length;
                        index++
                      ) ...[
                        if (index > 0) const SizedBox(width: 6),
                        Expanded(
                          child: _OtpCodeCell(
                            value: index < digits.length ? digits[index] : '',
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
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(OtpCodeField.length),
                      ],
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

class _OtpCodeCell extends StatelessWidget {
  const _OtpCodeCell({
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
