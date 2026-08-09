import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

import '../../resources/domain/server_resources.dart';

/// The secret and options collected before calling `pool.dataset.unlock`.
class DatasetUnlockRequest {
  const DatasetUnlockRequest({
    required this.secret,
    required this.usePassphrase,
    required this.unlockChildren,
  });

  final String secret;
  final bool usePassphrase;
  final bool unlockChildren;
}

/// Collects the passphrase or hex key needed to unlock an encrypted dataset.
///
/// The secret only lives in this sheet's controller and is handed straight to
/// the caller. It is never persisted, logged, or echoed back in any message.
class DatasetUnlockSheet extends StatefulWidget {
  const DatasetUnlockSheet({required this.dataset, super.key});

  final Dataset dataset;

  @override
  State<DatasetUnlockSheet> createState() => _DatasetUnlockSheetState();
}

class _DatasetUnlockSheetState extends State<DatasetUnlockSheet> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _unlockChildren = true;
  String? _error;

  bool get _usePassphrase => widget.dataset.usesPassphrase;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.storageUnlockTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(widget.dataset.name, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              autofocus: true,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => setState(() => _error = null),
              decoration: InputDecoration(
                labelText: _usePassphrase
                    ? l10n.storageUnlockPassphraseLabel
                    : l10n.storageUnlockHexKeyLabel,
                helperText: _usePassphrase
                    ? l10n.storageUnlockPassphraseHelper
                    : l10n.storageUnlockHexKeyHelper,
                helperMaxLines: 10,
                prefixIcon: const Icon(Icons.key_outlined),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  tooltip: _obscure
                      ? l10n.storageUnlockShow
                      : l10n.storageUnlockHide,
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.storageUnlockChildrenTitle),
              subtitle: Text(l10n.storageUnlockChildrenSubtitle),
              value: _unlockChildren,
              onChanged: (value) => setState(() => _unlockChildren = value),
            ),
            const SizedBox(height: 8),
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.storageUnlockSecretNotice,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
            if (_error case final error?) ...[
              const SizedBox(height: 16),
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    error,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.lock_open_rounded),
              label: Text(l10n.storageUnlockAction),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    final secret = _controller.text;
    if (secret.trim().isEmpty) {
      setState(
        () => _error = _usePassphrase
            ? l10n.storageUnlockErrorPassphraseRequired
            : l10n.storageUnlockErrorHexKeyRequired,
      );
      return;
    }
    if (!_usePassphrase && !RegExp(r'^[0-9a-fA-F]+$').hasMatch(secret.trim())) {
      setState(() => _error = l10n.storageUnlockErrorHexKeyFormat);
      return;
    }
    Navigator.of(context).pop(
      DatasetUnlockRequest(
        // A passphrase may legitimately contain leading or trailing spaces,
        // but a hex key never does.
        secret: _usePassphrase ? secret : secret.trim(),
        usePassphrase: _usePassphrase,
        unlockChildren: _unlockChildren,
      ),
    );
  }
}
