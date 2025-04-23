import 'dart:io';
import 'package:flutter/material.dart';
import 'pos_mdns.dart';

class POSServerScreen extends StatefulWidget {
  @override
  _POSServerScreenState createState() => _POSServerScreenState();
}

class _POSServerScreenState extends State<POSServerScreen> {
  final List<String> messages = [];
  ServerSocket? server;
  List<Socket> clients = [];
  String ipAddress = 'Loading...';

  @override
  void initState() {
    super.initState();
    _getIPAddress();
    _startServer();
  }

  Future<void> _getIPAddress() async {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          setState(() {
            ipAddress = addr.address;
          });
          return;
        }
      }
    }
    setState(() {
      ipAddress = 'IP not found';
    });
  }

  void _startServer() async {
    await advertiseMainPOS();
    server = await ServerSocket.bind(InternetAddress.anyIPv4, 34041);
    server!.listen((client) {
      clients.add(client);
      final address = client.remoteAddress.address;
      final port = client.remotePort;

      setState(() => messages.add('🔌 Client connected: $address:$port'));

      client.listen(
        (data) {
          final msg = String.fromCharCodes(data);
          setState(() => messages.add('Client: $msg'));
        },
        onDone: () {
          clients.remove(client);
          setState(() => messages.add('❌ Client disconnected: $address:$port'));
        },
        onError: (e) {
          clients.remove(client);
          setState(() => messages.add('⚠️ Client error ($address:$port): $e'));
        },
        cancelOnError: true,
      );
    });
  }

  void _sendToClients(String msg) {
    for (var client in clients) {
      client.write(msg);
    }
    setState(() => messages.add('Me: $msg'));
  }

  Future<void> _shutdownServerAndExit() async {
    for (var c in clients) {
      c.close();
    }
    server?.close();
    await stopAdvertisement();
    Navigator.pop(context); // ⬅️ 메인 페이지로 돌아감
  }

  @override
  void dispose() {
    for (var c in clients) {
      c.close();
    }
    server?.close();    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text('Main POS (Server) - $ipAddress'),
        actions: [
          IconButton(
            icon: Icon(Icons.power_settings_new),
            tooltip: 'Shutdown Server',
            onPressed: () {
              // 🔴 Confirmation dialog before shutting down
              showDialog(
                context: context,
                builder:
                    (_) => AlertDialog(
                      title: Text("Shutdown Server"),
                      content: Text(
                        "Do you want to stop the server and return to the main screen?",
                      ),
                      actions: [
                        TextButton(
                          child: Text("Cancel"),
                          onPressed: () => Navigator.pop(context),
                        ),
                        ElevatedButton(
                          child: Text("Shutdown"),
                          onPressed: () {
                            Navigator.pop(context); // Close dialog
                            _shutdownServerAndExit();
                          },
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(child: ListView(children: messages.map(Text.new).toList())),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: controller)),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    _sendToClients(controller.text);
                    controller.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
