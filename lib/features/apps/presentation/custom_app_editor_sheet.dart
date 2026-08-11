import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class CustomAppEditorSheet extends StatefulWidget {
  const CustomAppEditorSheet({
    required this.appName,
    required this.configuration,
    super.key,
  });

  final String appName;
  final Map<String, Object?> configuration;

  @override
  State<CustomAppEditorSheet> createState() => _CustomAppEditorSheetState();
}

class _CustomAppEditorSheetState extends State<CustomAppEditorSheet> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(widget.configuration),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.appsInstanceEditTitle(widget.appName),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.appsCustomComposeDescription,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('custom-app-compose-editor'),
              controller: _controller,
              minLines: 14,
              maxLines: 28,
              autocorrect: false,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(fontFamily: 'monospace'),
              decoration: InputDecoration(
                labelText: l10n.appsCustomComposeLabel,
                alignLabelWithHint: true,
                errorText: _error,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.actionCancel),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(l10n.appsCustomComposeReview),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    try {
      final value = jsonDecode(_controller.text);
      if (value is! Map) throw const FormatException();
      Navigator.pop(context, Map<String, Object?>.from(value));
    } on FormatException {
      setState(
        () => _error = AppLocalizations.of(context).appsCustomComposeInvalid,
      );
    }
  }
}
