import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../share/transfer.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Settings -> "Send to another device": pick Send or Receive.
class ShareScreen extends StatelessWidget {
  const ShareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    void open(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    return Scaffold(
      appBar: AppBar(title: const Text('Send to another device')),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Copy everything in this book (entries, categories, budgets, savings goal) '
              'to your other phone or computer over your own Wi-Fi. Both devices must be on '
              'the same network. Nothing goes through the internet.',
              style: t.body,
            ),
            const SizedBox(height: 8),
            Text(
              'Entries that are already on the other device are not doubled; '
              'where both have changed the same entry, the newer change is kept.',
              style: t.caption,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => open(const SendPage()),
              icon: const Icon(Icons.upload),
              label: const Text('Send'),
            ),
            const SizedBox(height: 8),
            Text('On the device that has the data.', style: t.caption, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => open(const ReceivePage()),
              icon: const Icon(Icons.download),
              label: const Text('Receive'),
            ),
            const SizedBox(height: 8),
            Text('On the device that should get the data. Start this first.',
                style: t.caption, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.ok, required this.message});
  final bool ok;
  final String message;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Icon(ok ? Icons.check_circle_outline : Icons.error_outline,
            size: 48, color: ok ? c.accent : c.over),
        const SizedBox(height: 12),
        Text(message, style: context.text.body, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
      ],
    );
  }
}

class _Busy extends StatelessWidget {
  const _Busy(this.status);
  final String status;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SizedBox(width: 32, height: 32, child: CircularProgressIndicator()),
      const SizedBox(height: 12),
      Text(status, style: context.text.body, textAlign: TextAlign.center),
    ],
  );
}

class ReceivePage extends StatefulWidget {
  const ReceivePage({super.key});
  @override
  State<ReceivePage> createState() => _ReceivePageState();
}

class _ReceivePageState extends State<ReceivePage> {
  ShareReceiver? _rx;
  List<String> _addresses = [];
  String _status = 'Starting…';
  ReceiveOutcome? _outcome;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final store = StoreScope.read(context);
    try {
      final rx = await ShareReceiver.start(
        onBundle: (b) async => (await store.importBook(b)).message,
        onStatus: (s) => mounted ? setState(() => _status = s) : null,
      );
      final addrs = await ShareReceiver.localAddresses();
      if (!mounted) {
        await rx.cancel();
        return;
      }
      setState(() {
        _rx = rx;
        _addresses = addrs;
        _status = 'Waiting for the other device…';
      });
      final out = await rx.done;
      if (mounted) setState(() => _outcome = out);
    } catch (e) {
      if (mounted) setState(() => _outcome = ReceiveOutcome(false, "Couldn't start receiving: $e"));
    }
  }

  @override
  void dispose() {
    _rx?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final rx = _rx;
    final out = _outcome;
    Widget body;
    if (out != null) {
      body = _Result(ok: out.ok, message: out.message);
    } else if (rx == null) {
      body = _Busy(_status);
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('On the other device, open Settings → Send to another device → Send, '
              'and enter:', style: t.body),
          const SizedBox(height: 24),
          Text('Address', style: t.caption, textAlign: TextAlign.center),
          if (_addresses.isEmpty)
            Text('No Wi-Fi address found. Connect this device to Wi-Fi and try again.',
                style: t.body, textAlign: TextAlign.center)
          else
            for (final a in _addresses)
              SelectableText('$a:${rx.port}', style: t.headlineAmount, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text('PIN', style: t.caption, textAlign: TextAlign.center),
          SelectableText(
            '${rx.pin.substring(0, 3)} ${rx.pin.substring(3)}',
            key: const Key('pin'),
            style: t.displayAmount,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _Busy(_status),
          const SizedBox(height: 16),
          Text('Keep this screen open. It stops by itself after one transfer or 5 minutes.',
              style: t.caption, textAlign: TextAlign.center),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Receive')),
      body: MaxWidth(child: ListView(padding: const EdgeInsets.all(16), children: [body])),
    );
  }
}

class SendPage extends StatefulWidget {
  const SendPage({super.key});
  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  final _address = TextEditingController();
  final _pin = TextEditingController();
  String? _status;
  String? _error;
  String? _done;

  @override
  void dispose() {
    _address.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final addr = parseAddress(_address.text);
    final pin = _pin.text.replaceAll(' ', '');
    if (addr == null) {
      return setState(() => _error = 'Enter the address exactly as shown on the other device, e.g. 192.168.1.20:40123.');
    }
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      return setState(() => _error = 'The PIN has 6 digits.');
    }
    final store = StoreScope.read(context);
    setState(() {
      _error = null;
      _status = 'Preparing…';
    });
    try {
      final bundle = await store.exportBook();
      final msg = await sendBundle(
        host: addr.$1,
        port: addr.$2,
        pin: pin,
        bundle: bundle,
        onStatus: (s) => mounted ? setState(() => _status = s) : null,
      );
      if (mounted) setState(() => _done = 'Sent. The other device says:\n$msg');
    } on ShareException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _status = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final busy = _status != null;
    final done = _done;
    return Scaffold(
      appBar: AppBar(title: const Text('Send')),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (done != null)
              _Result(ok: true, message: done)
            else ...[
              Text('On the other device, open Settings → Send to another device → Receive. '
                  'Then type the address and PIN it shows.', style: t.body),
              const SizedBox(height: 16),
              TextField(
                controller: _address,
                enabled: !busy,
                decoration: const InputDecoration(labelText: 'Address', hintText: '192.168.1.20:40123'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.:]'))],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pin,
                enabled: !busy,
                decoration: const InputDecoration(labelText: 'PIN'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                onSubmitted: (_) => busy ? null : _send(),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Text(_error!, style: t.body.copyWith(color: context.colors.over)),
                const SizedBox(height: 16),
              ],
              if (busy) _Busy(_status!) else FilledButton(onPressed: _send, child: const Text('Send')),
            ],
          ],
        ),
      ),
    );
  }
}
