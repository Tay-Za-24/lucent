import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucent/data/models.dart';
import 'package:lucent/data/store.dart';
import 'package:lucent/data/sync.dart';
import 'package:lucent/share/transfer.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tmp;
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });
  setUp(() => tmp = Directory.systemTemp.createTempSync('lucent_share'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('parseAddress', () {
    expect(parseAddress(' 192.168.1.20 : 40123 '), ('192.168.1.20', 40123));
    expect(parseAddress('192.168.1.20'), isNull);
    expect(parseAddress('1.2.3.4:99999'), isNull);
  });

  test('seal/unseal round trip; wrong key fails', () async {
    final salt = List<int>.filled(16, 7);
    final k = await deriveKey('123456', salt, 1000);
    final m = await seal(k, 'send', salt, {'a': 1});
    expect(await unseal(k, 'send', salt, m), {'a': 1});
    final bad = await deriveKey('123457', salt, 1000);
    expect(() => unseal(bad, 'send', salt, m), throwsA(isA<SecretBoxAuthenticationError>()));
    expect(() => unseal(k, 'result', salt, m), throwsA(isA<SecretBoxAuthenticationError>()));
  });

  test('PBKDF2 at the real iteration count is fast enough', () async {
    final sw = Stopwatch()..start();
    await deriveKey('123456', List<int>.filled(16, 1), defaultIterations);
    // ignore: avoid_print
    print('PBKDF2 $defaultIterations iterations: ${sw.elapsedMilliseconds} ms');
  });

  test('loopback: send a whole book from one store to another', () async {
    final a = await AppStore.open(path: '${tmp.path}/a.db');
    final food = await a.addCategory('Food', Kind.expense, 1);
    for (var i = 0; i < 132; i++) {
      await a.saveEntry(kind: Kind.expense, amount: 100 + i, categoryId: food.id, date: DateTime.now());
    }
    final b = await AppStore.open(path: '${tmp.path}/b.db');
    final statuses = <String>[];
    final rx = await ShareReceiver.start(
      address: InternetAddress.loopbackIPv4,
      iterations: 1000,
      onBundle: (bundle) async => (await b.importBook(bundle)).message,
      onStatus: statuses.add,
    );

    // A wrong PIN is rejected and leaves the session open.
    final wrong = rx.pin == '000000' ? '111111' : '000000';
    await expectLater(
      sendBundle(host: '127.0.0.1', port: rx.port, pin: wrong, bundle: await a.exportBook()),
      throwsA(isA<ShareException>().having((e) => e.message, 'message', contains('Wrong PIN'))),
    );

    final msg = await sendBundle(host: '127.0.0.1', port: rx.port, pin: rx.pin, bundle: await a.exportBook());
    expect(msg, startsWith('Received 132 entries'));
    final out = await rx.done;
    expect(out.ok, isTrue);
    expect(b.monthEntries, hasLength(132));
    expect(statuses, contains('Importing…'));

    // The server is closed after one transfer.
    await expectLater(
      sendBundle(host: '127.0.0.1', port: rx.port, pin: rx.pin, bundle: await a.exportBook()),
      throwsA(isA<ShareException>()),
    );
  });

  test('receiver refusal (decimals) reaches the sender; three wrong PINs close it', () async {
    final a = await AppStore.open(path: '${tmp.path}/a.db');
    final c = await a.addCategory('Food', Kind.expense, 1);
    await a.saveEntry(kind: Kind.expense, amount: 5, categoryId: c.id, date: DateTime.now());
    final b = await AppStore.open(path: '${tmp.path}/b.db');
    await b.setDecimals(2);
    final c2 = await b.addCategory('Rent', Kind.expense, 1);
    await b.saveEntry(kind: Kind.expense, amount: 5, categoryId: c2.id, date: DateTime.now());
    final rx = await ShareReceiver.start(
      address: InternetAddress.loopbackIPv4,
      iterations: 1000,
      onBundle: (bundle) async => (await b.importBook(bundle)).message,
    );
    await expectLater(
      sendBundle(host: '127.0.0.1', port: rx.port, pin: rx.pin, bundle: await a.exportBook()),
      throwsA(isA<ShareException>().having((e) => e.message, 'message', contains('decimal places'))),
    );
    expect((await rx.done).ok, isFalse);
    expect(() => validateBundle({}), throwsA(isA<BundleError>()));

    final rx2 = await ShareReceiver.start(address: InternetAddress.loopbackIPv4, iterations: 1000, onBundle: (_) async => 'x');
    final wrong = rx2.pin == '000000' ? '111111' : '000000';
    for (var i = 0; i < maxPinAttempts; i++) {
      await expectLater(
        sendBundle(host: '127.0.0.1', port: rx2.port, pin: wrong, bundle: const {}),
        throwsA(isA<ShareException>()),
      );
    }
    expect((await rx2.done).message, contains('wrongly'));
  });
}
