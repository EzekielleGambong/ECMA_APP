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

  Future<Map<String, dynamic>> scanBubbleSheet(
    File imageFile,
    BubbleSheetConfig config,
  ) async {
    try {
      // Pre-process the image
      final processedImage = await _preprocessImage(imageFile);
      
      // Convert to InputImage for ML Kit
      final inputImage = InputImage.fromFilePath(processedImage.path);

      // Detect text for student information
      final recognizedText = await _textDetector.processImage(inputImage);
      
      // Extract student information
      final studentInfo = await _extractStudentInfo(recognizedText);

      // Process the bubble sheet answers
      final answers = await _processAnswers(processedImage, config);

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
    }
  }

  Future<File> _preprocessImage(File imageFile) async {
    // Load the image
    final bytes = await imageFile.readAsBytes();
    var image = img.decodeImage(bytes);
    
    if (image == null) throw Exception('Failed to decode image');

    // Convert to grayscale
    image = img.grayscale(image);

    // Adjust brightness and contrast
    image = img.adjustColor(
      image,
      brightness: 0.2,  // Increase brightness by 20%
      contrast: 0.2,    // Increase contrast by 20%
      saturation: 0.0,  // Remove color
    );

    // Convert to binary (black and white)
    image = img.colorOffset(image, alpha: 0, red: -128, green: -128, blue: -128);

    // Save processed image
    final processedFile = File('${imageFile.path}_processed.jpg');
    await processedFile.writeAsBytes(img.encodeJpg(image));
    
    return processedFile;
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

  Future<Map<String, List<String>>> _processAnswers(File imageFile, BubbleSheetConfig config) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');

    final answers = <String, List<String>>{};
    
    for (final section in config.sections) {
      final sectionAnswers = <String>[];
      
      for (final question in section.questions) {
        var maxBrightness = 0.0;
        var selectedBubble = '';
        
        for (final bubble in question.bubbles) {
          final brightness = _calculateBrightness(image, bubble.x, bubble.y);
          if (brightness > maxBrightness) {
            maxBrightness = brightness;
            selectedBubble = bubble.value;
          }
        }
        
        sectionAnswers.add(selectedBubble);
      }
      
      answers[section.id] = sectionAnswers;
    }
    
    return answers;
  }

  double _calculateBrightness(img.Image image, int x, int y) {
    final pixel = image.getPixel(x, y);
    final r = pixel.r;
    final g = pixel.g;
    final b = pixel.b;
    return (r + g + b) / (3 * 255); // Normalize to 0-1 range
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
