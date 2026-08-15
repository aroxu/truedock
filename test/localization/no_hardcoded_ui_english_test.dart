import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('presentation widgets do not embed user-facing English literals', () {
    final roots = [
      Directory('lib/features'),
      Directory('lib/core/widgets'),
      Directory('lib/core/security'),
      Directory('lib/app'),
    ];
    final files = roots
        .expand((root) => root.listSync(recursive: true).whereType<File>())
        .where(
          (file) =>
              file.path.endsWith('.dart') &&
              (file.path.contains('/presentation/') ||
                  file.path.startsWith('lib/core/widgets/') ||
                  file.path.startsWith('lib/core/security/') ||
                  file.path.startsWith('lib/app/')),
        );
    final constructorLiteral = RegExp(
      r'''\b(?:const\s+)?(?:Text|SelectableText|TextSpan|Tooltip|SnackBar|Semantics)\s*\(\s*(?:const\s+)?[\'\"](?=[^\'\"\n]*[A-Za-z])''',
      multiLine: true,
    );
    final namedLiteral = RegExp(
      r'''\b(?:label|labelText|hintText|helperText|errorText|tooltip|semanticLabel|title|subtitle|content|message)\s*:\s*(?:const\s+)?[\'\"](?=[^\'\"\n]*[A-Za-z])''',
    );
    final allowedLiteral = RegExp(r'''(?:https?://|^[A-Z0-9_.:/%+ -]+$)''');
    final violations = <String>[];

    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        if (!constructorLiteral.hasMatch(line) &&
            !namedLiteral.hasMatch(line)) {
          continue;
        }
        final quoted = RegExp(r'''[\'\"]([^\'\"]*)[\'\"]''')
            .allMatches(line)
            .map((match) => match.group(1) ?? '')
            .map(
              (value) => value
                  .replaceAll(RegExp(r'\$\{[^}]*\}'), '')
                  .replaceAll(RegExp(r'\$[A-Za-z_]\w*'), ''),
            )
            .where((value) => RegExp('[A-Za-z]').hasMatch(value));
        if (quoted.isEmpty || quoted.every(allowedLiteral.hasMatch)) {
          continue;
        }
        violations.add('${file.path}:${index + 1}: ${line.trim()}');
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Move user-facing text into app_en.arb/app_ko.arb. '
          'Technical identifiers and server-provided values should be passed '
          'as data rather than embedded in widget copy.\n${violations.join('\n')}',
    );
  });

  test('presentation widgets do not expose raw exception strings', () {
    final roots = [
      Directory('lib/features'),
      Directory('lib/core/widgets'),
      Directory('lib/core/security'),
      Directory('lib/app'),
    ];
    final violations = <String>[];
    for (final file
        in roots
            .expand((root) => root.listSync(recursive: true).whereType<File>())
            .where(
              (file) =>
                  file.path.endsWith('.dart') &&
                  (file.path.contains('/presentation/') ||
                      file.path.startsWith('lib/core/widgets/') ||
                      file.path.startsWith('lib/core/security/') ||
                      file.path.startsWith('lib/app/')),
            )) {
      final lines = file.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        if (line.contains("'\$error'") ||
            line.contains('"\$error"') ||
            line.contains('error.toString()')) {
          violations.add('${file.path}:${index + 1}: ${line.trim()}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Convert client errors to DataMessage/ConnectionMessage codes or '
          'a localized generic failure before rendering.\n${violations.join('\n')}',
    );
  });
}
