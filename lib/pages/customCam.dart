import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class CustomCam extends StatefulWidget {
  const CustomCam({Key? key}) : super(key: key);

  @override
  CustomCamState createState() => CustomCamState();
}

class CustomCamState extends State<CustomCam> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> cameras = [];
  bool isInitialized = false;
  bool isProcessing = false;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentZoom = 1.0;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;
  bool _isFocused = false;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      initializeCamera();
    }
  }

  Future<void> initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showError('No cameras found');
        return;
      }

      // Select the best camera for document scanning (usually back camera)
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.max,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);
      
      // Get zoom range
      await Future.wait([
        _controller!.getMaxZoomLevel().then((value) => _maxAvailableZoom = value),
        _controller!.getMinZoomLevel().then((value) => _minAvailableZoom = value),
        _controller!.getMinExposureOffset().then((value) => _minAvailableExposureOffset = value),
        _controller!.getMaxExposureOffset().then((value) => _maxAvailableExposureOffset = value),
      ]);
      
      if (!mounted) return;
      
      setState(() {
        isInitialized = true;
      });
    } catch (e) {
      _showError('Error initializing camera: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _setFocusPoint(TapDownDetails details) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final size = MediaQuery.of(context).size;
    final offset = Offset(
      details.localPosition.dx / size.width,
      details.localPosition.dy / size.height,
    );

    try {
      await _controller!.setFocusPoint(offset);
      await _controller!.setExposurePoint(offset);
      
      setState(() => _isFocused = true);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _isFocused = false);
    } catch (e) {
      _showError('Error setting focus: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      if (_isFlashOn) {
        await _controller!.setFlashMode(FlashMode.off);
      } else {
        await _controller!.setFlashMode(FlashMode.torch);
      }
      setState(() => _isFlashOn = !_isFlashOn);
    } catch (e) {
      _showError('Error toggling flash: $e');
    }
  }

  Future<void> takePicture() async {
    if (!isInitialized || _controller == null || isProcessing) return;

    setState(() => isProcessing = true);

    try {
      final XFile image = await _controller!.takePicture();
      
      // Process the image
      final File processedImage = await _processImage(File(image.path));
      
      if (mounted) {
        Navigator.pop(context, processedImage);
      }
    } catch (e) {
      _showError('Error taking picture: $e');
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Future<File> _processImage(File imageFile) async {
    // Read the image
    final bytes = await imageFile.readAsBytes();
    var image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');

    // Apply image processing
    image = img.adjustColor(image, 
      contrast: 1.2,
      brightness: 1.1,
      saturation: 0.8,
    );
    
    // Enhance edges for better document detection
    image = img.sobel(image);

    // Save the processed image
    final tempDir = await getTemporaryDirectory();
    final processedFile = File('${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await processedFile.writeAsBytes(img.encodeJpg(image, quality: 90));
    
    return processedFile;
  }

  @override
  Widget build(BuildContext context) {
    if(!isInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
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
            GestureDetector(
              onTapDown: _setFocusPoint,
              onScaleUpdate: (details) async {
                _currentZoom = (_currentZoom * details.scale)
                    .clamp(_minAvailableZoom, _maxAvailableZoom);
                await _controller!.setZoomLevel(_currentZoom);
              },
              child: Transform.scale(
                scale: scale,
                child: Center(
                  child: CameraPreview(_controller!),
                ),
              ),
            ),
            if (_isFocused)
              const Center(
                child: Icon(
                  Icons.center_focus_strong,
                  color: Colors.white,
                  size: 80,
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
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.black45,
                child: const Text(
                  'Align Answer Sheet Within Frame',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
              ),
            ),
            // Camera controls
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    IconButton(
                      onPressed: _toggleFlash,
                      icon: Icon(
                        _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    GestureDetector(
                      onTap: takePicture,
                      child: Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 5,
                          ),
                        ),
                        child: Center(
                          child: isProcessing
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Icon(
                                Icons.camera,
                                color: Colors.white,
                                size: 40,
                              ),
                        ),
                      ),
                    ),
                    // Exposure control
                    IconButton(
                      onPressed: () async {
                        _currentExposureOffset = await showDialog(
                          context: context,
                          builder: (context) => ExposureDialog(
                            currentExposure: _currentExposureOffset,
                            minExposure: _minAvailableExposureOffset,
                            maxExposure: _maxAvailableExposureOffset,
                            onChanged: (value) async {
                              await _controller?.setExposureOffset(value);
                              setState(() => _currentExposureOffset = value);
                            },
                          ),
                        ) ?? _currentExposureOffset;
                      },
                      icon: const Icon(
                        Icons.exposure,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 30), // Balance spacing
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExposureDialog extends StatefulWidget {
  final double currentExposure;
  final double minExposure;
  final double maxExposure;
  final Function(double) onChanged;

  const ExposureDialog({
    Key? key,
    required this.currentExposure,
    required this.minExposure,
    required this.maxExposure,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<ExposureDialog> createState() => _ExposureDialogState();
}

class _ExposureDialogState extends State<ExposureDialog> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.currentExposure;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adjust Exposure'),
      content: Slider(
        value: _currentValue,
        min: widget.minExposure,
        max: widget.maxExposure,
        onChanged: (value) {
          setState(() => _currentValue = value);
          widget.onChanged(value);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _currentValue),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  const GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw corner boxes
    final double boxSize = size.width * 0.1;
    final double padding = 20.0;

    // Helper function to draw corner box with inner lines
    void drawCornerBox(Offset position) {
      final rect = Rect.fromLTWH(position.dx, position.dy, boxSize, boxSize);
      canvas.drawRect(rect, paint);
      
      // Draw inner cross
      canvas.drawLine(
        Offset(position.dx + boxSize * 0.25, position.dy + boxSize * 0.5),
        Offset(position.dx + boxSize * 0.75, position.dy + boxSize * 0.5),
        paint,
      );
      canvas.drawLine(
        Offset(position.dx + boxSize * 0.5, position.dy + boxSize * 0.25),
        Offset(position.dx + boxSize * 0.5, position.dy + boxSize * 0.75),
        paint,
      );
    }

    // Draw all corner boxes with inner crosses
    drawCornerBox(Offset(padding, padding)); // Top-left
    drawCornerBox(Offset(size.width - boxSize - padding, padding)); // Top-right
    drawCornerBox(Offset(padding, size.height - boxSize - padding)); // Bottom-left
    drawCornerBox(Offset(size.width - boxSize - padding, size.height - boxSize - padding)); // Bottom-right

    // Draw alignment grid lines with reduced opacity
    paint.color = Colors.white.withOpacity(0.3);
    paint.strokeWidth = 1.0;

    // Draw horizontal and vertical lines
    for (int i = 1; i < 3; i++) {
      final double dy = size.height * (i / 3);
      final double dx = size.width * (i / 3);
      
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
