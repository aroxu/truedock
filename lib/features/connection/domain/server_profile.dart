import 'dart:convert';

import 'package:crypto/crypto.dart';

class ServerProfile {
  const ServerProfile({
    required this.name,
    required this.baseUri,
    this.pinnedCertificateSha256,
    this.profileId,
  });

  final String name;
  final Uri baseUri;
  final String? pinnedCertificateSha256;
  final String? profileId;

  String get id =>
      profileId ?? sha256.convert(utf8.encode(baseUri.toString())).toString();

  Uri get websocketUri => baseUri.replace(
    scheme: 'wss',
    path: '/api/current',
    query: null,
    fragment: null,
  );

  ServerProfile copyWith({
    String? name,
    Uri? baseUri,
    String? pinnedCertificateSha256,
  }) => ServerProfile(
    name: name ?? this.name,
    baseUri: baseUri ?? this.baseUri,
    profileId: id,
    pinnedCertificateSha256:
        pinnedCertificateSha256 ?? this.pinnedCertificateSha256,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'base_uri': baseUri.toString(),
    if (pinnedCertificateSha256 != null)
      'pinned_certificate_sha256': pinnedCertificateSha256,
  };

  factory ServerProfile.fromJson(Map<String, dynamic> json) {
    final uri = Uri.tryParse(json['base_uri'] as String? ?? '');
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const FormatException('Saved server profile is invalid.');
    }
    return ServerProfile(
      name: json['name'] as String? ?? uri.host,
      baseUri: uri,
      profileId: json['id'] as String?,
      pinnedCertificateSha256: json['pinned_certificate_sha256'] as String?,
    );
  }

  static ServerProfile parse({required String name, required String address}) {
    final input = address.trim();
    final parsed = Uri.tryParse(
      input.contains('://') ? input : 'https://$input',
    );
    if (parsed == null || parsed.host.isEmpty) {
      throw const FormatException('Enter a valid TrueNAS address.');
    }
    if (parsed.scheme != 'https' && parsed.scheme != 'wss') {
      throw const FormatException('TrueDock requires HTTPS/WSS.');
    }
    final normalized = parsed.replace(
      scheme: 'https',
      path: '',
      query: null,
      fragment: null,
    );
    return ServerProfile(
      name: name.trim().isEmpty ? parsed.host : name.trim(),
      baseUri: normalized,
    );
  }
}
