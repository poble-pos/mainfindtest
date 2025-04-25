import 'package:shared_preferences/shared_preferences.dart';

const String deviceNameKey = 'device_name';

Future<void> saveDeviceName(String name) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(deviceNameKey, name);
}

Future<String?> loadDeviceName() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(deviceNameKey);
}
