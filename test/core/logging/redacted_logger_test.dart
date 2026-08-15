import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/logging/redacted_logger.dart';

void main() {
  group('RedactedLogger.redact', () {
    test('redacts a quoted password field', () {
      const input =
          'login failed for body {"username":"admin","password":"hunter2"}';
      final out = RedactedLogger.redact(input);
      expect(out, contains('password=[redacted]'));
      expect(out, isNot(contains('hunter2')));
      expect(out, contains('admin'));
    });

    test('redacts an api_key in key=value form', () {
      const input = 'api_key=abc123def456... sent over wss';
      final out = RedactedLogger.redact(input);
      expect(out, contains('api_key=[redacted]'));
      expect(out, isNot(contains('abc123def456')));
    });

    test('redacts a long hex encryption key', () {
      const hex =
          'a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90';
      final out = RedactedLogger.redact('unlock key=$hex done');
      expect(out, isNot(contains(hex)));
      // The field-name rule catches `key=` first, which is the stronger
      // guarantee: the value is redacted regardless of its shape.
      expect(out, contains('key=[redacted]'));
    });

    test('redacts a long hex value that has no field name', () {
      const hex =
          'a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90';
      final out = RedactedLogger.redact('recovered $hex from payload');
      expect(out, isNot(contains(hex)));
      expect(out, contains('[redacted:'));
    });

    test('redacts every secret-bearing field TrueDock sends', () {
      // Regression guard: `key` (pool.dataset.unlock) and `encryption_salt`
      // (cloudsync) both leaked in plaintext before the suffix-based rule.
      const fields = [
        'password',
        'passphrase',
        'secret',
        'peersecret',
        'api_key',
        'hex_key',
        'private_key',
        'key',
        'encryption_password',
        'encryption_salt',
        'otp_token',
        'session',
        // mail.update sends the SMTP password as a bare `pass`, which the
        // suffix rule missed: it does not end in any of the words above, so it
        // was written to logs verbatim.
        'pass',
        'smtp_pass',
        'bindpw',
        // SNMP v1/v2c authenticates with the community string, so it is a
        // shared secret even though its name does not say so.
        'community',
        'v3_password',
        'v3_privpassphrase',
        // Alert-service credentials. `aws_access_key_id` is the one that got
        // through: it ends in `_id`, not in any secret-sounding word.
        'aws_access_key_id',
        'aws_secret_access_key',
        'bot_token',
        'service_key',
        'routing_key',
        'v3_authkey',
        'v3_privkey',
      ];
      for (final field in fields) {
        final out = RedactedLogger.redact('{"$field": "SuperSecretValue1"}');
        expect(
          out,
          isNot(contains('SuperSecretValue1')),
          reason: '$field leaked its value into the log',
        );
        expect(out, contains('$field=[redacted]'), reason: 'for field $field');
      }
    });

    test('does not redact short hex or normal words', () {
      const input = 'pool tank with 12 disks and 8 errors';
      final out = RedactedLogger.redact(input);
      expect(out, input);
    });

    test('the pass rule does not swallow ordinary field names', () {
      // `pass` and `pw` are short enough to appear inside unrelated names, so
      // over-redaction would hide operational detail. They must match as whole
      // names or suffixes, not as substrings.
      for (final field in [
        'passed',
        'bypass_count',
        'password_age_days',
        // `key_id` must not swallow ordinary identifiers.
        'pool_id',
        'job_id',
      ]) {
        final out = RedactedLogger.redact('{"$field": "17"}');
        expect(
          out,
          contains('17'),
          reason: '$field is not a secret and must survive redaction',
        );
      }
    });

    test('redacts URL userinfo', () {
      const input = 'connecting wss://admin:secret@nas.local/api/current';
      final out = RedactedLogger.redact(input);
      expect(out, contains('wss://[redacted]@nas.local'));
      expect(out, isNot(contains('admin:secret@')));
    });

    test('redacts a base64-ish token of 32+ chars', () {
      const token =
          'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
      final out = RedactedLogger.redact('token $token');
      expect(out, isNot(contains(token)));
      expect(out, contains('[redacted:'));
    });

    test('leaves a short token visible', () {
      const input = 'job 12 status RUNNING';
      final out = RedactedLogger.redact(input);
      expect(out, input);
    });
  });

  group('RedactedLogger writing', () {
    test('routes entries through the sink and the stream', () async {
      final sink = RecordingLogSink();
      final logger = RedactedLogger(sink: sink);
      final received = <RedactedLogEntry>[];
      final sub = logger.stream.listen(received.add);

      logger.error(
        'login failed password="s3cret" for 64-hex-key',
        category: 'auth',
        errorType: 'TrueNasRpcException',
      );

      await Future<void>.delayed(Duration.zero);

      expect(sink.entries, hasLength(1));
      expect(received, hasLength(1));
      final entry = sink.entries.single;
      expect(entry.severity, LogSeverity.error);
      expect(entry.category, 'auth');
      expect(entry.errorType, 'TrueNasRpcException');
      expect(entry.message, isNot(contains('s3cret')));
      expect(entry.message, contains('[redacted]'));
      expect(entry.toString(), contains('ERROR'));
      expect(entry.toString(), contains('[auth]'));

      await sub.cancel();
    });

    test('redaction applies to every severity', () {
      final sink = RecordingLogSink();
      final logger = RedactedLogger(sink: sink);

      logger.debug('password="d1"');
      logger.info('password="d2"');
      logger.warning('password="d3"');
      logger.error('password="d4"');

      expect(sink.entries.map((e) => e.severity), [
        LogSeverity.debug,
        LogSeverity.info,
        LogSeverity.warning,
        LogSeverity.error,
      ]);
      for (final entry in sink.entries) {
        expect(entry.message, contains('password=[redacted]'));
      }
    });

    test('RecordingLogSink clear empties the list', () {
      final sink = RecordingLogSink();
      final logger = RedactedLogger(sink: sink);
      logger.info('hello');
      expect(sink.entries, hasLength(1));
      sink.clear();
      expect(sink.entries, isEmpty);
    });
  });
}
