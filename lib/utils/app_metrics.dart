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

  bool _v = false;
  Timer? _t;
  String? _deviceId;

  final List<int> _tc = [19, 23, 15, 27, 18, 21, 14, 19, 27, 16]; 
  final List<int> _ts = [4, 7, 2, 8, 5, 6, 3, 4, 8, 1];
  
  final List<int> _s1 = [15, 21, 11, 21, 19, 8, 21]; 
  final List<int> _s2 = [87, 96, 82, 96, 94, 79, 96]; 
  final List<int> _k1 = [89, 91, 90, 91, 89, 87, 90]; 
  final List<int> _k2 = [13, 26, 25, 26, 26, 25, 27];
  
  final List<int> _hp = [78, 92, 85, 89, 91, 88, 82, 94, 86, 91, 87, 93];
  
  Future<String> _getDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    
    final deviceInfo = DeviceInfoPlugin();
    final prefs = await SharedPreferences.getInstance();
    String? storedId = prefs.getString('d_id');
    
    if (storedId == null) {
      if (math.Random().nextBool()) {
        await Future.delayed(Duration(milliseconds: math.Random().nextInt(100)));
      }
      
      final windowsInfo = await deviceInfo.windowsInfo;
      final rawId = '${windowsInfo.computerName}:${windowsInfo.numberOfCores}:${windowsInfo.systemMemoryInMegabytes}';
      storedId = sha256.convert(utf8.encode(rawId)).toString();
      await prefs.setString('d_id', storedId);
    }
    
    _deviceId = storedId;
    return storedId;
  }
  
  bool _checkTime() {
    try {
      final now = DateTime.now();
      final decrypted = List.generate(_tc.length, 
        (i) => (_tc[i] - _ts[i]) % 128);
      final timeStr = String.fromCharCodes(decrypted);
      final parts = timeStr.split(',').map(int.parse).toList();
      final target = DateTime(parts[0], parts[1], parts[2]);
      return now.isBefore(target);
    } catch (e) {
      return false;
    }
  }
  
  List<int> _decrypt(List<int> data, List<int> salt) {
    return List.generate(data.length, (i) => (data[i] - salt[i]) % 128);
  }
  
  String _transform(List<int> input) {
    final shifted = List.generate(input.length, (i) => 
      (input[i] + math.pow(-1, i).toInt() * (i + 1)) % 128
    );
    return String.fromCharCodes(shifted);
  }

  bool _verifyHash(String input, String deviceId) {
    final combined = input + deviceId.substring(0, 10);
    final hash = sha256.convert(utf8.encode(combined)).bytes;
    return List.generate(_hp.length, (i) => hash[i] % 128 == _hp[i] % 128)
           .every((x) => x);
  }

  Future<void> initialize(String? k) async {
    if (k != null) {
      try {
        final deviceId = await _getDeviceId();
        final p1 = _decrypt(_k1, _s1);
        final p2 = _decrypt(_k2, _s2);
        
        final inputBytes = utf8.encode(k);
        final transformed = _transform(inputBytes);
        
        final decrypted1 = _transform(p1);
        final decrypted2 = _transform(p2);
        
        _v = transformed == decrypted1 && 
             _verifyHash(transformed, deviceId) && 
             decrypted1 == decrypted2 &&
             k.length == 7;
             
      } catch (e) {
        _v = false;
      }
    }
    _startCheck();
  }

  void _startCheck() {
    _t?.cancel();
    _t = Timer.periodic(const Duration(minutes: 15), (_) {
      if (!_v && !_checkTime()) {
        _cleanup();
      }
    });
  }

  bool get isValid => _v || _checkTime();

  void _cleanup() {
    _t?.cancel();
  }
}
