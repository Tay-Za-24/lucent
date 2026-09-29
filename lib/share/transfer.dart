/// One-time send of the book over the local network (Wi-Fi).
///
/// The receiver runs a tiny HTTP server while its Receive screen is open and
/// shows a random 6-digit PIN. Both sides turn PIN + a fresh random salt
/// (from the receiver) into an AES-256 key with PBKDF2. The sender encrypts
/// the bundle with AES-GCM, so it is private and tamper-proof, and the PIN
/// itself never crosses the network. A wrong PIN simply fails to decrypt;
/// after 3 wrong tries, one transfer, or 5 minutes the server closes.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

const shareProtocol = 1;
const defaultIterations = 100000;
const maxBodyBytes = 64 * 1024 * 1024;
const maxPinAttempts = 3;

/// A problem the user should see.
class ShareException implements Exception {
  ShareException(this.message);
  final String message;
  @override
  String toString() => message;
}

final _aes = AesGcm.with256bits();
final _rng = Random.secure();

List<int> _randomBytes(int n) => List<int>.generate(n, (_) => _rng.nextInt(256));

String newPin() => _rng.nextInt(1000000).toString().padLeft(6, '0');

Future<SecretKey> deriveKey(String pin, List<int> salt, int iterations) =>
    Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256)
        .deriveKey(secretKey: SecretKey(utf8.encode(pin)), nonce: salt);

// Different labels for each direction, so a message can't be replayed back.
List<int> _aad(String label, List<int> salt) => [...utf8.encode('lucent/$shareProtocol/$label'), ...salt];

/// Encrypts [value] (JSON, gzipped) into a JSON-safe map.
Future<Map<String, String>> seal(SecretKey key, String label, List<int> salt, Object? value) async {
  final box = await _aes.encrypt(
    gzip.encode(utf8.encode(jsonEncode(value))),
    secretKey: key,
    aad: _aad(label, salt),
  );
  return {
    'n': base64Encode(box.nonce),
    'c': base64Encode(box.cipherText),
    'm': base64Encode(box.mac.bytes),
  };
}

/// Decrypts a [seal]ed map. Throws [SecretBoxAuthenticationError] if the key
/// (PIN) is wrong or the data was changed on the way.
Future<Object?> unseal(SecretKey key, String label, List<int> salt, Map<String, Object?> m) async {
  final box = SecretBox(
    base64Decode(m['c'] as String),
    nonce: base64Decode(m['n'] as String),
    mac: Mac(base64Decode(m['m'] as String)),
  );
  final plain = await _aes.decrypt(box, secretKey: key, aad: _aad(label, salt));
  return jsonDecode(utf8.decode(gzip.decode(plain)));
}

/// How a receive session ended.
class ReceiveOutcome {
  ReceiveOutcome(this.ok, this.message);
  final bool ok;
  final String message;
}

/// The receiving side. [onBundle] imports the data and returns the success
/// message; it throws to refuse (its message is shown on both devices).
class ShareReceiver {
  ShareReceiver._(this._server, this.port, this.pin, this._salt, this._iterations, this._onBundle, this._onStatus);

  final HttpServer _server;

  /// The port the server listens on (shown with the IP address).
  final int port;
  final String pin;
  final List<int> _salt;
  final int _iterations;
  final Future<String> Function(Map<String, Object?> bundle) _onBundle;
  final void Function(String status)? _onStatus;
  final _done = Completer<ReceiveOutcome>();
  Timer? _timer;
  SecretKey? _key;
  int _wrong = 0;
  bool _busy = false;

  /// Completes once, when the session ends (success, error, timeout or cancel).
  Future<ReceiveOutcome> get done => _done.future;

  static Future<ShareReceiver> start({
    required Future<String> Function(Map<String, Object?> bundle) onBundle,
    void Function(String status)? onStatus,
    Duration timeout = const Duration(minutes: 5),
    int iterations = defaultIterations,
    Object? address,
    String? pin,
  }) async {
    final server = await HttpServer.bind(address ?? InternetAddress.anyIPv4, 0);
    final r = ShareReceiver._(server, server.port, pin ?? newPin(), _randomBytes(16), iterations, onBundle, onStatus);
    r._timer = Timer(timeout, () => r._finish(false, 'Nothing arrived within ${timeout.inMinutes} minutes, so receiving stopped.'));
    server.listen(r._handle, onError: (_) {});
    return r;
  }

  /// This device's local network addresses (to show to the sender).
  static Future<List<String>> localAddresses() async {
    final list = await NetworkInterface.list(type: InternetAddressType.IPv4);
    return [
      for (final i in list)
        for (final a in i.addresses)
          if (!a.isLoopback && !a.isLinkLocal) a.address,
    ];
  }

  Future<void> cancel() => _finish(false, 'Receiving was cancelled.');

