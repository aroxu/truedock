import 'package:meta/meta.dart';

/// Transport security for the outgoing SMTP connection.
enum MailSecurity { plain, ssl, tls }

extension MailSecurityApi on MailSecurity {
  String get apiValue => switch (this) {
    MailSecurity.plain => 'PLAIN',
    MailSecurity.ssl => 'SSL',
    MailSecurity.tls => 'TLS',
  };

  static MailSecurity fromApi(Object? value) => switch (value) {
    'SSL' => MailSecurity.ssl,
    'TLS' => MailSecurity.tls,
    _ => MailSecurity.plain,
  };
}

/// Stable codes for mail validation failures.
enum MailValidationCode {
  fromAddressRequired,
  fromAddressInvalid,
  serverRequired,
  portRange,
  usernameWithoutPassword,
}

@immutable
class MailValidationIssue {
  const MailValidationIssue(this.code, {this.bound});
  final MailValidationCode code;
  final int? bound;
}

/// `mail.config`: how TrueNAS sends alert email.
///
/// The SMTP password is deliberately absent. `mail.config` does not return it,
/// and TrueDock never holds it beyond the single update call that sets it, so
/// there is nothing here for a log, a screenshot, or a state dump to leak.
@immutable
class MailConfiguration {
  const MailConfiguration({
    required this.fromEmail,
    required this.fromName,
    required this.outgoingServer,
    required this.port,
    required this.security,
    this.smtpAuthentication = false,
    this.username,
    this.usesOauth = false,
  });

  factory MailConfiguration.fromJson(Map<String, dynamic> json) {
    final oauth = json['oauth'];
    return MailConfiguration(
      fromEmail: json['fromemail'] is String ? json['fromemail'] as String : '',
      fromName: json['fromname'] is String ? json['fromname'] as String : '',
      outgoingServer: json['outgoingserver'] is String
          ? json['outgoingserver'] as String
          : '',
      port: json['port'] is int ? json['port'] as int : 25,
      security: MailSecurityApi.fromApi(json['security']),
      smtpAuthentication: json['smtp'] == true,
      username: json['user'] is String && (json['user'] as String).isNotEmpty
          ? json['user'] as String
          : null,
      // An OAuth-configured server is driven from the web UI; TrueDock shows
      // that it is in use rather than offering a partial editor that would
      // clear it.
      usesOauth: oauth is Map && oauth.isNotEmpty,
    );
  }

  final String fromEmail;
  final String fromName;
  final String outgoingServer;
  final int port;
  final MailSecurity security;

  /// Whether the server authenticates to SMTP with a username and password.
  final bool smtpAuthentication;
  final String? username;
  final bool usesOauth;

  bool get isConfigured => fromEmail.isNotEmpty && outgoingServer.isNotEmpty;
}

/// A mail settings edit, for `mail.update`.
///
/// Only changed fields are emitted, so an untouched password is never resent —
/// and because `mail.config` never returns it, resending would send the wrong
/// value rather than the current one.
@immutable
class MailConfigurationEdit {
  const MailConfigurationEdit({
    this.fromEmail,
    this.fromName,
    this.outgoingServer,
    this.port,
    this.security,
    this.smtpAuthentication,
    this.username,
    this.password,
  });

  final String? fromEmail;
  final String? fromName;
  final String? outgoingServer;
  final int? port;
  final MailSecurity? security;
  final bool? smtpAuthentication;
  final String? username;

  /// Set only when the user typed a new password. Never read back from the
  /// server and never persisted by TrueDock.
  final String? password;

  List<MailValidationIssue> validate() {
    final issues = <MailValidationIssue>[];
    final from = fromEmail;
    if (from != null) {
      if (from.trim().isEmpty) {
        issues.add(
          const MailValidationIssue(MailValidationCode.fromAddressRequired),
        );
      } else if (!_looksLikeEmail(from.trim())) {
        issues.add(
          const MailValidationIssue(MailValidationCode.fromAddressInvalid),
        );
      }
    }
    if (outgoingServer != null && outgoingServer!.trim().isEmpty) {
      issues.add(const MailValidationIssue(MailValidationCode.serverRequired));
    }
    // The server refuses an empty `fromemail` outright, so clearing it has to be
    // caught here rather than surfaced as a middleware validation dump.
    if (from != null && from.trim().isEmpty) {
      // Already reported above as fromAddressRequired; nothing to add.
    }
    final portValue = port;
    if (portValue != null && (portValue < 1 || portValue > 65535)) {
      issues.add(
        const MailValidationIssue(MailValidationCode.portRange, bound: 65535),
      );
    }
    return issues;
  }

  /// Validates against the current settings, which is needed for rules that
  /// depend on state the edit does not carry.
  List<MailValidationIssue> validateAgainst(MailConfiguration baseline) {
    final issues = validate();
    // Enabling SMTP auth with a username but no password — and none already
    // stored, which the app cannot see — would silently fail to authenticate.
    final wantsAuth = smtpAuthentication ?? baseline.smtpAuthentication;
    final user = username ?? baseline.username;
    final hadUser = baseline.username != null;
    if (wantsAuth &&
        (user?.isNotEmpty ?? false) &&
        (password == null || password!.isEmpty) &&
        !hadUser) {
      issues.add(
        const MailValidationIssue(MailValidationCode.usernameWithoutPassword),
      );
    }
    return issues;
  }

  /// Payload for `mail.update`.
  ///
  /// [current] carries the existing settings so `fromemail` can always be
  /// included. The server rejects the whole call with "this field is required"
  /// when `fromemail` is absent *and* not already stored, so a genuinely partial
  /// update is impossible on a server where mail was never configured. It also
  /// refuses an empty `fromemail`, so once set it cannot be unset from here.
  Map<String, Object?> toApiJsonFor(MailConfiguration current) {
    final payload = toApiJson();
    if (!payload.containsKey('fromemail') && current.fromEmail.isNotEmpty) {
      // Already stored, so a partial update is accepted as-is.
      return payload;
    }
    if (!payload.containsKey('fromemail')) {
      payload['fromemail'] = current.fromEmail;
    }
    return payload;
  }

  Map<String, Object?> toApiJson() => <String, Object?>{
    if (fromEmail != null) 'fromemail': fromEmail!.trim(),
    if (fromName != null) 'fromname': fromName!.trim(),
    if (outgoingServer != null) 'outgoingserver': outgoingServer!.trim(),
    if (port != null) 'port': port,
    if (security != null) 'security': security!.apiValue,
    if (smtpAuthentication != null) 'smtp': smtpAuthentication,
    if (username != null) 'user': username!.isEmpty ? null : username,
    if (password != null) 'pass': password,
  };

  bool get isEmpty => toApiJson().isEmpty;

  /// True when this edit carries a secret, so callers can avoid logging it.
  bool get carriesSecret => password != null && password!.isNotEmpty;
}

bool _looksLikeEmail(String value) =>
    RegExp(r'^[^@\s]+@[^@\s.]+(\.[^@\s.]+)+$').hasMatch(value);
