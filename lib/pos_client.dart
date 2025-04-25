import 'dart:io';
import 'package:flutter/material.dart';
import 'pos_mdns.dart';

class POSClientScreen extends StatefulWidget {
  final List<FoundPOS>? foundServers;

  const POSClientScreen({super.key, this.foundServers});
  @override
  _POSClientScreenState createState() => _POSClientScreenState();
}

class _POSClientScreenState extends State<POSClientScreen> {
  Socket? socket;
  List<String> messages = [];
  List<FoundPOS> foundServers = [];
  bool isLoading = true;
  String? connectedIP;

  @override
  void initState() {
    super.initState();
    if (widget.foundServers != null) {
      // 서버 리스트가 이미 있는 경우
      foundServers = widget.foundServers!;
      isLoading = false;

      if (foundServers.isNotEmpty) {
        _connectToSelectedServer(foundServers.first);
      }
    } else {
      // 수동 진입한 경우 또는 fallback
      _searchAndConnectToServer();
    }
  }

  void _searchAndConnectToServer() async {
    final servers = await findMainPOSList();
    if (servers.isNotEmpty) {
      setState(() => foundServers = servers);
      _connectToSelectedServer(servers.first);
    } else {
      setState(() {
        foundServers = [];
        isLoading = false;
      });
    }
  }

  String? mainPOSDeviceName;

void _connectToSelectedServer(FoundPOS pos) async {
  final ip = pos.ip;
  await socket?.close();
  socket = null;

  setState(() {
    connectedIP = ip;
    mainPOSDeviceName = pos.deviceName;
    messages.add("🔌 Connecting to $ip (${mainPOSDeviceName ?? ''})...");
    isLoading = true;
  });

  try {
    socket = await Socket.connect(ip, 34041);

    // ✅ 연결 직후 장비 이름 전송
    final myDeviceName = await getDeviceName();
    socket!.write('[DEVICE_NAME]$myDeviceName');

    socket!.listen(
      (data) {
        final msg = String.fromCharCodes(data);
        setState(() => messages.add('Server: $msg'));
      },
      onDone: () {
        setState(() {
          messages.add("❌ Disconnected from server.");
          socket = null;
          connectedIP = null;
        });
      },
      onError: (e) {
        setState(() {
          messages.add("⚠️ Socket error: $e");
          socket = null;
          connectedIP = null;
        });
      },
    );

    setState(() {
      messages.add("✅ Connected to $ip (${mainPOSDeviceName ?? ''})");
      isLoading = false;
    });
  } catch (e) {
    setState(() {
      messages.add("❌ Connection failed: $e");
      connectedIP = null;
      isLoading = false;
    });
  }
}


  void _sendMessage(String msg) {
    if (socket != null && msg.trim().isNotEmpty) {
      socket!.write(msg);
      setState(() => messages.add('Me: $msg'));
    }
  }

  void _showServerSwitchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Switch Server"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                foundServers.map((pos) {
                  final isConnected = pos.ip == connectedIP;
                  return ListTile(
                    title: Text('device: ${pos.deviceName} ip:${pos.ip}'),
                    trailing:
                        isConnected
                            ? Icon(Icons.check_circle, color: Colors.green)
                            : null,
                    onTap: () {
                      Navigator.pop(context);
                      if (!isConnected) {
                        _connectToSelectedServer(pos);
                      }
                    },
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    socket?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text(
  'Client POS - Connected to ${mainPOSDeviceName ?? connectedIP ?? 'Unknown'}',
),

        actions: [
          IconButton(
            icon: Icon(Icons.swap_horiz),
            tooltip: 'Switch Server',
            onPressed: foundServers.isEmpty ? null : _showServerSwitchDialog,
          ),
        ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : socket == null
              ? Center(child: Text('No Main POS found.'))
              : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.all(12),
                      children: messages.map((m) => Text(m)).toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(child: TextField(controller: controller)),
                        IconButton(
                          icon: Icon(Icons.send),
                          onPressed: () {
                            _sendMessage(controller.text);
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
