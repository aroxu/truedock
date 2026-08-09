import 'package:flutter/foundation.dart';

/// Stable validation codes for iSCSI CHAP credential sheets. The presentation
/// layer maps each code to a localized message.
enum IscsiAuthValidationCode {
  userRequired,
  secretRequired,
  secretMismatch,
  peerUserRequired,
  peerSecretRequired,
  peerSecretMismatch,
}

/// Mutable CHAP credential configuration collected by [IscsiAuthSheet].
///
/// Secrets are write-only: when editing an existing entry, a null [secret]
/// means "leave the server-side secret unchanged." The sheet only ever sends
/// a secret the user just typed; it never holds or re-sends an existing one.
@immutable
class IscsiAuthConfiguration {
  const IscsiAuthConfiguration({
    required this.tag,
    required this.user,
    required this.secret,
    required this.peerUser,
    required this.peerSecret,
  });

  /// Numeric tag identifying the credential within the target group.
  final int tag;

  /// The CHAP username initiators must present.
  final String user;

  /// The CHAP secret. Null when editing and leaving the existing secret in
  /// place. Required on create.
  final String? secret;

  /// The peer username for mutual CHAP. Empty for one-way CHAP.
  final String peerUser;

  /// The peer secret for mutual CHAP. Null when editing and leaving the
  /// existing peer secret in place.
  final String? peerSecret;

  bool get isMutual => peerUser.isNotEmpty;

  /// Payload for `iscsi.auth.create`.
  Map<String, Object?> toCreateApiJson() => {
    'tag': tag,
    'user': user,
    'secret': secret,
    if (peerUser.isNotEmpty) 'peeruser': peerUser,
    if (peerSecret != null && peerSecret!.isNotEmpty) 'peersecret': peerSecret,
  };

  /// Payload for `iscsi.auth.update`. Secrets are omitted when left blank so
  /// the server keeps the existing value.
  Map<String, Object?> toUpdateApiJson() => {
    'tag': tag,
    'user': user,
    if (secret != null && secret!.isNotEmpty) 'secret': secret,
    if (peerUser.isNotEmpty) 'peeruser': peerUser,
    if (peerSecret != null && peerSecret!.isNotEmpty) 'peersecret': peerSecret,
  };
}
