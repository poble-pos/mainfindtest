import 'package:flutter/material.dart';
import 'package:mainfindtest/manualTest.dart';
import 'package:mainfindtest/pos_mdns.dart';
import 'pos_server.dart';
import 'pos_client.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Test App',
      home: RoleSelectorScreen(),
    );
  }
}

class RoleSelectorScreen extends StatefulWidget {
  @override
  _RoleSelectorScreenState createState() => _RoleSelectorScreenState();
}

class _RoleSelectorScreenState extends State<RoleSelectorScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _autoDecideRole();
  }

  void _autoDecideRole() async {
  final foundServers = await findMainPOSList();

  if (foundServers.isEmpty) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => POSServerScreen()),
    );
  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => POSClientScreen(foundServers: foundServers),
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

//select role by button
class ManualRoleSelectorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('POS Role Selection')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text('Main POS (Server)'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => POSServerScreen()),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Client POS'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => POSClientScreen()),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
  child: Text('Manual Socket Test'),
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ManualTestScreen()),
  ),
),

          ],
        ),
      ),
    );
  }
}
