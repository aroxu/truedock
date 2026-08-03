import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../security/tls_certificate_service.dart';
import '../../features/connection/domain/auth_credential.dart';
import '../../features/connection/domain/server_capabilities.dart';
import '../../features/connection/domain/server_profile.dart';
import '../../features/connection/domain/system_info.dart';

typedef WebSocketConnector =
    Future<WebSocketChannel> Function(ServerProfile profile);

const _firmwareUploadBytesPerSecond = 10 * 1024 * 1024;

/// Applies backpressure so a firmware upload cannot saturate the NAS link.
///
/// The delay is based on total bytes emitted rather than on individual chunk
/// delays, so scheduler jitter does not accumulate and make a long upload
/// progressively slower.
Stream<List<int>> limitByteRate(
  Stream<List<int>> source, {
  required int bytesPerSecond,
}) async* {
  if (bytesPerSecond <= 0) {
    throw ArgumentError.value(bytesPerSecond, 'bytesPerSecond');
  }
  final stopwatch = Stopwatch()..start();
  var emittedBytes = 0;
  await for (final chunk in source) {
    emittedBytes += chunk.length;
    final targetElapsed = Duration(
      microseconds:
          emittedBytes * Duration.microsecondsPerSecond ~/ bytesPerSecond,
    );
    final delay = targetElapsed - stopwatch.elapsed;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    yield chunk;
  }
}

class TrueNasJsonRpcClient {
  TrueNasJsonRpcClient({
    WebSocketConnector? connector,
    SecureWebSocketTransport? transport,
  }) : this._(connector, transport ?? SecureWebSocketTransport());

  TrueNasJsonRpcClient._(this._connector, this._transport);

  final SecureWebSocketTransport _transport;
  final WebSocketConnector? _connector;
  final Map<int, Completer<Object?>> _pending = {};

  /// Requests admitted to the socket but not yet answered.
  ///
  /// TrueNAS rejects the 21st concurrent call on a connection with
  /// "Maximum number of concurrent calls (20) has exceeded". Overview alone
  /// fans out more than twenty section reads, so the limit has to be enforced
  /// here rather than by counting parallelism at each call site: any screen
  /// that adds a section would otherwise silently break a different screen
  /// that happens to load at the same time.
  static const _maxConcurrentCalls = 16;
  int _inFlight = 0;
  final _admissionQueue = <Completer<void>>[];
  final StreamController<RpcNotification> _notifications =
      StreamController<RpcNotification>.broadcast();
  final StreamController<ConnectionLoss> _connectionLoss =
      StreamController<ConnectionLoss>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<Object?>? _subscription;
  int _nextId = 1;

  Stream<RpcNotification> get notifications => _notifications.stream;

  /// Emits whenever the transport goes away without [close] being called.
  ///
  /// The client cannot decide what a lost connection means for the user, so it
  /// reports the loss and lets the connection controller move the app out of
  /// its connected state. Without this, every screen keeps rendering as though
  /// the server were still reachable.
  Stream<ConnectionLoss> get connectionLost => _connectionLoss.stream;

  bool get isConnected => _channel != null;

  Future<void> connect(ServerProfile profile) async {
    if (profile.websocketUri.scheme != 'wss') {
      throw const TrueNasRpcException(
        code: -1,
        message: 'TrueDock requires a secure WSS connection.',
      );
    }
    await close();
    WebSocketChannel channel;
    if (_connector != null) {
      channel = await _connector.call(profile);
      _lastVerifiedCertificate = null;
    } else {
      final connection = await _transport.connect(profile);
      channel = connection.channel;
      _lastVerifiedCertificate = connection.certificate;
    }
    _channel = channel;
    _subscription = channel.stream.listen(
      _handleMessage,
      onError: _handleSocketError,
      onDone: _handleSocketClosed,
      cancelOnError: false,
    );
  }

  /// The certificate verified by the most recent [connect] call, when the
  /// transport reported one. Lets callers warn about an expiring or expired
  /// certificate right after a successful connection.
  TlsCertificateIdentity? _lastVerifiedCertificate;
  TlsCertificateIdentity? get lastVerifiedCertificate =>
      _lastVerifiedCertificate;

  Future<ServerProfile> trustCertificate(
    ServerProfile profile,
    TlsCertificateIdentity certificate,
  ) => _transport.trust(profile, certificate);

  Future<Object?> call(
    String method, {
    List<Object?> params = const [],
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final channel = _channel;
    if (channel == null) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'Not connected to a TrueNAS server.',
      );
    }

