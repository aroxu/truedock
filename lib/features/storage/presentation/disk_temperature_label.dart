import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../resources/domain/server_resources.dart';

/// Shows a drive's temperature, judged against that drive's own thresholds.
///
/// A drive TrueNAS could not read renders nothing rather than a zero, which
/// would read as a very cold disk. Over-temperature is carried by text and
/// weight as well as colour, so the warning never depends on colour alone.
class DiskTemperatureLabel extends StatelessWidget {
  const DiskTemperatureLabel({required this.temperature, super.key});

  final DiskTemperature? temperature;

  @override
  Widget build(BuildContext context) {
    final reading = temperature;
    if (reading == null || !reading.isKnown) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final alarming = reading.isCritical || reading.isOverMaximum;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Text(
        '${reading.celsius}°C',
        semanticsLabel: alarming
            ? l10n.storageDiskTempOverLimit(reading.celsius!)
            : l10n.storageDiskTempNormal(reading.celsius!),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: alarming ? scheme.error : scheme.onSurfaceVariant,
          fontWeight: alarming ? FontWeight.w700 : null,
          // Aligned digits keep a column of temperatures scannable.
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
