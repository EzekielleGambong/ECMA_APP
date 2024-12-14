import 'dart:io';
import 'dart:math';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import 'package:collection/collection.dart';
import '../models/bubble_sheet_config.dart';

class BubbleSheetScanner {
  static final BubbleSheetScanner _instance = BubbleSheetScanner._internal();
  factory BubbleSheetScanner() => _instance;
  BubbleSheetScanner._internal();

  final _textDetector = GoogleMlKit.vision.textRecognizer();
  final _imageLabeler = GoogleMlKit.vision.imageLabeler();
  bool _isProcessing = false;

  Future<Map<String, dynamic>> scanBubbleSheet(
    File imageFile,
    BubbleSheetConfig config,
  ) async {
    if (_isProcessing) {
      return {'error': 'Scanner is busy processing another frame', 'processed': false};
    }

    _isProcessing = true;
    try {
      // Pre-process the image
      final processedImage = await _preprocessImage(imageFile);
      
      // Detect corner squares
      final corners = await _detectCornerSquares(processedImage, config.cornerSquares);
      if (corners == null) {
        return {'error': 'Could not detect corner squares', 'processed': false};
      }

      // Convert to InputImage for ML Kit
      final inputImage = InputImage.fromFilePath(processedImage.path);

      // Detect text for student information
      final recognizedText = await _textDetector.processImage(inputImage);
      
      // Extract student information
      final studentInfo = await _extractStudentInfo(recognizedText);

      // Process the bubble sheet answers with perspective correction
      final answers = await _processAnswers(processedImage, config, corners);

      // Calculate confidence scores
      final confidenceScores = _calculateConfidenceScores(answers);

      return {
        'studentInfo': studentInfo,
        'answers': answers,
        'confidenceScores': confidenceScores,
        'timestamp': DateTime.now().toIso8601String(),
        'examId': config.examCode,
        'processed': true,
      };
    } catch (e) {
      return {
        'error': 'Error scanning bubble sheet: ${e.toString()}',
        'processed': false,
      };
    } finally {
      _isProcessing = false;
    }
  }

  Future<File> _preprocessImage(File imageFile) async {
    // Load the image
    final bytes = await imageFile.readAsBytes();
    var image = img.decodeImage(bytes);
    
    if (image == null) throw Exception('Failed to decode image');

    // Resize image if too large
    if (image.width > 1920 || image.height > 1920) {
      final newHeight = ((1920 * image.height) ~/ image.width).toInt();
      image = img.copyResize(
        image,
        width: 1920,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );
    }

    // Convert to grayscale
    image = img.grayscale(image);

    // Apply adaptive thresholding
    image = _adaptiveThreshold(image, 11, 2);

    // Save processed image
    final processedFile = File('${imageFile.path}_processed.jpg');
    await processedFile.writeAsBytes(img.encodeJpg(image));
    
    return processedFile;
  }

  img.Image _adaptiveThreshold(img.Image src, int kernelSize, int c) {
    final result = img.Image(width: src.width, height: src.height);
    final kernel = kernelSize ~/ 2;

    for (var y = 0; y < src.height; y++) {
      for (var x = 0; x < src.width; x++) {
        var sum = 0;
        var count = 0;

        // Calculate local mean
        for (var ky = -kernel; ky <= kernel; ky++) {
          for (var kx = -kernel; kx <= kernel; kx++) {
            final px = x + kx;
            final py = y + ky;
            if (px >= 0 && px < src.width && py >= 0 && py < src.height) {
              final pixel = src.getPixel(px, py);
              sum += ((pixel.r + pixel.g + pixel.b) ~/ 3).toInt();
              count++;
            }
          }
        }

        final mean = (sum ~/ count).toInt();
        final pixel = src.getPixel(x, y);
        final intensity = ((pixel.r + pixel.g + pixel.b) ~/ 3).toInt();
        
        result.setPixel(x, y, 
          img.ColorRgb8(
            intensity < (mean - c) ? 0 : 255,
            intensity < (mean - c) ? 0 : 255,
            intensity < (mean - c) ? 0 : 255,
          )
        );
      }
    }
    return result;
  }

  Future<List<Point>?> _detectCornerSquares(File imageFile, List<CornerSquare> expectedCorners) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return null;

    final corners = <Point>[];
    for (final corner in expectedCorners) {
      final x = (corner.x * image.width).toInt();
      final y = (corner.y * image.height).toInt();
      final size = corner.size.toInt();

      var found = false;
      // Search in a small area around the expected position
      for (var dy = -10; dy <= 10 && !found; dy++) {
        for (var dx = -10; dx <= 10 && !found; dx++) {
          final testX = x + dx;
          final testY = y + dy;
          if (_isCornerSquare(image, testX, testY, size)) {
            corners.add(Point(testX.toDouble(), testY.toDouble()));
            found = true;
          }
        }
      }
      
      if (!found) return null;
    }