    await _acquireSlot();
    // The socket can go away while a call waits for a slot.
    final live = _channel;
    if (live == null) {
      _releaseSlot();
      throw const TrueNasRpcException(
        code: -1,
        message: 'Not connected to a TrueNAS server.',
      );
    }

    final id = _nextId++;
    final completer = Completer<Object?>();
    _pending[id] = completer;
    live.sink.add(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': id,
        'method': method,
        'params': params,
      }),
    );

    try {
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      throw TrueNasRpcException(
        code: -1,
        message: 'TrueNAS did not answer $method in time.',
      );
    } finally {
      _pending.remove(id);
      _releaseSlot();
    }
  }

  /// Waits until the connection has room for another in-flight call.
  ///
  /// Kept strictly FIFO so a burst of section reads cannot starve a later
  /// user-initiated mutation behind an unbounded queue of refreshes.
  Future<void> _acquireSlot() {
    if (_inFlight < _maxConcurrentCalls) {
      _inFlight++;
      return Future<void>.value();
    }
    final waiter = Completer<void>();
    _admissionQueue.add(waiter);
    return waiter.future;
  }

  void _releaseSlot() {
    if (_admissionQueue.isNotEmpty) {
      // Hand the slot straight to the next waiter instead of decrementing,
      // so the count never dips and lets an extra call through.
      _admissionQueue.removeAt(0).complete();
      return;
    }
    if (_inFlight > 0) _inFlight--;
  }

  Future<AuthResult> authenticate(AuthCredential credential) async {
    final result = await call(
      'auth.login_ex',
      params: [credential.toLoginPayload()],
    );
    return AuthResult.fromJson(_asObject(result, 'auth.login_ex'));
  }

  /// Ends the session on the server via `auth.logout`.
  ///
  /// Closing the socket alone leaves the authenticated session alive on the
  /// server until it times out, so a "sign out" that only drops the transport
  /// is not really a sign out. Failures are swallowed: the user asked to leave,
  /// and the socket is closed immediately afterwards regardless.
  Future<void> logout() async {
    if (_channel == null) return;
    try {
      await call('auth.logout', timeout: const Duration(seconds: 5));
    } on Object {
      // An unreachable or already-expired session cannot be logged out; the
      // local teardown in close() still runs.
    }
  }

  /// Reads the signed-in account name via `auth.me`.
  ///
  /// `auth.login_ex` normally carries the account in `user_info.pw_name`, but
  /// that object is not guaranteed: an API-key login can return `SUCCESS`
  /// without it. This is the fallback so the saved-server list never shows a
  /// blank account. Returns null when the server cannot answer, because a
  /// missing label must not fail an otherwise good connection.
  Future<String?> currentUserName() async {
    try {
      final result = await call('auth.me', timeout: const Duration(seconds: 5));
      if (result is Map<String, dynamic>) {
        final name = result['pw_name'] ?? result['username'];
        if (name is String && name.isNotEmpty) return name;
      }
      return null;
    } on Object {
      return null;
    }
  }

  Future<AuthResult> continueWithOtp(String otp) async {
    final result = await call(
      'auth.login_ex_continue',
      params: [
        {
          'mechanism': 'OTP_TOKEN',
          'otp_token': otp,
          'login_options': {'user_info': true},
        },
      ],
    );
    return AuthResult.fromJson(_asObject(result, 'auth.login_ex_continue'));
  }

  Future<SystemInfo> getSystemInfo() async {
    final result = await call('system.info');
    return SystemInfo.fromJson(_asObject(result, 'system.info'));
  }

  /// Uploads a manual TrueNAS update through the authenticated job pipe.
  ///
  /// The HTTP endpoint cannot reuse the WebSocket session directly. TrueNAS's
  /// own UI generates a single-use token and sends it as `auth_token`; doing
  /// the same keeps passwords and API keys out of the upload request.
  Future<int> uploadSystemUpdate({
    required ServerProfile profile,
    required String filePath,
    required String fileName,
    void Function(int sent, int total)? onProgress,
  }) async {
    final expectedCertificate = await SecureHttpCertificatePolicy().verify(
      profile,
    );
    final token = await call(
      'auth.generate_token',
      params: const [300, <String, Object?>{}, true, true],
    );
    if (token is! String || token.isEmpty) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'TrueNAS did not issue an upload token.',
      );
    }

    final dio = Dio(BaseOptions(baseUrl: profile.baseUri.toString()));
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        if (!expectedCertificate.isTrustedBySystem) {
          client.badCertificateCallback = (presented, host, port) {
            final fingerprint = sha256.convert(presented.der).toString();
            return host == profile.baseUri.host &&
                port ==
                    (profile.baseUri.hasPort ? profile.baseUri.port : 443) &&
                fingerprint.toLowerCase() ==
                    expectedCertificate.sha256.toLowerCase();
          };
        }
        return client;
      },
    );

    try {
      final uploadFile = File(filePath);
      if (!await uploadFile.exists()) {
        throw TrueNasRpcException(
          code: -1,
          message:
              'The selected firmware file is no longer available: $fileName',
        );
      }
      final fileLength = await uploadFile.length();
      if (fileLength <= 0) {
        throw TrueNasRpcException(
          code: -1,
          message: 'The selected firmware file is empty: $fileName',
        );
      }
      final response = await dio.post<Object?>(
        '/_upload',
        queryParameters: {'auth_token': token},
        data: FormData.fromMap({
          'data': jsonEncode({
            'method': 'update.file',
            'params': [
              // Match the 25.10 WebUI upload request exactly. `resume` is only
              // sent on a later RPC call when the server returns EAGAIN and
              // the user explicitly accepts the warning.
              {'destination': null},
            ],
          }),
          'file': MultipartFile.fromStream(
            () => limitByteRate(
              uploadFile.openRead(),
              bytesPerSecond: _firmwareUploadBytesPerSecond,
            ),
            fileLength,
            filename: fileName,
            contentType: DioMediaType('application', 'octet-stream'),
          ),
        }),
        onSendProgress: onProgress,
        options: Options(contentType: 'multipart/form-data'),
      );
      final body = response.data;
      final jobId = body is Map ? body['job_id'] : null;
      if (jobId is! int) {
        throw const TrueNasRpcException(
          code: -1,
          message: 'TrueNAS did not return an update job.',
        );
      }
      return jobId;
    } on DioException catch (error) {
      final response = error.response;
      final detail = _uploadFailureDetail(error);
      throw TrueNasRpcException(
        code: response?.statusCode ?? -1,
        message: detail,
      );
    } on TrueNasRpcException {
      rethrow;
    } on FileSystemException catch (error) {
      throw TrueNasRpcException(
        code: error.osError?.errorCode ?? -1,
        message:
            'The selected firmware file could not be read: '
            '${error.message}${error.osError == null ? '' : ' (${error.osError})'}',
      );
    } on Object catch (error) {
      throw TrueNasRpcException(
        code: -1,
        message:
            'The firmware upload could not start: '
            '${error.runtimeType}: $error',
      );
    } finally {
      dio.close(force: true);
    }
  }

  String _uploadFailureDetail(DioException error) {
    final body = error.response?.data;
    if (body is Map) {
      for (final key in const ['message', 'error', 'reason', 'detail']) {
        final value = body[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
      final encoded = jsonEncode(body);
      if (encoded != '{}') return encoded;
    }
    if (body is String) {
      final plain = body
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (plain.isNotEmpty) return plain;
    }

    final nested = error.error;
    final nestedDetail = nested == null
        ? null
        : '${nested.runtimeType}: $nested';
    return switch (error.type) {
      DioExceptionType.connectionTimeout =>
        'Timed out while connecting to the TrueNAS upload endpoint.',
      DioExceptionType.sendTimeout =>
        'The firmware upload timed out while sending the file.',
      DioExceptionType.receiveTimeout =>
        'TrueNAS did not answer after receiving the firmware file.',
      DioExceptionType.connectionError =>
        'The connection to TrueNAS was interrupted during the firmware upload: ${error.message ?? 'connection error'}',
      DioExceptionType.badCertificate =>
        'TrueNAS presented an untrusted certificate during the firmware upload.',
      DioExceptionType.cancel => 'The firmware upload was cancelled.',
      _ => _unknownUploadFailureDetail(error, nestedDetail),
    };
  }

  String _unknownUploadFailureDetail(DioException error, String? nestedDetail) {
    final parts = <String>[
      if (error.message?.trim().isNotEmpty == true) error.message!.trim(),
      ?nestedDetail,
      if (error.response?.statusCode case final status?) 'HTTP $status',
    ];
    return parts.isEmpty
        ? 'Unknown upload transport error (${error.type.name}).'
        : parts.join(' — ');
  }

  Future<ServerCapabilities> discoverCapabilities(SystemInfo systemInfo) async {
    final results = await Future.wait([
      call('system.product_type'),
      call('core.get_methods', params: const [null, 'WS']),
    ]);
    final capabilities = ServerCapabilities.fromDiscovery(
      systemInfo: systemInfo,
      productType: results[0],
      methods: results[1],
    );
    capabilities.validateForTrueDock();
    return capabilities;
  }

  Future<void> close() async {
    final subscription = _subscription;
    final channel = _channel;
    _subscription = null;
    _channel = null;
    await subscription?.cancel();
    await channel?.sink.close();
    _failPending(
      const TrueNasRpcException(code: -1, message: 'Connection closed.'),
    );
  }

  void _handleMessage(Object? rawMessage) {
    try {
      final decoded = jsonDecode(rawMessage as String);
      if (decoded is! Map<String, dynamic>) return;

      final id = decoded['id'];
      if (id is int) {
        final completer = _pending[id];
        if (completer == null || completer.isCompleted) return;
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          completer.completeError(TrueNasRpcException.fromJson(error));
        } else {
          completer.complete(decoded['result']);
        }
        return;
      }

      final method = decoded['method'];
      if (method is String) {
        _notifications.add(
          RpcNotification(method: method, params: decoded['params']),
        );
      }
    } on Object catch (error, stackTrace) {
      _notifications.addError(error, stackTrace);
    }
  }

  void _handleSocketError(Object error, StackTrace stackTrace) {
    _channel = null;
    _failPending(
      TrueNasRpcException(code: -1, message: 'WebSocket error: $error'),
    );
    _notifications.addError(error, stackTrace);
    _reportConnectionLoss('The connection to TrueNAS was interrupted.');
  }

  void _handleSocketClosed() {
    _channel = null;
    _failPending(
      const TrueNasRpcException(
        code: -1,
        message: 'The TrueNAS connection was closed.',
      ),
    );
    _reportConnectionLoss('The TrueNAS connection was closed.');
  }

  /// Announces an unexpected loss. [close] clears [_subscription] first, so a
  /// deliberate disconnect does not reach here and cannot be mistaken for a
  /// dropped socket.
  void _reportConnectionLoss(String message) {
    if (_subscription == null) return;
    _subscription = null;
    if (!_connectionLoss.isClosed) {
      _connectionLoss.add(ConnectionLoss(message));
    }
  }

  void _failPending(Object error) {
    for (final completer in _pending.values) {
      if (!completer.isCompleted) completer.completeError(error);
    }
    _pending.clear();
    // Calls still queued for an admission slot were never written to the
    // socket, so `_pending` does not hold them. Releasing them here is what
    // keeps a dropped connection from leaving them awaiting forever; each one
    // then fails on the null-channel check and surfaces as a connection error.
    final queued = List<Completer<void>>.of(_admissionQueue);
    _admissionQueue.clear();
    _inFlight = 0;
    for (final waiter in queued) {
      if (!waiter.isCompleted) waiter.complete();
    }
  }

  static Map<String, dynamic> _asObject(Object? value, String method) {
    if (value is Map<String, dynamic>) return value;
    throw TrueNasRpcException(
      code: -1,
      message: '$method returned an unexpected response.',
    );
  }
}

class RpcNotification {
  const RpcNotification({required this.method, this.params});

  final String method;
  final Object? params;
}

/// Reported when the transport goes away without a deliberate [close].
///
/// Carries a user-facing [message] so the connection controller can explain
/// the drop without inventing its own wording.
class ConnectionLoss {
  const ConnectionLoss(this.message);

  final String message;

  @override
  String toString() => 'ConnectionLoss($message)';
}

class TrueNasRpcException implements Exception {
  const TrueNasRpcException({
    required this.code,
    required this.message,
    this.reason,
    this.errorName,
  });

  factory TrueNasRpcException.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final details = data is Map<String, dynamic> ? data : null;
    return TrueNasRpcException(
      code: json['code'] is int ? json['code'] as int : -1,
      message: json['message'] as String? ?? 'TrueNAS API error',
      reason: details?['reason'] as String?,
      errorName: details?['errname'] as String?,
    );
  }

  final int code;
  final String message;
  final String? reason;
  final String? errorName;

  String get displayMessage => reason ?? message;

  @override
  String toString() => 'TrueNasRpcException($code, $displayMessage)';
}
