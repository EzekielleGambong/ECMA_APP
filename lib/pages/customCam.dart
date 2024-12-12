import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class CustomCam extends StatefulWidget {
  const CustomCam({Key? key}) : super(key: key);

  @override
  CustomCamState createState() => CustomCamState();
}

class CustomCamState extends State<CustomCam> {
  CameraController? _controller;
  List<CameraDescription> cameras = [];
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _controller = CameraController(
          cameras[0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            isInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> takePicture() async {
    if (!isInitialized || _controller == null) return;

    try {
      final XFile image = await _controller!.takePicture();
      if (mounted) {
        Navigator.pop(context, File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error Taking Picture'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if(!isInitialized || _controller == null) {
      return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: CircularProgressIndicator(),
          )
      );
    }

    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    final scale = 1 / ((_controller!.value.aspectRatio) * deviceRatio);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(
              scale: scale,
              child: Center(
                child: CameraPreview(_controller!),
              ),
            ),
            const Positioned.fill(
              child: CustomPaint(
                painter: GridPainter(),
              ),
            ),
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Align Answer Sheet Within Frame',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(1.0, 1.0),
                        blurRadius: 3.0,
                        color: Colors.black
                      )
                    ]
                  ),
                ),
              )
            ),
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Close button on the left
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    )
                  ),
                  // Camera button in the center
                  GestureDetector(
                    onTap: takePicture,
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white, 
                          width: 5
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.camera,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ),
          ],
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  const GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw horizontal lines
    for (int i = 1; i < 3; i++) {
      final double dy = size.height * (i / 3);
      canvas.drawLine(
        Offset(0, dy),
        Offset(size.width, dy),
        paint,
      );
    }

    // Draw vertical lines
    for (int i = 1; i < 3; i++) {
      final double dx = size.width * (i / 3);
      canvas.drawLine(
        Offset(dx, 0),
        Offset(dx, size.height),
        paint,
      );
    }

    // Draw border rectangle
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
