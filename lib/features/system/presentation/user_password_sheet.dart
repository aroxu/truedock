import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

import '../domain/system_resources.dart';

/// Sets a new password for a local user.
///
/// Returns the chosen password string only after an explicit confirmation
/// step; the caller routes it through the shared destructive-action
/// confirmation and then through `user.update`. The password never leaves
/// this sheet except to be sent to the connected TrueNAS server.
class UserPasswordSheet extends StatefulWidget {
  const UserPasswordSheet({required this.user, super.key});

  final NasUser user;

  @override
  State<UserPasswordSheet> createState() => _UserPasswordSheetState();
}

class _UserPasswordSheetState extends State<UserPasswordSheet> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _reviewing = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
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
          height: MediaQuery.sizeOf(context).height * .62,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.errorContainer,
                    child: Icon(
                      Icons.key_off_outlined,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _reviewing
                              ? l10n.sysUserPasswordReviewTitle
                              : l10n.sysUserPasswordSetTitle(
                                  widget.user.username,
                                ),
                          style: theme.textTheme.headlineSmall,
                        ),
                        Text(
                          widget.user.local
                              ? l10n.sysUserPasswordLocalAccount
                              : l10n.sysUserPasswordDirectoryAccount,
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
                    tooltip: l10n.actionClose,
                  ),
                ],
              ),
              const SizedBox(height: 18),
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
                  else
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.actionCancel),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _reviewing ? _submit : _validate,
                    icon: Icon(
                      _reviewing
                          ? Icons.key_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(
                      _reviewing
                          ? l10n.sysUserPasswordReviewAction
                          : l10n.actionReview,
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

  Widget _form(ThemeData theme, AppLocalizations l10n) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        TextField(
          controller: _passwordController,
          obscureText: _obscure,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (_) => setState(() => _error = null),
          decoration: InputDecoration(
            labelText: l10n.sysUserPasswordNewLabel,
            prefixIcon: const Icon(Icons.key_outlined),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              tooltip: _obscure
                  ? l10n.sysUserShowPassword
                  : l10n.sysUserHidePassword,
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
          controller: _confirmController,
          obscureText: _obscure,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (_) => setState(() => _error = null),
          decoration: InputDecoration(
            labelText: l10n.sysUserPasswordConfirmLabel,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
          ),
        ),
        const SizedBox(height: 16),
        _PasswordNotice(message: l10n.sysUserPasswordNotice),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _PasswordNotice(message: _error!, error: true),
        ],
      ],
    );
  }

  Widget _review(ThemeData theme, AppLocalizations l10n) {
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
              _ReviewRow(
                label: l10n.sysUserPasswordReviewServerAction,
                value: l10n.sysUserPasswordReviewServerActionValue,
              ),
              _ReviewRow(
                label: l10n.sysUserPasswordReviewAccount,
                value: widget.user.username,
              ),
              _ReviewRow(
                label: l10n.sysUserPasswordReviewSetLabel,
                value: l10n.sysUserPasswordReviewSetValue(
                  _passwordController.text.length,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _PasswordNotice(
          message: l10n.sysUserPasswordReviewSessionWarning(
            widget.user.username,
          ),
        ),
      ],
    );
  }

  void _validate() {
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    if (password.isEmpty) {
      setState(
        () => _error = AppLocalizations.of(context).sysUserPasswordErrorEmpty,
      );
      return;
    }
    if (password.length < 8) {
      setState(
        () => _error = AppLocalizations.of(context).sysUserPasswordErrorShort,
      );
      return;
    }
    if (password != confirm) {
      setState(
        () =>
            _error = AppLocalizations.of(context).sysUserPasswordErrorMismatch,
      );
      return;
    }
    setState(() {
      _error = null;
      _reviewing = true;
    });
  }

  void _submit() {
    Navigator.of(context).pop(_passwordController.text);
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

class _PasswordNotice extends StatelessWidget {
  const _PasswordNotice({required this.message, this.error = false});

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
            : theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            error ? Icons.error_outline_rounded : Icons.shield_outlined,
            color: error
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.onSurfaceVariant,
            size: 20,
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
