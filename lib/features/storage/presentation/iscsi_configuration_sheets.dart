import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../resources/domain/server_resources.dart';
import '../domain/iscsi_configuration.dart';
import 'storage_localizations.dart';

class IscsiPortalSheet extends StatefulWidget {
  const IscsiPortalSheet({
    required this.availableAddresses,
    this.existingPortal,
    super.key,
  });

  final List<String> availableAddresses;
  final IscsiPortal? existingPortal;

  @override
  State<IscsiPortalSheet> createState() => _IscsiPortalSheetState();
}

class _IscsiPortalSheetState extends State<IscsiPortalSheet> {
  final _commentController = TextEditingController();
  final _selectedAddresses = <String>{};
  bool _reviewing = false;
  Map<String, IscsiPortalValidationCode> _errors = const {};

  List<String> get _unavailableExistingAddresses =>
      widget.existingPortal?.listen
          .map((entry) => entry.ip)
          .where((address) => !widget.availableAddresses.contains(address))
          .toList(growable: false) ??
      const [];

  @override
  void initState() {
    super.initState();
    final configuration = widget.existingPortal == null
        ? IscsiPortalConfiguration.defaults(widget.availableAddresses)
        : IscsiPortalConfiguration.fromPortal(widget.existingPortal!);
    _selectedAddresses.addAll(configuration.listenAddresses);
    _commentController.text = configuration.comment;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _IscsiSheetFrame(
      icon: Icons.router_outlined,
      title: _reviewing
          ? l10n.storageIscsiPortalReviewTitle
          : widget.existingPortal == null
          ? l10n.storageIscsiPortalNewTitle
          : l10n.storageIscsiPortalEditTitle,
      subtitle: l10n.storageIscsiPortalSubtitle,
      reviewing: _reviewing,
      submitLabel: widget.existingPortal == null
          ? l10n.storageIscsiPortalCreate
          : l10n.storageIscsiPortalSaveChanges,
      onBack: () => setState(() => _reviewing = false),
      onCancel: () => Navigator.pop(context),
      onNext: _review,
      onSubmit: () => Navigator.pop(context, _configuration),
      child: _reviewing ? _buildReview() : _buildForm(),
    );
  }

