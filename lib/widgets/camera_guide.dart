import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class CameraGuide extends StatefulWidget {
  final double screenWidth;
  final double screenHeight;
  
  const CameraGuide({
    Key? key, 
    required this.screenWidth,
    required this.screenHeight,
  }) : super(key: key);

  @override
  State<CameraGuide> createState() => _CameraGuideState();
}

class _CameraGuideState extends State<CameraGuide> {
  String? _deviceModel;
  bool _isInitialized = false;
  late double _guideScale;
  late double _guideOpacity;
  
  @override
  void initState() {
    super.initState();
    _detectDevice();
    _guideScale = 0.8; // Default scale
    _guideOpacity = 0.5; // Default opacity
  }

  Future<void> _detectDevice() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      setState(() {
        _deviceModel = androidInfo.model;
        _isInitialized = true;
        // Adjust guide based on known device characteristics
        _adjustGuideForDevice(androidInfo.model);
      });
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      setState(() {
        _deviceModel = iosInfo.model;
        _isInitialized = true;
        // Adjust guide based on known device characteristics
        _adjustGuideForDevice(iosInfo.model);
      });
    }
  }

  void _adjustGuideForDevice(String model) {
    // Adjust guide parameters based on device model
    // These are example adjustments - you should fine-tune based on testing
    switch (model.toLowerCase()) {
      case String m when m.contains('iphone 13'):
      case String m when m.contains('iphone 14'):
        _guideScale = 0.85;
        _guideOpacity = 0.6;
        break;
      case String m when m.contains('samsung s21'):
      case String m when m.contains('samsung s22'):
        _guideScale = 0.82;
        _guideOpacity = 0.55;
        break;
      case String m when m.contains('pixel'):
        _guideScale = 0.8;
        _guideOpacity = 0.5;
        break;
      default:
        // Default values for unknown devices
        _guideScale = 0.8;
        _guideOpacity = 0.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Main scanning area guide
        _buildScanningGuide(),
        // Tent-style guides
        _buildTentGuides(),
        // Device-specific instructions
        _buildDeviceInstructions(),
      ],
    );
  }

  Widget _buildScanningGuide() {
    return Center(
      child: Container(
        width: widget.screenWidth * _guideScale,
        height: widget.screenHeight * _guideScale,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white.withOpacity(_guideOpacity),
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }

  Widget _buildTentGuides() {
    return Stack(
      children: [
        // Top tent guide
        Positioned(
          top: widget.screenHeight * 0.1,
          left: widget.screenWidth * 0.1,
          right: widget.screenWidth * 0.1,
          child: Container(
            height: 2,
            color: Colors.white.withOpacity(_guideOpacity * 0.8),
          ),
        ),
        // Bottom tent guide
        Positioned(
          bottom: widget.screenHeight * 0.1,
          left: widget.screenWidth * 0.1,
          right: widget.screenWidth * 0.1,
          child: Container(
            height: 2,
            color: Colors.white.withOpacity(_guideOpacity * 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceInstructions() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Device: $_deviceModel',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(height: 4),
            const Text(
              'Hold phone parallel to paper\nAlign edges with guides',
              style: TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