  Future<void> _finish(bool ok, String message) async {
    _timer?.cancel();
    if (!_done.isCompleted) _done.complete(ReceiveOutcome(ok, message));
    await _server.close(force: true);
  }

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    try {
      if (req.method == 'GET' && req.uri.path == '/v1/hello') {
        return await _json(res, 200, {'app': 'lucent', 'v': shareProtocol, 'salt': base64Encode(_salt), 'iter': _iterations});
      }
      if (req.method != 'POST' || req.uri.path != '/v1/send') return await _json(res, 404, {'error': 'not_found'});
      if (_busy || _done.isCompleted) return await _json(res, 409, {'error': 'busy'});
      _busy = true;
      try {
        await _receive(req, res);
      } finally {
        _busy = false;
      }
    } catch (_) {
      try {
        await _json(res, 400, {'error': 'bad_request'});
      } catch (_) {}
    }
  }

  Future<void> _receive(HttpRequest req, HttpResponse res) async {
    _onStatus?.call('Receiving…');
    final bytes = <int>[];
    await for (final chunk in req) {
      bytes.addAll(chunk);
      if (bytes.length > maxBodyBytes) return _json(res, 413, {'error': 'too_large'});
    }
    final sealed = (jsonDecode(utf8.decode(bytes)) as Map).cast<String, Object?>();
    _key ??= await deriveKey(pin, _salt, _iterations);
    final Object? bundle;
    try {
      bundle = await unseal(_key!, 'send', _salt, sealed);
    } on SecretBoxAuthenticationError {
      _wrong++;
      final left = maxPinAttempts - _wrong;
      await _json(res, 403, {'error': 'wrong_pin', 'left': left});
      if (left <= 0) {
        await _finish(false, 'The PIN was entered wrongly $maxPinAttempts times, so receiving stopped.');
      } else {
        _onStatus?.call('Wrong PIN from the other device. Waiting…');
      }
      return;
    }
    _onStatus?.call('Importing…');
    var ok = true;
    String message;
    try {
      if (bundle is! Map) throw const FormatException();
      message = await _onBundle(bundle.cast<String, Object?>());
    } catch (e) {
      ok = false;
      message = e is FormatException ? 'The data was damaged.' : '$e';
    }
    await _json(res, 200, await seal(_key!, 'result', _salt, {'ok': ok, 'message': message}));
    await _finish(ok, message);
  }

  static Future<void> _json(HttpResponse res, int status, Object body) async {
    res.statusCode = status;
    res.headers.contentType = ContentType.json;
    res.write(jsonEncode(body));
    await res.close();
  }
}

/// Parses "192.168.1.20:40123" (as shown on the receiver).
(String, int)? parseAddress(String s) {
  final m = RegExp(r'^\s*([0-9.]+|localhost)\s*:\s*(\d{1,5})\s*$').firstMatch(s);
  if (m == null) return null;
  final port = int.parse(m[2]!);
  return port > 0 && port < 65536 ? (m[1]!, port) : null;
}

/// Sends [bundle] to a receiver. Returns the receiver's message
/// (e.g. "Received 132 entries ..."). Throws [ShareException].
Future<String> sendBundle({
  required String host,
  required int port,
  required String pin,
  required Map<String, Object?> bundle,
  void Function(String status)? onStatus,
}) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  final base = Uri(scheme: 'http', host: host, port: port);
  try {
    onStatus?.call('Connecting…');
    final hello = await _request(client, 'GET', base.replace(path: '/v1/hello'), null);
    if (hello.$1 != 200 || hello.$2['app'] != 'lucent') {
      throw ShareException('That address is not a Lucent device waiting to receive.');
    }
    if (hello.$2['v'] != shareProtocol) {
      throw ShareException('The other device runs a different Lucent version. Update both and try again.');
    }
    final salt = base64Decode(hello.$2['salt'] as String);
    onStatus?.call('Encrypting…');
    final key = await deriveKey(pin.trim(), salt, hello.$2['iter'] as int);
    final body = jsonEncode(await seal(key, 'send', salt, bundle));
    onStatus?.call('Sending…');
    final r = await _request(client, 'POST', base.replace(path: '/v1/send'), body);
    if (r.$1 == 403) {
      final left = r.$2['left'] as int? ?? 0;
      throw ShareException(left > 0
          ? 'Wrong PIN. Check the PIN on the other device ($left ${left == 1 ? 'try' : 'tries'} left).'
          : 'Wrong PIN too many times. Start receiving again on the other device.');
    }
    if (r.$1 == 409) throw ShareException('The other device is busy with another transfer.');
    if (r.$1 != 200) throw ShareException('The other device refused the data (error ${r.$1}).');
    final Object? result;
    try {
      result = await unseal(key, 'result', salt, r.$2);
    } on SecretBoxAuthenticationError {
      throw ShareException('The reply from the other device could not be verified.');
    }
    final m = result as Map;
    if (m['ok'] != true) throw ShareException(m['message'] as String);
    return m['message'] as String;
  } on ShareException {
    rethrow;
  } on SocketException {
    throw ShareException(
      "Couldn't reach $host:$port. Check both devices are on the same Wi-Fi, "
      'the address is right, and the other device is still on the Receive screen.',
    );
  } on TimeoutException {
    throw ShareException('The other device stopped responding.');
  } on HttpException {
    throw ShareException('The connection was interrupted. Try again.');
  } on FormatException {
    throw ShareException('The other device sent an answer Lucent does not understand.');
  } finally {
    client.close(force: true);
  }
}

Future<(int, Map<String, Object?>)> _request(HttpClient c, String method, Uri uri, String? body) async {
  final req = await c.openUrl(method, uri);
  if (body != null) {
    req.headers.contentType = ContentType.json;
    req.write(body);
  }
  final res = await req.close().timeout(const Duration(minutes: 2));
  final text = await utf8.decodeStream(res).timeout(const Duration(minutes: 2));
  return (res.statusCode, (jsonDecode(text) as Map).cast<String, Object?>());
}