    return corners;
  }

  bool _isCornerSquare(img.Image image, int x, int y, int size) {
    if (x < 0 || x >= image.width || y < 0 || y >= image.height) return false;

    // Check if the center pixel is black
    final centerPixel = image.getPixel(x, y);
    if (_getBrightness(centerPixel) > 0.5) return false;

    // Check the surrounding area
    var blackCount = 0;
    final halfSize = size ~/ 2;
    
    for (var dy = -halfSize; dy <= halfSize; dy++) {
      for (var dx = -halfSize; dx <= halfSize; dx++) {
        final px = x + dx;
        final py = y + dy;
        if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
          final pixel = image.getPixel(px, py);
          if (_getBrightness(pixel) < 0.5) blackCount++;
        }
      }
    }

    // The square should be mostly black
    return blackCount > ((size * size * 0.7).toInt());
  }

  double _getBrightness(img.Pixel pixel) {
    return (pixel.r + pixel.g + pixel.b) / (3.0 * 255.0);
  }

  Future<Map<String, List<String>>> _processAnswers(
    File imageFile,
    BubbleSheetConfig config,
    List<Point> corners,
  ) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');

    // Apply perspective correction using corner points
    final correctedImage = _correctPerspective(image, corners);

    final answers = <String, List<String>>{};
    
    for (final section in config.sections) {
      final sectionAnswers = <String>[];
      
      for (final question in section.questions) {
        var maxBrightness = 0.0;
        var selectedBubble = '';
        
        for (final bubble in question.bubbles) {
          // Calculate absolute pixel coordinates
          final x = (bubble.x * correctedImage.width).toInt();
          final y = (bubble.y * correctedImage.height).toInt();
          
          // Calculate average brightness in a small area around the bubble
          var totalBrightness = 0.0;
          const areaSize = 3;
          var count = 0;
          
          for (var dy = -areaSize; dy <= areaSize; dy++) {
            for (var dx = -areaSize; dx <= areaSize; dx++) {
              final px = x + dx;
              final py = y + dy;
              if (px >= 0 && px < correctedImage.width && py >= 0 && py < correctedImage.height) {
                totalBrightness += _getBrightness(correctedImage.getPixel(px, py));
                count++;
              }
            }
          }
          
          final avgBrightness = totalBrightness / count;
          if (avgBrightness > maxBrightness) {
            maxBrightness = avgBrightness;
            selectedBubble = bubble.value;
          }
        }
        
        sectionAnswers.add(selectedBubble);
      }
      
      answers[section.id] = sectionAnswers;
    }
    
    return answers;
  }

  img.Image _correctPerspective(img.Image image, List<Point> corners) {
    // Implement perspective correction using the detected corner points
    // This is a simplified version - you may want to use a more sophisticated algorithm
    return image;
  }

  Future<Map<String, String>> _extractStudentInfo(RecognizedText recognizedText) async {
    final studentInfo = <String, String>{};
    
    // Look for patterns like "Name:" or "ID:" and extract the following text
    for (final block in recognizedText.blocks) {
      final text = block.text.toLowerCase();
      
      if (text.contains('name:')) {
        final nameMatch = RegExp(r'name:\s*(.+)').firstMatch(text);
        if (nameMatch != null) {
          studentInfo['name'] = nameMatch.group(1)?.trim() ?? '';
        }
      }
      
      if (text.contains('id:')) {
        final idMatch = RegExp(r'id:\s*(.+)').firstMatch(text);
        if (idMatch != null) {
          studentInfo['id'] = idMatch.group(1)?.trim() ?? '';
        }
      }
    }
    
    return studentInfo;
  }

  Map<String, double> _calculateConfidenceScores(Map<String, List<String>> answers) {
    final totalQuestions = answers.values.fold(0, (acc, answers) => acc + answers.length);
    final answeredQuestions = answers.values.fold(0, (acc, answers) => acc + answers.where((a) => a.isNotEmpty).length);
    
    return {
      'overall': answeredQuestions / totalQuestions,
      'clarity': _calculateClarityScore(answers),
    };
  }

  double _calculateClarityScore(Map<String, List<String>> answers) {
    // Implement a more sophisticated clarity scoring system
    // This is a simplified version
    return 0.8; // Default high confidence for now
  }

  Future<void> dispose() async {
    await _textDetector.close();
    await _imageLabeler.close();
  }
}

class Point {
  final double x;
  final double y;
  
  Point(this.x, this.y);
}
