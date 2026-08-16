import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/safe_refresh_indicator.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../connection/presentation/connection_controller.dart';
import '../../resources/presentation/server_resources_provider.dart';
import 'system_administration_screen.dart';
import 'system_resources_provider.dart';

class SystemScreen extends ConsumerStatefulWidget {
  const SystemScreen({super.key});

  @override
  ConsumerState<SystemScreen> createState() => _SystemScreenState();
}

class _SystemScreenState extends ConsumerState<SystemScreen> {
  String? _selectedSection;

  @override
  Widget build(BuildContext context) {
    final window = MediaQuery.sizeOf(context);
    final usesInlineNavigation =
        window.width >= 600 || window.width > window.height;
    final showingInlineSection = _selectedSection != null;
    final isActiveTab = TickerMode.valuesOf(context).enabled;

    return PopScope<Object?>(
      canPop: !isActiveTab || !showingInlineSection,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && isActiveTab && showingInlineSection) {
          _showMenu();
        }
      },
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: context.motionDuration(AppMotion.emphasized),
          switchInCurve: AppMotion.standardCurve,
          switchOutCurve: AppMotion.exitCurve,
          transitionBuilder: (child, animation) {
            final openingSection =
                child.key is ValueKey<String> &&
                (child.key! as ValueKey<String>).value.startsWith(
                  'system-inline-section-',
                );
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: Offset(openingSection ? 0.16 : -0.16, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: AppMotion.standardCurve,
                      ),
                    ),
                child: child,
              ),
            );
          },
          child: showingInlineSection
              ? SystemAdministrationScreen(
                  key: ValueKey('system-inline-section-$_selectedSection'),
                  section: _selectedSection!,
                  onBack: _showMenu,
                )
              : KeyedSubtree(
                  key: const ValueKey('system-menu'),
                  child: _buildMenu(context, usesInlineNavigation),
                ),
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context, bool usesInlineNavigation) {
    final l10n = AppLocalizations.of(context);
    final connection = ref.watch(connectionControllerProvider);
    return SafeRefreshIndicator(
      onRefresh: () async {
        if (connection.isConnected) {
          final info = ref
              .read(connectionControllerProvider.notifier)
              .refreshSystemInfo();
          refreshServerResources(ref);
          refreshSystemResources(ref);
          await Future.wait([
            info,
            ref.read(serverResourcesProvider.future),
            ref.read(systemResourcesProvider.future),
          ]);
        }
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(title: Text(l10n.navSystem)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            sliver: SliverList.list(
              children: [
                Text(
                  l10n.systemAdministration,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    children: [
                      _AdminTile(
                        key: const ValueKey('system-general-tile'),
                        icon: Icons.settings_outlined,
                        title: l10n.systemGeneralSettings,
                        subtitle: l10n.systemGeneralSettingsSubtitle,
                        enabled: connection.isConnected,
                        onTap: () => _openSection(
                          context,
                          'general',
                          usesInlineNavigation,
                        ),
                      ),
                      const Divider(indent: 68, height: 1),
                      _AdminTile(
                        icon: Icons.notifications_outlined,
                        title: l10n.systemAlertsAndJobs,
                        enabled: connection.isConnected,
                        onTap: () => _openSection(
                          context,
                          'activity',
                          usesInlineNavigation,
                        ),
                      ),
                      const Divider(indent: 68, height: 1),
                      _AdminTile(
                        icon: Icons.people_outline_rounded,
                        title: l10n.systemUsersAndAccess,
                        enabled: connection.isConnected,
                        onTap: () => _openSection(
                          context,
                          'accounts',
                          usesInlineNavigation,
                        ),
                      ),
                      const Divider(indent: 68, height: 1),
                      _AdminTile(
                        icon: Icons.lan_outlined,
                        title: l10n.systemNetwork,
                        enabled: connection.isConnected,
                        onTap: () => _openSection(
                          context,
                          'network',
                          usesInlineNavigation,
                        ),
                      ),
                      const Divider(indent: 68, height: 1),
                      _AdminTile(
                        icon: Icons.schedule_rounded,
                        title: l10n.sysCronTitle,
                        enabled: connection.isConnected,
                        onTap: () =>
                            _openSection(context, 'cron', usesInlineNavigation),
                      ),
                      const Divider(indent: 68, height: 1),
                      _AdminTile(
                        key: const ValueKey('system-advanced-tile'),
                        icon: Icons.admin_panel_settings_outlined,
                        title: l10n.systemAdvanced,
                        subtitle: l10n.systemAdvancedSubtitle,
                        enabled: connection.isConnected,
                        onTap: () => _openSection(
                          context,
                          'advanced',
                          usesInlineNavigation,
                        ),
                      ),
                      const Divider(indent: 68, height: 1),
                      _AdminTile(
                        key: const ValueKey('system-updates-tile'),
                        icon: Icons.system_update_alt_rounded,
                        title: l10n.systemUpdates,
                        enabled: connection.isConnected,
                        onTap: () => _openSection(
                          context,
                          'updates',
                          usesInlineNavigation,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openSection(
    BuildContext context,
    String section,
    bool usesInlineNavigation,
  ) {
    if (!usesInlineNavigation) {
      context.push('/system/$section');
      return;
    }
    setState(() => _selectedSection = section);
  }

  void _showMenu() => setState(() => _selectedSection = null);
}

class _AdminTile extends StatelessWidget {
  const _AdminTile({
    required this.icon,
    required this.title,
    required this.enabled,
    required this.onTap,
    this.subtitle,
    super.key,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: enabled,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: enabled ? onTap : null,
    );
  }
}

class AppearanceSheet extends ConsumerWidget {
  const AppearanceSheet({super.key});

  static const presets = [
    AppTheme.defaultSeed,
    Color(0xFF5977D3),
    Color(0xFF7D5260),
    Color(0xFF6F7E2C),
    Color(0xFF9C4146),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);
    final supportsDynamic = defaultTargetPlatform == TargetPlatform.android;
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
            Text(
              l10n.systemAppearance,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 22),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(l10n.themeModeSystem),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(l10n.themeModeLight),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(l10n.themeModeDark),
                ),
              ],
              selected: {settings.mode},
              onSelectionChanged: (value) => controller.setMode(value.first),
            ),
            const SizedBox(height: 26),
            Text(
              l10n.themeColor,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (supportsDynamic) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.themeSystemDynamicColor),
                subtitle: Text(l10n.themeSystemDynamicColorSubtitle),
                value: settings.source == ThemeSource.systemDynamic,
                onChanged: (value) => controller.setSource(
                  value ? ThemeSource.systemDynamic : ThemeSource.brand,
                  seedColor: AppTheme.defaultSeed,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final color in presets)
                  _ColorChoice(
                    color: color,
                    selected:
                        settings.source != ThemeSource.systemDynamic &&
                        settings.seedColor.toARGB32() == color.toARGB32(),
                    onTap: () => controller.setSource(
                      color == AppTheme.defaultSeed
                          ? ThemeSource.brand
                          : ThemeSource.custom,
                      seedColor: color,
                    ),
                  ),
                _CustomColorChoice(
                  initialColor: settings.seedColor,
                  onSelected: (color) => controller.setSource(
                    ThemeSource.custom,
                    seedColor: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hex =
        '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    return Semantics(
      button: true,
      selected: selected,
      label: AppLocalizations.of(context).themeColorSemantics(hex),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.transparent,
              width: 3,
            ),
          ),
          child: selected
              ? const Icon(Icons.check_rounded, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

class _CustomColorChoice extends StatelessWidget {
  const _CustomColorChoice({
    required this.initialColor,
    required this.onSelected,
  });
  final Color initialColor;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: () async {
        final value = await showDialog<Color>(
          context: context,
          builder: (context) => _ColorPickerDialog(initialColor: initialColor),
        );
        if (value != null) onSelected(value);
      },
      icon: const Icon(Icons.add_rounded),
      tooltip: AppLocalizations.of(context).themeCustomColor,
      style: IconButton.styleFrom(minimumSize: const Size.square(50)),
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initialColor});

  final Color initialColor;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late final TextEditingController controller;
  late HSVColor selected;
  String? error;

  @override
  void initState() {
    super.initState();
    selected = HSVColor.fromColor(widget.initialColor);
    controller = TextEditingController(text: _hex(selected.toColor()));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.themeCustomSourceColor),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SaturationValuePicker(
                color: selected,
                onChanged: _selectFromPicker,
              ),
              const SizedBox(height: 18),
              _HuePicker(color: selected, onChanged: _selectFromPicker),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    label: l10n.themeColorSemantics(
                      '#${_hex(selected.toColor())}',
                    ),
                    child: Container(
                      key: const ValueKey('custom-color-preview'),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: selected.toColor(),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      key: const ValueKey('custom-color-hex'),
                      controller: controller,
                      autofocus: false,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 6,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp('[0-9a-fA-F]'),
                        ),
                        LengthLimitingTextInputFormatter(6),
                      ],
                      onChanged: _selectFromHex,
                      decoration: InputDecoration(
                        prefixText: '#',
                        labelText: l10n.themeHexColor,
                        errorText: error,
                        counterText: '',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(onPressed: _apply, child: Text(l10n.actionApply)),
      ],
    );
  }

  void _apply() {
    final raw = controller.text.trim();
    final value = int.tryParse(raw, radix: 16);
    if (value == null || raw.length != 6) {
      setState(() => error = AppLocalizations.of(context).themeInvalidHex);
      return;
    }
    Navigator.pop(context, Color(0xFF000000 | value));
  }

  void _selectFromPicker(HSVColor value) {
    setState(() {
      selected = value;
      error = null;
      controller.value = TextEditingValue(
        text: _hex(value.toColor()),
        selection: const TextSelection.collapsed(offset: 6),
      );
    });
  }

  void _selectFromHex(String raw) {
    final value = int.tryParse(raw, radix: 16);
    setState(() {
      error = null;
      if (value != null && raw.length == 6) {
        selected = HSVColor.fromColor(Color(0xFF000000 | value));
      }
    });
  }

  static String _hex(Color color) =>
      color.toARGB32().toRadixString(16).substring(2).toUpperCase();
}

class _SaturationValuePicker extends StatelessWidget {
  const _SaturationValuePicker({required this.color, required this.onChanged});

  final HSVColor color;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) {
    void update(Offset position, Size size) {
      onChanged(
        color
            .withSaturation((position.dx / size.width).clamp(0.0, 1.0))
            .withValue(1 - (position.dy / size.height).clamp(0.0, 1.0)),
      );
    }

    return Semantics(
      label: AppLocalizations.of(context).themeColorPickerArea,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, 190);
          return GestureDetector(
            key: const ValueKey('saturation-value-picker'),
            onTapDown: (details) => update(details.localPosition, size),
            onPanUpdate: (details) => update(details.localPosition, size),
            child: CustomPaint(
              size: size,
              painter: _SaturationValuePainter(color),
            ),
          );
        },
      ),
    );
  }
}

