import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../resources/domain/server_resources.dart';
import '../domain/iscsi_auth_configuration.dart';
import 'storage_localizations.dart';

/// Editor for a single iSCSI CHAP credential entry.
///
/// Returns an [IscsiAuthConfiguration] after an explicit review step. On
/// create, the secret and (for mutual CHAP) peer secret are required and
/// confirmed by retyping. On edit, leaving a secret blank means "keep the
/// existing server-side secret"; the user must opt into rotation by typing a
/// new one. Secrets never leave this sheet except in the returned
/// configuration, which the caller sends to the server over the authenticated
/// session and then discards.
class IscsiAuthSheet extends StatefulWidget {
  const IscsiAuthSheet({this.existingAuth, this.nextTag = 1, super.key});

  /// When null the sheet creates a new entry; otherwise it edits [existingAuth].
  final IscsiAuth? existingAuth;

  /// Suggested tag for a new entry. TrueNAS tags credentials with a small
  /// integer; the caller picks the next free one.
  final int nextTag;

  @override
  State<IscsiAuthSheet> createState() => _IscsiAuthSheetState();
}

class _IscsiAuthSheetState extends State<IscsiAuthSheet> {
  late final TextEditingController _userController;
  late final TextEditingController _secretController;
  late final TextEditingController _secretConfirmController;
  late final TextEditingController _peerUserController;
  late final TextEditingController _peerSecretController;
  late final TextEditingController _peerSecretConfirmController;

  late int _tag;
  bool _mutual = false;
  bool _obscure = true;
  bool _reviewing = false;
  IscsiAuthValidationCode? _error;

  bool get _editing => widget.existingAuth != null;

  @override
  void initState() {
    super.initState();
    final auth = widget.existingAuth;
    _userController = TextEditingController(text: auth?.user ?? '');
    _secretController = TextEditingController();
    _secretConfirmController = TextEditingController();
    _peerUserController = TextEditingController(text: auth?.peerUser ?? '');
    _peerSecretController = TextEditingController();
    _peerSecretConfirmController = TextEditingController();
    _tag = auth?.tag ?? widget.nextTag;
    _mutual = auth?.isMutual ?? false;
  }

