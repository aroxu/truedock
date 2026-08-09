import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../resources/domain/server_resources.dart';
import '../domain/nfs_share_configuration.dart';
import 'storage_localizations.dart';

class NfsShareSheet extends StatefulWidget {
  const NfsShareSheet({required this.datasets, this.existingShare, super.key});

  final List<Dataset> datasets;
  final NfsShare? existingShare;

  @override
  State<NfsShareSheet> createState() => _NfsShareSheetState();
}

class _NfsShareSheetState extends State<NfsShareSheet> {
  final _pathController = TextEditingController();
  final _commentController = TextEditingController();
  final _networksController = TextEditingController();
  final _hostsController = TextEditingController();
  final _mapRootUserController = TextEditingController();
  final _mapRootGroupController = TextEditingController();
  final _mapAllUserController = TextEditingController();
  final _mapAllGroupController = TextEditingController();

  final _security = <NfsSecurity>{};
  bool _enabled = true;
  bool _readOnly = false;
  bool _reviewing = false;
  Map<String, NfsValidationCode> _errors = const {};

  bool get _preserveExposeSnapshots =>
      widget.existingShare?.exposeSnapshots ?? false;

  List<String> get _paths =>
      widget.datasets
          .where((dataset) => dataset.type == 'FILESYSTEM' && !dataset.locked)
          .map((dataset) => '/mnt/${dataset.name}')
          .toSet()
          .toList(growable: false)
        ..sort();

  @override
  void initState() {
    super.initState();
    final configuration = widget.existingShare == null
        ? NfsShareConfiguration.defaults()
        : NfsShareConfiguration.fromShare(widget.existingShare!);
    _pathController.text = configuration.path.startsWith('/mnt/')
        ? configuration.path
        : (_paths.isEmpty ? '' : _paths.first);
    _commentController.text = configuration.comment;
    _networksController.text = configuration.networks.join('\n');
    _hostsController.text = configuration.hosts.join('\n');
    _mapRootUserController.text = configuration.mapRootUser ?? '';
    _mapRootGroupController.text = configuration.mapRootGroup ?? '';
    _mapAllUserController.text = configuration.mapAllUser ?? '';
    _mapAllGroupController.text = configuration.mapAllGroup ?? '';
    _security.addAll(configuration.security);
    _enabled = configuration.enabled;
    _readOnly = configuration.readOnly;
  }