  Widget _buildForm() {
    final l10n = AppLocalizations.of(context);
    return ListView(
      children: [
        Text(
          l10n.storageIscsiPortalListenAddresses,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          l10n.storageIscsiPortalListenHelper,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.availableAddresses.isEmpty)
          _IscsiNotice(message: l10n.storageIscsiPortalNoAddress, error: true)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final address in widget.availableAddresses)
                FilterChip(
                  label: Text(address),
                  selected: _selectedAddresses.contains(address),
                  onSelected: (selected) => setState(() {
                    selected
                        ? _selectedAddresses.add(address)
                        : _selectedAddresses.remove(address);
                  }),
                ),
            ],
          ),
        if (_errors['listen'] case final error?) ...[
          const SizedBox(height: 8),
          Text(
            l10n.iscsiPortalValidationMessage(error),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (_unavailableExistingAddresses.isNotEmpty) ...[
          const SizedBox(height: 12),
          _IscsiNotice(
            message: l10n.storageIscsiPortalUnavailableNotice(
              _unavailableExistingAddresses.join(', '),
            ),
            error: true,
          ),
        ],
        const SizedBox(height: 18),
        TextField(
          controller: _commentController,
          decoration: InputDecoration(
            labelText: l10n.storageIscsiPortalCommentLabel,
            helperText: l10n.storageIscsiPortalCommentHelper,
            prefixIcon: const Icon(Icons.notes_outlined),
            border: const OutlineInputBorder(),
          ),
        ),
        if (widget.existingPortal != null) ...[
          const SizedBox(height: 14),
          _IscsiNotice(message: l10n.storageIscsiPortalUpdateNotice),
        ],
      ],
    );
  }

  Widget _buildReview() {
    final l10n = AppLocalizations.of(context);
    return ListView(
      children: [
        _IscsiReviewCard(
          rows: [
            (
              l10n.storageIscsiPortalReviewListen,
              _configuration.listenAddresses.join(', '),
            ),
            (
              l10n.storageIscsiPortalReviewPort,
              l10n.storageIscsiPortalReviewPortValue,
            ),
            (
              l10n.storageIscsiPortalReviewComment,
              _configuration.comment.isEmpty
                  ? l10n.storageIscsiPortalReviewNone
                  : _configuration.comment,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _IscsiNotice(message: l10n.storageIscsiPortalReviewNotice),
      ],
    );
  }

  IscsiPortalConfiguration get _configuration => IscsiPortalConfiguration(
    listenAddresses: widget.availableAddresses
        .where(_selectedAddresses.contains)
        .toList(growable: false),
    comment: _commentController.text.trim(),
  );

  void _review() {
    final errors = _configuration.validate(
      availableAddresses: widget.availableAddresses,
    );
    setState(() {
      _errors = errors;
      _reviewing = errors.isEmpty;
    });
  }
}

class IscsiInitiatorSheet extends StatefulWidget {
  const IscsiInitiatorSheet({this.existingInitiator, super.key});

  final IscsiInitiator? existingInitiator;

  @override
  State<IscsiInitiatorSheet> createState() => _IscsiInitiatorSheetState();
}

class _IscsiInitiatorSheetState extends State<IscsiInitiatorSheet> {
  final _initiatorsController = TextEditingController();
  final _commentController = TextEditingController();
  bool _reviewing = false;
  Map<String, IscsiInitiatorValidationCode> _errors = const {};

  @override
  void initState() {
    super.initState();
    final configuration = widget.existingInitiator == null
        ? IscsiInitiatorConfiguration.defaults()
        : IscsiInitiatorConfiguration.fromInitiator(widget.existingInitiator!);
    _initiatorsController.text = configuration.initiators.join('\n');
    _commentController.text = configuration.comment;
  }

  @override
  void dispose() {
    _initiatorsController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _IscsiSheetFrame(
      icon: Icons.devices_other_outlined,
      title: _reviewing
          ? l10n.storageIscsiInitiatorReviewTitle
          : widget.existingInitiator == null
          ? l10n.storageIscsiInitiatorNewTitle
          : l10n.storageIscsiInitiatorEditTitle,
      subtitle: l10n.storageIscsiInitiatorSubtitle,
      reviewing: _reviewing,
      submitLabel: widget.existingInitiator == null
          ? l10n.storageIscsiInitiatorCreate
          : l10n.storageIscsiInitiatorSaveChanges,
      onBack: () => setState(() => _reviewing = false),
      onCancel: () => Navigator.pop(context),
      onNext: _review,
      onSubmit: () => Navigator.pop(context, _configuration),
      child: _reviewing ? _buildReview() : _buildForm(),
    );
  }

  Widget _buildForm() {
    final l10n = AppLocalizations.of(context);
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        TextField(
          controller: _initiatorsController,
          minLines: 5,
          maxLines: 10,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.storageIscsiInitiatorLabel,
            helperText: l10n.storageIscsiInitiatorHelper,
            errorText: _errors['initiators'] != null
                ? l10n.iscsiInitiatorValidationMessage(_errors['initiators']!)
                : null,
            prefixIcon: const Icon(Icons.badge_outlined),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _commentController,
          decoration: InputDecoration(
            labelText: l10n.storageIscsiInitiatorCommentLabel,
            helperText: l10n.storageIscsiInitiatorCommentHelper,
            prefixIcon: const Icon(Icons.notes_outlined),
            border: const OutlineInputBorder(),
          ),
        ),
        if (widget.existingInitiator != null) ...[
          const SizedBox(height: 14),
          _IscsiNotice(message: l10n.storageIscsiInitiatorUpdateNotice),
        ],
      ],
    );
  }

  Widget _buildReview() {
    final l10n = AppLocalizations.of(context);
    return ListView(
      children: [
        _IscsiReviewCard(
          rows: [
            (
              l10n.storageIscsiInitiatorReviewClients,
              _configuration.allowsAll
                  ? l10n.storageIscsiInitiatorReviewAll
                  : _configuration.initiators.join(', '),
            ),
            (
              l10n.storageIscsiInitiatorReviewComment,
              _configuration.comment.isEmpty
                  ? l10n.storageIscsiInitiatorReviewNone
                  : _configuration.comment,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_configuration.allowsAll)
          _IscsiNotice(
            message: l10n.storageIscsiInitiatorAllNotice,
            error: true,
          )
        else
          _IscsiNotice(message: l10n.storageIscsiInitiatorListedNotice),
      ],
    );
  }

  IscsiInitiatorConfiguration get _configuration => IscsiInitiatorConfiguration(
    initiators: _lines(_initiatorsController.text),
    comment: _commentController.text.trim(),
  );

  void _review() {
    final errors = _configuration.validate();
    setState(() {
      _errors = errors;
      _reviewing = errors.isEmpty;
    });
  }
}

class _IscsiSheetFrame extends StatelessWidget {
  const _IscsiSheetFrame({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.reviewing,
    required this.submitLabel,
    required this.onBack,
    required this.onCancel,
    required this.onNext,
    required this.onSubmit,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool reviewing;
  final String submitLabel;
  final VoidCallback onBack;
  final VoidCallback onCancel;
  final VoidCallback onNext;
  final VoidCallback onSubmit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .9,
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
                    backgroundColor: colors.tertiaryContainer,
                    child: Icon(icon, color: colors.onTertiaryContainer),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close_rounded),
                    tooltip: l10n.storageIscsiConfigClose,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(child: child),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (reviewing)
                    TextButton.icon(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text(l10n.storageIscsiConfigBack),
                    )
                  else
                    TextButton(
                      onPressed: onCancel,
                      child: Text(l10n.storageIscsiConfigCancel),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: reviewing ? onSubmit : onNext,
                    icon: Icon(
                      reviewing
                          ? Icons.save_outlined
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(
                      reviewing ? submitLabel : l10n.storageIscsiConfigReview,
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
}

class _IscsiReviewCard extends StatelessWidget {
  const _IscsiReviewCard({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
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
          ),
      ],
    ),
  );
}

class _IscsiNotice extends StatelessWidget {
  const _IscsiNotice({required this.message, this.error = false});

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: error ? colors.errorContainer : colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            error ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
            color: error ? colors.onErrorContainer : colors.onTertiaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

List<String> _lines(String value) => value
    .split('\n')
    .map((line) => line.trim())
    .where((line) => line.isNotEmpty)
    .toList(growable: false);