  @override
  void dispose() {
    _userController.dispose();
    _secretController.dispose();
    _secretConfirmController.dispose();
    _peerUserController.dispose();
    _peerSecretController.dispose();
    _peerSecretConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.shield_outlined,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _reviewing
                              ? l10n.storageIscsiAuthReviewTitle
                              : _editing
                              ? l10n.storageIscsiAuthEditTitle
                              : l10n.storageIscsiAuthNewTitle,
                          style: theme.textTheme.headlineSmall,
                        ),
                        Text(
                          l10n.storageIscsiAuthSubtitle,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: l10n.storageIscsiAuthClose,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(child: _reviewing ? _review(theme) : _form(theme)),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_reviewing)
                    TextButton.icon(
                      onPressed: () => setState(() => _reviewing = false),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text(l10n.storageIscsiAuthBack),
                    )
                  else
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.storageIscsiAuthCancel),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _reviewing ? _submit : _validate,
                    icon: Icon(
                      _reviewing
                          ? Icons.save_outlined
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(
                      _reviewing
                          ? (_editing
                                ? l10n.storageIscsiAuthSaveChanges
                                : l10n.storageIscsiAuthCreateCredential)
                          : l10n.storageIscsiAuthReview,
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

  Widget _form(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        TextField(
          controller: _userController,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (_) => setState(() => _error = null),
          decoration: InputDecoration(
            labelText: l10n.storageIscsiAuthChapUserLabel,
            prefixIcon: const Icon(Icons.person_outline_rounded),
            helperText: l10n.storageIscsiAuthChapUserHelper,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _secretController,
          obscureText: _obscure,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (_) => setState(() => _error = null),
          decoration: InputDecoration(
            labelText: _editing
                ? l10n.storageIscsiAuthNewSecretLabel
                : l10n.storageIscsiAuthSecretLabel,
            prefixIcon: const Icon(Icons.key_outlined),
            helperText: _editing
                ? l10n.storageIscsiAuthNewSecretHelper
                : l10n.storageIscsiAuthSecretHelper,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              tooltip: _obscure
                  ? l10n.storageIscsiAuthShow
                  : l10n.storageIscsiAuthHide,
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _secretConfirmController,
          obscureText: _obscure,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (_) => setState(() => _error = null),
          decoration: InputDecoration(
            labelText: _editing
                ? l10n.storageIscsiAuthConfirmNewSecretLabel
                : l10n.storageIscsiAuthConfirmSecretLabel,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            helperText: _editing
                ? l10n.storageIscsiAuthConfirmNewSecretHelper
                : null,
          ),
        ),
        const SizedBox(height: 18),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.storageIscsiAuthMutualTitle),
          subtitle: Text(l10n.storageIscsiAuthMutualSubtitle),
          value: _mutual,
          onChanged: (value) => setState(() {
            _mutual = value;
            _error = null;
            if (!value) {
              _peerSecretController.clear();
              _peerSecretConfirmController.clear();
            }
          }),
        ),
        if (_mutual) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _peerUserController,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(
              labelText: l10n.storageIscsiAuthPeerUserLabel,
              prefixIcon: const Icon(Icons.person_outline_rounded),
              helperText: l10n.storageIscsiAuthPeerUserHelper,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _peerSecretController,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(
              labelText: _editing
                  ? l10n.storageIscsiAuthNewPeerSecretLabel
                  : l10n.storageIscsiAuthPeerSecretLabel,
              prefixIcon: const Icon(Icons.key_outlined),
              helperText: _editing
                  ? l10n.storageIscsiAuthNewPeerSecretHelper
                  : null,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                tooltip: _obscure
                    ? l10n.storageIscsiAuthShow
                    : l10n.storageIscsiAuthHide,
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _peerSecretConfirmController,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(
              labelText: _editing
                  ? l10n.storageIscsiAuthConfirmNewPeerSecretLabel
                  : l10n.storageIscsiAuthConfirmPeerSecretLabel,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              helperText: _editing
                  ? l10n.storageIscsiAuthConfirmNewPeerSecretHelper
                  : null,
            ),
          ),
        ],
        const SizedBox(height: 16),
        _Notice(message: l10n.storageIscsiAuthSecretsNotice),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _Notice(
            message: l10n.iscsiAuthValidationMessage(_error!),
            error: true,
          ),
        ],
      ],
    );
  }

  Widget _review(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final secret = _secretController.text;
    final peerSecret = _peerSecretController.text;
    return ListView(
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
              _ReviewRow(label: l10n.storageIscsiAuthReviewTag, value: '$_tag'),
              _ReviewRow(
                label: l10n.storageIscsiAuthReviewChapUser,
                value: _userController.text,
              ),
              _ReviewRow(
                label: l10n.storageIscsiAuthReviewSecret,
                value: _editing && secret.isEmpty
                    ? l10n.storageIscsiAuthReviewSecretUnchanged
                    : l10n.storageIscsiAuthReviewSecretSet(secret.length),
              ),
              _ReviewRow(
                label: l10n.storageIscsiAuthReviewMutual,
                value: _mutual
                    ? l10n.storageIscsiAuthReviewYes
                    : l10n.storageIscsiAuthReviewNo,
              ),
              if (_mutual) ...[
                _ReviewRow(
                  label: l10n.storageIscsiAuthReviewPeerUser,
                  value: _peerUserController.text,
                ),
                _ReviewRow(
                  label: l10n.storageIscsiAuthReviewPeerSecret,
                  value: _editing && peerSecret.isEmpty
                      ? l10n.storageIscsiAuthReviewSecretUnchanged
                      : l10n.storageIscsiAuthReviewSecretSet(peerSecret.length),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Notice(
          message: _editing
              ? l10n.storageIscsiAuthReviewNoticeEdit
              : l10n.storageIscsiAuthReviewNoticeCreate,
        ),
      ],
    );
  }

  void _validate() {
    final user = _userController.text.trim();
    final secret = _secretController.text;
    final secretConfirm = _secretConfirmController.text;
    final peerUser = _peerUserController.text.trim();
    final peerSecret = _peerSecretController.text;
    final peerSecretConfirm = _peerSecretConfirmController.text;

    if (user.isEmpty) {
      setState(() => _error = IscsiAuthValidationCode.userRequired);
      return;
    }
    if (!_editing && secret.isEmpty) {
      setState(() => _error = IscsiAuthValidationCode.secretRequired);
      return;
    }
    if (secret.isNotEmpty && secret != secretConfirm) {
      setState(() => _error = IscsiAuthValidationCode.secretMismatch);
      return;
    }
    if (_mutual) {
      if (peerUser.isEmpty) {
        setState(() => _error = IscsiAuthValidationCode.peerUserRequired);
        return;
      }
      if (!_editing && peerSecret.isEmpty) {
        setState(() => _error = IscsiAuthValidationCode.peerSecretRequired);
        return;
      }
      if (peerSecret.isNotEmpty && peerSecret != peerSecretConfirm) {
        setState(() => _error = IscsiAuthValidationCode.peerSecretMismatch);
        return;
      }
    }
    setState(() {
      _error = null;
      _reviewing = true;
    });
  }

  void _submit() {
    final secret = _secretController.text;
    final peerSecret = _peerSecretController.text;
    Navigator.of(context).pop(
      IscsiAuthConfiguration(
        tag: _tag,
        user: _userController.text.trim(),
        secret: secret.isEmpty ? null : secret,
        peerUser: _mutual ? _peerUserController.text.trim() : '',
        peerSecret: _mutual && peerSecret.isNotEmpty ? peerSecret : null,
      ),
    );
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
            width: 120,
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
  const _Notice({required this.message, this.error = false});

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: error
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            error ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            size: 20,
            color: error
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: error
                    ? theme.colorScheme.onErrorContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
