import 'package:flutter/material.dart';
import 'package:mainfindtest/manualTest.dart';
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

class RoleSelectorScreen extends StatelessWidget {
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
