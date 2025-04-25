import 'dart:io';

import 'package:flutter/material.dart';

class ManualTestScreen extends StatefulWidget {
  @override
  _ManualTestScreenState createState() => _ManualTestScreenState();
}

class _ManualTestScreenState extends State<ManualTestScreen> {
  final ipController = TextEditingController();
  final msgController = TextEditingController();
  Socket? socket;
  List<String> logs = [];

  void _connect() async {
    final ip = ipController.text.trim();
    if (ip.isEmpty) return;

    try {
      socket = await Socket.connect(ip, 34041);
      logs.add("✅ Connected to $ip");

      socket!.listen((data) {
        final msg = String.fromCharCodes(data);
        setState(() => logs.add("📥 Server: $msg"));
      });

      setState(() {});
    } catch (e) {
      setState(() => logs.add("❌ Connection failed: $e"));
    }
  }

  void _disconnect() {
    socket?.destroy();
    socket = null;
    setState(() => logs.add("🔌 Disconnected"));
  }

  void _sendMessage() {
    final msg = msgController.text;
    if (socket != null && msg.isNotEmpty) {
      socket!.write(msg);
      setState(() => logs.add("📤 Me: $msg"));
      msgController.clear();
    }
  }

  @override
  void dispose() {
    socket?.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manual Socket Test')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: ipController,
              decoration: InputDecoration(
                labelText: 'Server IP',
                hintText: 'e.g. 192.168.XXX.XXX',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: socket == null ? _connect : null,
                  child: Text('Connect'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: socket != null ? _disconnect : null,
                  child: Text('Disconnect'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: msgController,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: logs.map((log) => Text(log)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