class _HuePicker extends StatelessWidget {
  const _HuePicker({required this.color, required this.onChanged});

  final HSVColor color;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) {
    void update(Offset position, double width) =>
        onChanged(color.withHue((position.dx / width).clamp(0.0, 1.0) * 360));

    return Semantics(
      label: AppLocalizations.of(context).themeColorHue,
      child: LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          key: const ValueKey('hue-picker'),
          onTapDown: (details) =>
              update(details.localPosition, constraints.maxWidth),
          onPanUpdate: (details) =>
              update(details.localPosition, constraints.maxWidth),
          child: CustomPaint(
            size: Size(constraints.maxWidth, 28),
            painter: _HuePainter(color.hue),
          ),
        ),
      ),
    );
  }
}

class _SaturationValuePainter extends CustomPainter {
  const _SaturationValuePainter(this.color);

  final HSVColor color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = BorderRadius.circular(18);
    canvas.save();
    canvas.clipRRect(radius.toRRect(rect));
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white,
            HSVColor.fromAHSV(1, color.hue, 1, 1).toColor(),
          ],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );
    canvas.restore();
    _paintThumb(
      canvas,
      Offset(color.saturation * size.width, (1 - color.value) * size.height),
      color.toColor(),
    );
  }

  @override
  bool shouldRepaint(_SaturationValuePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _HuePainter extends CustomPainter {
  const _HuePainter(this.hue);

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Colors.red,
            Colors.yellow,
            Colors.green,
            Colors.cyan,
            Colors.blue,
            Colors.purple,
            Colors.red,
          ],
        ).createShader(rect),
    );
    _paintThumb(
      canvas,
      Offset((hue / 360) * size.width, size.height / 2),
      HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
      radius: 10,
    );
  }

  @override
  bool shouldRepaint(_HuePainter oldDelegate) => oldDelegate.hue != hue;
}

void _paintThumb(
  Canvas canvas,
  Offset center,
  Color color, {
  double radius = 11,
}) {
  canvas.drawCircle(center, radius + 2, Paint()..color = Colors.white);
  canvas.drawCircle(center, radius, Paint()..color = color);
  canvas.drawCircle(
    center,
    radius + 2,
    Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1,
  );
}