  @override
  void dispose() {
    _pathController.dispose();
    _commentController.dispose();
    _networksController.dispose();
    _hostsController.dispose();
    _mapRootUserController.dispose();
    _mapRootGroupController.dispose();
    _mapAllUserController.dispose();
    _mapAllGroupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final editing = widget.existingShare != null;
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
                    backgroundColor: colors.secondaryContainer,
                    child: Icon(
                      _reviewing
                          ? Icons.fact_check_outlined
                          : Icons.folder_shared_outlined,
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _reviewing
                              ? l10n.storageNfsReviewTitle
                              : editing
                              ? l10n.storageNfsEditTitle
                              : l10n.storageNfsNewTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          l10n.storageNfsSubtitle,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: l10n.storageNfsClose,
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
                      label: Text(l10n.storageNfsBack),
                    )
                  else
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.storageNfsCancel),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _reviewing ? _submit : _review,
                    icon: Icon(
                      _reviewing
                          ? editing
                                ? Icons.save_outlined
                                : Icons.add_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(
                      _reviewing
                          ? editing
                                ? l10n.storageNfsSaveChanges
                                : l10n.storageNfsCreateShare
                          : l10n.storageNfsReview,
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
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        TextField(
          controller: _pathController,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.storageNfsExportPathLabel,
            helperText: l10n.storageNfsExportPathHelper,
            errorText: _errors['path'] != null
                ? l10n.nfsValidationMessage(_errors['path']!)
                : null,
            prefixIcon: const Icon(Icons.account_tree_outlined),
            border: const OutlineInputBorder(),
          ),
        ),
        if (_paths.isNotEmpty) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final path in _paths) ...[
                  ActionChip(
                    label: Text(path),
                    onPressed: () =>
                        setState(() => _pathController.text = path),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _commentController,
          decoration: InputDecoration(
            labelText: l10n.storageNfsCommentLabel,
            prefixIcon: const Icon(Icons.notes_outlined),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.storageNfsAuthorizedClients,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _networksController,
          minLines: 2,
          maxLines: 6,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.storageNfsNetworksLabel,
            helperText: l10n.storageNfsNetworksHelper,
            errorText: _errors['networks'] != null
                ? l10n.nfsValidationMessage(_errors['networks']!)
                : null,
            prefixIcon: const Icon(Icons.hub_outlined),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _hostsController,
          minLines: 2,
          maxLines: 6,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.storageNfsHostsLabel,
            helperText: l10n.storageNfsHostsHelper,
            errorText: _errors['hosts'] != null
                ? l10n.nfsValidationMessage(_errors['hosts']!)
                : null,
            prefixIcon: const Icon(Icons.dns_outlined),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.storageNfsSecurityTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final security in NfsSecurity.values)
              FilterChip(
                label: Text(l10n.nfsSecurityLabel(security)),
                selected: _security.contains(security),
                onSelected: (selected) => setState(() {
                  selected
                      ? _security.add(security)
                      : _security.remove(security);
                }),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _security.isEmpty
              ? l10n.storageNfsSecurityEmpty
              : l10n.storageNfsSecuritySelected,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(l10n.storageNfsMappingTitle),
          subtitle: Text(
            _errors['mapping'] != null
                ? l10n.nfsValidationMessage(_errors['mapping']!)
                : l10n.storageNfsMappingSubtitle,
            style: _errors['mapping'] == null
                ? null
                : TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          children: [
            _MappingFields(
              title: l10n.storageNfsMapRoot,
              user: _mapRootUserController,
              group: _mapRootGroupController,
            ),
            const SizedBox(height: 14),
            _MappingFields(
              title: l10n.storageNfsMapAll,
              user: _mapAllUserController,
              group: _mapAllGroupController,
            ),
            const SizedBox(height: 12),
          ],
        ),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          value: _readOnly,
          onChanged: (value) => setState(() => _readOnly = value),
          title: Text(l10n.storageNfsReadOnlyTitle),
          subtitle: Text(l10n.storageNfsReadOnlySubtitle),
        ),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          value: _enabled,
          onChanged: (value) => setState(() => _enabled = value),
          title: Text(l10n.storageNfsEnableTitle),
          subtitle: Text(l10n.storageNfsEnableSubtitle),
        ),
        if (_preserveExposeSnapshots)
          _NfsNotice(message: l10n.storageNfsEnterpriseNotice),
      ],
    );
  }

  Widget _buildReview() {
    final configuration = _configuration;
    final l10n = AppLocalizations.of(context);
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              _ReviewRow(
                label: l10n.storageNfsReviewPath,
                value: configuration.path,
              ),
              _ReviewRow(
                label: l10n.storageNfsReviewClients,
                value: configuration.unrestricted
                    ? l10n.storageNfsReviewClientsAll
                    : [
                        ...configuration.networks,
                        ...configuration.hosts,
                      ].join(', '),
              ),
              _ReviewRow(
                label: l10n.storageNfsReviewAccess,
                value: configuration.readOnly
                    ? l10n.storageNfsReviewAccessReadOnly
                    : l10n.storageNfsReviewAccessReadWrite,
              ),
              _ReviewRow(
                label: l10n.storageNfsReviewSecurity,
                value: configuration.security.isEmpty
                    ? l10n.storageNfsReviewSecurityDefault
                    : configuration.security
                          .map((security) => l10n.nfsSecurityLabel(security))
                          .join(', '),
              ),
              _ReviewRow(
                label: l10n.storageNfsReviewRootMapping,
                value: _mappingLabel(
                  l10n,
                  configuration.mapRootUser,
                  configuration.mapRootGroup,
                ),
              ),
              _ReviewRow(
                label: l10n.storageNfsReviewAllMapping,
                value: _mappingLabel(
                  l10n,
                  configuration.mapAllUser,
                  configuration.mapAllGroup,
                ),
              ),
              _ReviewRow(
                label: l10n.storageNfsReviewState,
                value: configuration.enabled
                    ? l10n.storageNfsReviewStateEnabled
                    : l10n.storageNfsReviewStateDisabled,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (configuration.unrestricted && !configuration.readOnly)
          _NfsNotice(message: l10n.storageNfsUnrestrictedNotice, error: true)
        else if (configuration.mapAllUser == 'root')
          _NfsNotice(message: l10n.storageNfsMapAllRootNotice, error: true)
        else
          _NfsNotice(message: l10n.storageNfsReviewNotice),
      ],
    );
  }

  NfsShareConfiguration get _configuration => NfsShareConfiguration(
    path: _pathController.text.trim(),
    comment: _commentController.text.trim(),
    networks: _lines(_networksController.text),
    hosts: _lines(_hostsController.text),
    readOnly: _readOnly,
    mapRootUser: _nullIfEmpty(_mapRootUserController.text),
    mapRootGroup: _nullIfEmpty(_mapRootGroupController.text),
    mapAllUser: _nullIfEmpty(_mapAllUserController.text),
    mapAllGroup: _nullIfEmpty(_mapAllGroupController.text),
    security: Set.unmodifiable(_security),
    enabled: _enabled,
    exposeSnapshots: _preserveExposeSnapshots,
  );

  void _review() {
    final errors = _configuration.validate();
    setState(() {
      _errors = errors;
      _reviewing = errors.isEmpty;
    });
  }

  void _submit() => Navigator.pop(context, _configuration);
}

class _MappingFields extends StatelessWidget {
  const _MappingFields({
    required this.title,
    required this.user,
    required this.group,
  });

  final String title;
  final TextEditingController user;
  final TextEditingController group;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: user,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.storageNfsUserLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: group,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.storageNfsGroupLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

List<String> _lines(String value) => value
    .split('\n')
    .map((line) => line.trim())
    .where((line) => line.isNotEmpty)
    .toList(growable: false);

String? _nullIfEmpty(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _mappingLabel(AppLocalizations l10n, String? user, String? group) {
  final parts = [user, group].whereType<String>().toList(growable: false);
  return parts.isEmpty
      ? l10n.storageNfsMappingNone
      : l10n.storageNfsMappingLabel(
          parts[0],
          parts.length > 1 ? parts[1] : parts[0],
        );
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
          width: 104,
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

class _NfsNotice extends StatelessWidget {
  const _NfsNotice({required this.message, this.error = false});

  final String message;
  final bool error;

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
            error ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
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
