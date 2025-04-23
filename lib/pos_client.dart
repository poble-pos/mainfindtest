import 'dart:io';
import 'package:flutter/material.dart';
import 'pos_mdns.dart';

class POSClientScreen extends StatefulWidget {
  @override
  _POSClientScreenState createState() => _POSClientScreenState();
}


class _POSClientScreenState extends State<POSClientScreen> {
  Socket? socket;
  List<String> messages = [];
  List<String> foundServers = [];
  bool isLoading = true;
  String? connectedIP;

  @override
  void initState() {
    super.initState();
    _searchForServers();
  }

  void _searchForServers() async {
    final servers = await findMainPOSList();
    setState(() {
      foundServers = servers;
      isLoading = false;
    });
  }

  void _connectToSelectedServer(String ip) async {
  if (connectedIP == ip) {
    final shouldDisconnect = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Already connected"),
        content: Text("Already connected on $ip \n Disconnect?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Confirm disconnect"),
          ),
        ],
      ),
    );

    if (shouldDisconnect == true) {
      await socket?.close();
      setState(() {
        socket = null;
        connectedIP = null;
        messages.add("🔌 Disconnected from $ip");
      });
    }
    return;
  }

  // 다른 서버로 전환
  await socket?.close();
  socket = null;
  setState(() {
    messages.add("🔌 Switching to $ip...");
    connectedIP = ip;
  });

  try {
    socket = await Socket.connect(ip, 34041);
    setState(() => messages.add("✅ Connected to $ip"));

    socket!.listen((data) {
      final msg = String.fromCharCodes(data);
      setState(() => messages.add('Server: $msg'));
    });
  } catch (e) {
    setState(() {
      messages.add("❌ Connection failed: $e");
      connectedIP = null;
    });
  }
}


  void _sendMessage(String msg) {
    if (socket != null && msg.trim().isNotEmpty) {
      socket!.write(msg);
      setState(() => messages.add('Me: $msg'));
    }
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
      appBar: AppBar(title: Text('Client POS')),
      body: socket == null
          ? isLoading
              ? Center(child: CircularProgressIndicator())
              : foundServers.isEmpty
                  ? Center(child: Text('No Main POS found.'))
                  : ListView.builder(
                      padding: EdgeInsets.all(12),
                      itemCount: foundServers.length,
                      itemBuilder: (context, index) {
                        final ip = foundServers[index];
                        final isConnected = ip == connectedIP;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isConnected
                                  ? Colors.green
                                  : Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white, 
                              padding: EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => _connectToSelectedServer(ip),
                            icon: Icon(isConnected
                                ? Icons.check_circle
                                : Icons.wifi),
                            label: Text(
                              isConnected
                                  ? 'Connected to $ip'
                                  : 'Connect to $ip',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        );
                      },
                    )
          : Column(
              children: [
                Expanded(
                    child: ListView(
                        padding: EdgeInsets.all(12),
                        children: messages.map((m) => Text(m)).toList())),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(children: [
                    Expanded(child: TextField(controller: controller)),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () {
                        _sendMessage(controller.text);
                        controller.clear();
                      },
                    )
                  ]),
                )
              ],
            ),
    );
  }
}
