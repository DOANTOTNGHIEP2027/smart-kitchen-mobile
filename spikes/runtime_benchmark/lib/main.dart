import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'bench/bench_runner.dart';
import 'bench/crash_ledger.dart';
import 'bench/runners.dart';

/// Spike benchmark gate #116 — chạy trên THIẾT BỊ THẬT, không emulator.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  final ledger = CrashLedger(dir)..reconcileOnStartup();
  runApp(MaterialApp(home: BenchPage(ledger: ledger, outDir: dir)));
}

class BenchPage extends StatefulWidget {
  const BenchPage({super.key, required this.ledger, required this.outDir});

  final CrashLedger ledger;
  final Directory outDir;

  @override
  State<BenchPage> createState() => _BenchPageState();
}

class _BenchPageState extends State<BenchPage> {
  final _runners = runnersForPlatform();
  late final Set<String> _selected = _runners.map((r) => r.id).toSet();
  final _device = TextEditingController();
  final _rounds = TextEditingController(text: '1');
  bool _running = false;
  String _status = '';
  String _report = '';

  Future<void> _run() async {
    setState(() => _running = true);
    final results = <Map<String, dynamic>>[];
    final rounds = int.tryParse(_rounds.text) ?? 1;
    for (var round = 1; round <= rounds; round++) {
      for (final r in _runners.where((r) => _selected.contains(r.id))) {
        setState(() => _status = 'Vòng $round/$rounds — ${r.id}…');
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final res = await benchOne(r, widget.ledger);
        // Chỉ vòng 1 vào bảng latency; các vòng sau phục vụ crash-free rate.
        if (round == 1) results.add(res);
      }
    }
    final report = const JsonEncoder.withIndent('  ').convert(buildReport(
      device: _device.text.trim(),
      results: results,
      ledger: widget.ledger,
    ));
    final file = File('${widget.outDir.path}/bench_'
        '${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(report);
    setState(() {
      _running = false;
      _status = 'Xong — đã lưu ${file.path}';
      _report = report;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Runtime benchmark #116')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _device,
            decoration: const InputDecoration(
                labelText: 'Model máy (vd. Galaxy A54, iPhone 12)'),
          ),
          TextField(
            controller: _rounds,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Số vòng (vòng ≥2 chỉ để đếm crash-free)'),
          ),
          for (final r in _runners)
            CheckboxListTile(
              dense: true,
              title: Text(r.id),
              value: _selected.contains(r.id),
              onChanged: _running
                  ? null
                  : (v) => setState(() =>
                      v! ? _selected.add(r.id) : _selected.remove(r.id)),
            ),
          Wrap(spacing: 8, children: [
            FilledButton(
              onPressed: _running || _device.text.trim().isEmpty ? null : _run,
              child: const Text('Chạy'),
            ),
            OutlinedButton(
              onPressed: _report.isEmpty
                  ? null
                  : () => Clipboard.setData(ClipboardData(text: _report)),
              child: const Text('Copy JSON'),
            ),
            OutlinedButton(
              onPressed: _running
                  ? null
                  : () => setState(() {
                        widget.ledger.reset();
                        _status = 'Đã xoá crash ledger';
                      }),
              child: const Text('Reset ledger'),
            ),
          ]),
          const SizedBox(height: 8),
          Text(_status),
          SelectableText(_report,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _device.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _device.dispose();
    _rounds.dispose();
    super.dispose();
  }
}
