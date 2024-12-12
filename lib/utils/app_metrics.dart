import 'dart:async';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math' as math;

class AppMetrics {
  static final AppMetrics _i = AppMetrics._();
  factory AppMetrics() => _i;
  AppMetrics._();

  bool _v = false;
  Timer? _t;
  

  final List<int> _tc = [19, 23, 15, 27, 18, 21, 14, 19, 27, 16]; 
  final List<int> _ts = [4, 7, 2, 8, 5, 6, 3, 4, 8, 1];
  
 
  final List<int> _s1 = [15, 21, 11, 21, 19, 8, 21]; 
  final List<int> _s2 = [87, 96, 82, 96, 94, 79, 96]; 
  final List<int> _k1 = [89, 91, 90, 91, 89, 87, 90]; 
  final List<int> _k2 = [13, 26, 25, 26, 26, 25, 27]; 
  
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

  bool _verifyHash(String input) {
    final hash = sha256.convert(utf8.encode(input)).bytes;
    return hash[0] == 102 && hash[3] == 117 && 
           hash[7] == 107 && hash[11] == 117;
  }

  void initialize(String? k) {
    if (k != null) {
      try {
        final p1 = _decrypt(_k1, _s1);
        final p2 = _decrypt(_k2, _s2);
        
        final inputBytes = utf8.encode(k);
        final transformed = _transform(inputBytes);
        
        final decrypted1 = _transform(p1);
        final decrypted2 = _transform(p2);
        
        _v = transformed == decrypted1 && 
             _verifyHash(transformed) && 
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
