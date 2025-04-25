import 'dart:io';
import 'package:flutter/material.dart';
import 'pos_mdns.dart';

class POSServerScreen extends StatefulWidget {
  @override
  _POSServerScreenState createState() => _POSServerScreenState();
}

class _POSServerScreenState extends State<POSServerScreen>
    with WidgetsBindingObserver {
  Map<String, Socket> clients = {};
  List<String> messages = [];
  String ipAddress = 'Loading...';
  ServerSocket? server;
  String? selectedClientID;

  String deviceName = 'Loading...';

  final ScrollController _scrollController = ScrollController();

  void _loadDeviceName() async {
    final name = await getDeviceName();
    setState(() {
      deviceName = name;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDeviceName();
    _getIPAddress();
    _startServer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (var c in clients.values) {
      c.close();
    }
    server?.close();
    stopAdvertisement();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("🔄 App resumed: restarting mDNS advertisement");
      advertiseMainPOS();
    } else if (state == AppLifecycleState.paused) {
      print("⏸ App paused: stopping mDNS");
      stopAdvertisement();
    }
  }

  String _getClientID(Socket socket) {
    return '${socket.remoteAddress.address}:${socket.remotePort}';
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

  Map<String, String> clientNames = {}; // clientID -> deviceName
  void _startServer() async {
    await advertiseMainPOS();
    server = await ServerSocket.bind(InternetAddress.anyIPv4, 34041);
    server!.listen((client) {
      final clientID = _getClientID(client);
      clients[clientID] = client;

      setState(() => messages.add('🔌 Client connected: $clientID'));

      client.listen(
        (data) {
          final msg = String.fromCharCodes(data);

          if (msg.startsWith('[DEVICE_NAME]')) {
            final deviceName = msg.replaceFirst('[DEVICE_NAME]', '').trim();
            setState(() {
              clientNames[clientID] = deviceName;
              messages.add('🆔 $clientID is "$deviceName"');              
            });
          } else {
            final name = clientNames[clientID] ?? clientID;
            setState(() => messages.add('$name: $msg'));
            sendToAll(msg);            
          }
          _scrollToBottom();
        },
        onDone: () {
          clients.remove(clientID);
          final name = clientNames.remove(clientID) ?? clientID;
          setState(() => messages.add('❌ Disconnected: $name'));
          _scrollToBottom();
        },
        onError: (e) {
          clients.remove(clientID);
          final name = clientNames.remove(clientID) ?? clientID;
          setState(() => messages.add('⚠️ Error ($name): $e'));
          _scrollToBottom();
        },
        cancelOnError: true,
      );
    });
  }

  void sendToAll(String msg) {
    for (var c in clients.values) {
      c.write(msg);
    }
    setState(() => messages.add('📢 Me (to all): $msg'));
  }

  void sendToOthers(String msg, String excludeID) {
    for (var entry in clients.entries) {
      if (entry.key != excludeID) {
        entry.value.write(msg);
      }
    }
    setState(() => messages.add('📤 Me (to others): $msg'));
  }

  void sendToClient(String clientID, String msg) {
    final target = clients[clientID];
    if (target != null) {
      target.write(msg);
      setState(() => messages.add('➡️ Me (to $clientID): $msg'));
    } else {
      setState(() => messages.add('❌ Client $clientID not found.'));
    }
  }

  Future<void> _shutdownServerAndExit() async {
    for (var c in clients.values) {
      c.close();
    }
    server?.close();
    await stopAdvertisement();
    Navigator.pop(context);
  }

void _scrollToBottom() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  });
}


  @override
  Widget build(BuildContext context) {
    TextEditingController controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text('Main POS - $ipAddress ($deviceName)'),
        actions: [
          IconButton(
            icon: Icon(Icons.power_settings_new),
            tooltip: 'Shutdown Server',
            onPressed: () {
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
                            Navigator.pop(context);
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
          // 메시지 기록
          Expanded(
            flex: 2,
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.all(8),
              children: messages.map((m) => Text(m)).toList(),
            ),
          ),
          Divider(),
          // 클라이언트 목록
          Container(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 8),
              children:
                  clients.keys.map((clientID) {
                    final label = clientNames[clientID] ?? clientID;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: selectedClientID == clientID,
                        onSelected: (_) {
                          setState(() => selectedClientID = clientID);
                        },
                      ),
                    );
                  }).toList(),
            ),
          ),
          // 메시지 입력 및 전송 버튼
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: controller)),
                PopupMenuButton<String>(
                  icon: Icon(Icons.send),
                  onSelected: (action) {
                    final msg = controller.text.trim();
                    if (msg.isEmpty) return;

                    switch (action) {
                      case 'all':
                        sendToAll(msg);
                        break;
                      case 'selected':
                        if (selectedClientID != null) {
                          sendToClient(selectedClientID!, msg);
                        }
                        break;
                      case 'others':
                        if (selectedClientID != null) {
                          sendToOthers(msg, selectedClientID!);
                        }
                        break;
                    }

                    controller.clear();
                  },
                  itemBuilder:
                      (_) => [
                        PopupMenuItem(value: 'all', child: Text('Send to All')),
                        PopupMenuItem(
                          value: 'selected',
                          child: Text('Send to Selected'),
                        ),
                        PopupMenuItem(
                          value: 'others',
                          child: Text('Send to Others'),
                        ),
                      ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
