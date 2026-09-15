import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ios_local_network_check/ios_local_network_check.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _plugin = const IosLocalNetworkCheck();
  final _ipAddressController = TextEditingController(text: '192.168.1.1');
  final _portController = TextEditingController(text: '9');

  StreamSubscription<LocalNetworkPermissionStatus>? _subscription;
  LocalNetworkProtocol _protocol = LocalNetworkProtocol.udp;
  LocalNetworkPermissionStatus? _status;
  String? _error;
  bool _isChecking = false;

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _ipAddressController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _startCheck() async {
    await _subscription?.cancel();

    final port = int.tryParse(_portController.text);
    if (port == null) {
      setState(() {
        _error = '请输入有效端口';
      });
      return;
    }

    setState(() {
      _status = null;
      _error = null;
      _isChecking = true;
    });

    try {
      final stream = _plugin.check(
        ipAddress: _ipAddressController.text.trim(),
        port: port,
        protocol: _protocol,
      );
      _subscription = stream.listen(
        (status) {
          if (!mounted) {
            return;
          }
          setState(() {
            _status = status;
          });
        },
        onError: (Object error) {
          if (!mounted) {
            return;
          }
          setState(() {
            _error = error.toString();
            _isChecking = false;
          });
        },
        onDone: () {
          if (!mounted) {
            return;
          }
          setState(() {
            _isChecking = false;
          });
        },
      );
    } on Object catch (error) {
      setState(() {
        _error = error.toString();
        _isChecking = false;
      });
    }
  }

  Future<void> _cancelCheck() async {
    await _subscription?.cancel();
    _subscription = null;
    if (!mounted) {
      return;
    }
    setState(() {
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text('iOS 本地网络权限检查')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextField(
                controller: _ipAddressController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '本地网络 IP',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _portController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '端口',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              SegmentedButton<LocalNetworkProtocol>(
                segments: const [
                  ButtonSegment(
                    value: LocalNetworkProtocol.udp,
                    label: Text('UDP'),
                  ),
                  ButtonSegment(
                    value: LocalNetworkProtocol.tcp,
                    label: Text('TCP'),
                  ),
                ],
                selected: {_protocol},
                onSelectionChanged:
                    _isChecking
                        ? null
                        : (selection) {
                          setState(() {
                            _protocol = selection.single;
                          });
                        },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isChecking ? null : _startCheck,
                child: const Text('开始检查'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _isChecking ? _cancelCheck : null,
                child: const Text('取消'),
              ),
              const SizedBox(height: 32),
              Text(
                '权限状态：${_status?.name ?? '尚未检查'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
