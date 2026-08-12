import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'static_route_localizations.dart';
import '../domain/static_route_configuration.dart';

/// Editor for a single static route.
///
/// On submit it returns the next [StaticRouteConfiguration] (with an id when
/// editing an existing route, without one when creating). The caller routes
/// the result through `staticroute.create`/`staticroute.update` and the shared
/// high-impact confirmation, then follows up with the network commit/checkin
/// workflow because the route does not take effect until the staged changes
/// are committed.
class StaticRouteSheet extends StatefulWidget {
  const StaticRouteSheet({required this.baseline, super.key});

  /// The route to edit, or a blank configuration when creating.
  final StaticRouteConfiguration baseline;

  @override
  State<StaticRouteSheet> createState() => _StaticRouteSheetState();
}

class _StaticRouteSheetState extends State<StaticRouteSheet> {
  late final TextEditingController _destinationController;
  late final TextEditingController _gatewayController;
  late final TextEditingController _descriptionController;

  late StaticRouteConfiguration _configuration;
  bool _reviewing = false;
  Map<String, StaticRouteValidationCode> _errors = const {};

  @override
  void initState() {
    super.initState();
    _configuration = widget.baseline;
    _destinationController = TextEditingController(
      text: widget.baseline.destination,
    );
    _gatewayController = TextEditingController(text: widget.baseline.gateway);
    _descriptionController = TextEditingController(
      text: widget.baseline.description,
    );
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _gatewayController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _syncConfiguration() {
    _configuration = _configuration.copyWith(
      destination: _destinationController.text.trim(),
      gateway: _gatewayController.text.trim(),
      description: _descriptionController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final creating = widget.baseline.isCreate;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.alt_route_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _reviewing
                          ? l10n.sysRouteReviewTitle
                          : (creating
                                ? l10n.sysRouteNewTitle
                                : l10n.sysRouteEditTitle),
                      style: theme.textTheme.headlineSmall,
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
                          ? Icons.save_outlined
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(
                      _reviewing ? l10n.sysRouteSaveAction : l10n.actionReview,
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
          controller: _destinationController,
          autocorrect: false,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            labelText: l10n.sysRouteDestinationLabel,
            prefixIcon: const Icon(Icons.hub_outlined),
            helperText: l10n.sysRouteDestinationHelper,
          ),
        ),
        if (_errors['destination'] != null) ...[
          const SizedBox(height: 6),
          Text(
            l10n.staticRouteValidationMessage(_errors['destination']!),
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 14),
        TextField(
          controller: _gatewayController,
          autocorrect: false,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            labelText: l10n.sysRouteGatewayLabel,
            prefixIcon: const Icon(Icons.router_rounded),
            helperText: l10n.sysRouteGatewayHelper,
          ),
        ),
        if (_errors['gateway'] != null) ...[
          const SizedBox(height: 6),
          Text(
            l10n.staticRouteValidationMessage(_errors['gateway']!),
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 14),
        TextField(
          controller: _descriptionController,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.sysRouteDescriptionLabel,
            prefixIcon: const Icon(Icons.notes_rounded),
            helperText: l10n.sysRouteDescriptionHelper,
          ),
        ),
        const SizedBox(height: 18),
        _Notice(message: l10n.sysRouteStagedNotice),
      ],
    );
  }

  Widget _review(ThemeData theme, AppLocalizations l10n) {
    _syncConfiguration();
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
                label: l10n.sysRouteReviewDestination,
                value: _configuration.destination,
              ),
              _ReviewRow(
                label: l10n.sysRouteReviewGateway,
                value: _configuration.gateway,
              ),
              _ReviewRow(
                label: l10n.sysRouteReviewDescription,
                value: _configuration.description.isEmpty
                    ? l10n.sysRouteReviewNone
                    : _configuration.description,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Notice(message: l10n.sysRouteCommitNotice),
      ],
    );
  }

  void _validate() {
    _syncConfiguration();
    final errors = validateStaticRouteConfiguration(_configuration);
    setState(() {
      _errors = errors;
      _reviewing = errors.isEmpty;
    });
  }

  void _submit() {
    _syncConfiguration();
    Navigator.of(context).pop(_configuration);
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
            width: 110,
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
  const _Notice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
