import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Severity for [RedactedLogEntry].
enum LogSeverity { debug, info, warning, error }

/// A single redacted log entry. The [message] is already redacted by the
/// [RedactedLogger] before it reaches here, so sinks can store or forward it
/// without scrubbing it again.
@immutable
class RedactedLogEntry {
  const RedactedLogEntry({
    required this.severity,
    required this.message,
    required this.timestamp,
    this.category,
    this.errorType,
  });

  final LogSeverity severity;
  final String message;
  final DateTime timestamp;
  final String? category;
  final String? errorType;

  @override
  String toString() {
    final level = severity.name.toUpperCase();
    final cat = category == null ? "" : "[$category] ";
    return "${timestamp.toIso8601String()} $level $cat$message"
        "${errorType == null ? "" : " ($errorType)"}";
  }
}

/// Sink that observes redacted log entries. Tests inject a recording sink;
/// production wires the platform debugPrint (or a crash-reporter that has
/// been audited to reject raw secrets).
abstract class RedactedLogSink {
  void write(RedactedLogEntry entry);
}

class _DebugPrintLogSink implements RedactedLogSink {
  const _DebugPrintLogSink();
  @override
  void write(RedactedLogEntry entry) => debugPrint(entry.toString());
}

/// Central, redacted logger for TrueDock.
///
/// TrueDock never stores credentials, passphrases, API keys, tokens, server
/// passwords, or full addresses in logs. [redact] replaces any of these
/// substrings with [redacted] before the message is handed to a sink, so a
/// raw value can never reach a sink even if a caller forgets to scrub it.
///
/// The redactor is intentionally conservative: it matches common
/// key/password shapes (hex keys, base64-ish tokens, long secret-looking
/// runs) and the known TrueNAS API fields that carry secrets. It does not
/// attempt to parse structured payloads, because logging structured secrets
/// is itself a mistake; callers should log summaries, not raw request bodies.
class RedactedLogger {
  RedactedLogger({RedactedLogSink? sink})
    : _sink = sink ?? const _DebugPrintLogSink();

  final RedactedLogSink _sink;
  final StreamController<RedactedLogEntry> _stream =
      StreamController<RedactedLogEntry>.broadcast();

  Stream<RedactedLogEntry> get stream => _stream.stream;

  void debug(String message, {String? category}) =>
      _write(LogSeverity.debug, message, category);
  void info(String message, {String? category}) =>
      _write(LogSeverity.info, message, category);
  void warning(String message, {String? category, String? errorType}) =>
      _write(LogSeverity.warning, message, category, errorType: errorType);
  void error(String message, {String? category, String? errorType}) =>
      _write(LogSeverity.error, message, category, errorType: errorType);

  void _write(
    LogSeverity severity,
    String message,
    String? category, {
    String? errorType,
  }) {
    final entry = RedactedLogEntry(
      severity: severity,
      message: RedactedLogger.redact(message),
      timestamp: DateTime.now().toUtc(),
      category: category,
      errorType: errorType,
    );
    _sink.write(entry);
    _stream.add(entry);
  }

  /// Replaces secret-looking substrings in [input] with [redacted].
  ///
  /// Redacts:
  /// - JSON fields whose name ends in a secret-bearing word: password,
  ///   passphrase, secret, token, key, salt, otp, session, or the abbreviated
  ///   `pass`/`pw` forms, with or without a prefix. This covers `password`,
  ///   `encryption_password`, `peersecret`, `api_key`, `hex_key`,
  ///   `private_key`, the bare `key` used by `pool.dataset.unlock`,
  ///   `encryption_salt`, the bare `pass` that `mail.update` uses for the SMTP
  ///   password, and `community`, which is the shared secret SNMP v1/v2c
  ///   authenticates with despite not being named like one, and `key_id`, which
  ///   catches `aws_access_key_id` — half of an AWS credential pair, and the
  ///   only one of the two whose name ends in `_id` rather than in a
  ///   secret-sounding word. Handles both `"name": "value"` and `name=value`.
  /// - Long hex strings (32+) and long base64-ish tokens (32+), which are the
  ///   shapes TrueNAS uses for encryption keys, API keys, and session tokens.
  /// - The userinfo portion of a URL, if present.
  static String redact(String input) {
    var out = input;
    // Field-name redaction. Match an optional prefix followed by a
    // secret-bearing suffix so new fields are covered by shape rather than by
    // an exact allowlist; a missed secret is far worse than an over-redacted
    // ordinary field. Capture the whole field name (without surrounding
    // quotes) so the replacement is stable regardless of how the caller
    // formatted the pair. Use a double-quoted raw string so the inner single
    // quote in the character class does not terminate the literal.
    final fieldRegex = RegExp(
      // `pass` and `pw` are matched as whole field names or suffixes rather
      // than as substrings, so `mail.update`'s bare `pass` and an LDAP `bindpw`
      // are covered without redacting ordinary words that merely contain them.
      r"""["']?([a-z0-9_-]*(?:password|passphrase|secret|token|key|salt|otp|session|two[_-]?factor[_-]?code|pass|pw|community|key_id))["']?\s*[:=]\s*["']?[^"',}\s]+""",
      caseSensitive: false,
    );
    out = out.replaceAllMapped(fieldRegex, (m) {
      final name = m[1]!;
      return "$name=[redacted]";
    });
    out = out.replaceAllMapped(RegExp(r"\b[0-9a-fA-F]{32,}\b"), (m) {
      final v = m[0]!;
      return v.length >= 32 ? "[redacted:${v.length}h]" : v;
    });
    out = out.replaceAllMapped(RegExp(r"\b[A-Za-z0-9+/=_-]{32,}\b"), (m) {
      final v = m[0]!;
      return v.length >= 32 ? "[redacted:${v.length}c]" : v;
    });
    out = out.replaceAllMapped(
      RegExp(r"(wss?|https?)://[^/@:]+:[^/@]+@"),
      (m) => "${m[1]}://[redacted]@",
    );
    return out;
  }
}

/// Riverpod provider for the central logger. Override in tests with a
/// recording sink.
final redactedLoggerProvider = Provider<RedactedLogger>((ref) {
  return RedactedLogger();
});

/// A [RedactedLogSink] that records every entry in memory, for tests and for
/// the in-app diagnostics screen.
class RecordingLogSink implements RedactedLogSink {
  final List<RedactedLogEntry> entries = [];

  @override
  void write(RedactedLogEntry entry) => entries.add(entry);

  void clear() => entries.clear();
}
