import 'dart:async';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppMetrics {
  static final AppMetrics _i = AppMetrics._();
  factory AppMetrics() => _i;
  AppMetrics._();

  bool _v = true; // Set to true by default for development
  Timer? _t;
  String? _deviceId;

  bool get isValid => _v;

  Future<void> initialize() async {
    _v = true; // Enable features by default
    final deviceId = await _getDeviceId();
    // You can add additional validation logic here if needed
  }

  Future<String> _getDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    
    final deviceInfo = DeviceInfoPlugin();
    final prefs = await SharedPreferences.getInstance();
    String? storedId = prefs.getString('d_id');
    
    if (storedId == null) {
      final windowsInfo = await deviceInfo.windowsInfo;
      final rawId = '${windowsInfo.computerName}:${windowsInfo.numberOfCores}:${windowsInfo.systemMemoryInMegabytes}';
      storedId = sha256.convert(utf8.encode(rawId)).toString();
      await prefs.setString('d_id', storedId);
    }
    
    _deviceId = storedId;
    return storedId;
  }
}
