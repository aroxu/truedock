import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('presentation code contains no direct user-facing prose literals', () {
    final roots = [Directory('lib/core/widgets'), Directory('lib/features')];
    final violations = <String>[];
    final userFacing = RegExp(
      r'''(?:Text|SelectableText)\(\s*(?:const\s+)?['\"]([^'\"]*[A-Za-z가-힣][^'\"]*)['\"]''',
      multiLine: true,
    );
    final namedUserFacing = RegExp(
      r'''(?:text|title|subtitle|label|labelText|helperText|hintText|tooltip|message|errorMessage):\s*(?:const\s+)?['\"]([^'\"]*[A-Za-z가-힣][^'\"]*)['\"]''',
      multiLine: true,
    );
    final semanticsLabel = RegExp(
      r'''Semantics\([\s\S]{0,180}?label:\s*(?:const\s+)?['\"]([^'\"]*[A-Za-z가-힣][^'\"]*)['\"]''',
      multiLine: true,
    );
    final allowed = RegExp(
      r'^(?:CPU|RAM|SMB|NFS|iSCSI|WebShare|Docker Compose 구성|https://|manual-|auto-|%U|admin|[0-9A-F]{6})',
    );

    for (final root in roots) {
      if (!root.existsSync()) continue;
      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (!entity.path.contains('/presentation/') &&
            !entity.path.contains('/core/widgets/')) {
          continue;
        }
        final source = entity.readAsStringSync();
        for (final pattern in [userFacing, namedUserFacing, semanticsLabel]) {
          for (final match in pattern.allMatches(source)) {
            final literal = match
                .group(1)!
                .replaceAll(RegExp(r'\$\{[^}]+\}'), '')
                .replaceAll(RegExp(r'\$[A-Za-z_][A-Za-z0-9_]*'), '')
                .replaceAll(r'\n', ' ')
                .trim();
            if (allowed.hasMatch(literal) ||
                !RegExp(r'[A-Za-z가-힣]{2,}').hasMatch(literal)) {
              continue;
            }
            final line =
                '\n'.allMatches(source.substring(0, match.start)).length + 1;
            violations.add('${entity.path}:$line: $literal');
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Move visible prose into app_en.arb/app_ko.arb and render it through '
          'AppLocalizations. Identifiers, paths, protocols, and units may be '
          'added to the narrow allow-list when they are not language.',
    );
  });
}
