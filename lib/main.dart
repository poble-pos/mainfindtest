import 'package:flutter/material.dart';
import 'package:mainfindtest/manualTest.dart';
import 'package:mainfindtest/pos_mdns.dart';
import 'package:mainfindtest/util.dart';
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
    _checkAndSetDeviceName();
  }

  Future<void> _checkAndSetDeviceName() async {
    final name = await loadDeviceName();

    if (name == null || name.trim().isEmpty) {
      // 이름이 없으면 입력 다이얼로그 표시
      await Future.delayed(Duration(milliseconds: 300)); // 약간의 지연으로 context 안정화
      final result = await _showDeviceNameDialog();

      if (result != null && result.trim().isNotEmpty) {
        await saveDeviceName(result.trim());
      } else {
        // 아무 것도 입력 안 하면 앱 종료 또는 기본 이름 설정
        Navigator.of(context).pop();
        return;
      }
    }

    _autoDecideRole();
  }

  Future<String?> _showDeviceNameDialog() async {
    TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false, // 반드시 입력하게
      builder: (context) {
        return AlertDialog(
          title: Text('POS 장비 이름을 입력하세요'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '예: 매장1-POS',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text('확인'),
            ),
          ],
        );
      },
    );
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
