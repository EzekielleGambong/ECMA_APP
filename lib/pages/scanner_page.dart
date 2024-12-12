import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../core/image_processor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({Key? key}) : super(key: key);

  @override
  _ScannerPageState createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  CameraController? _controller;
  bool _isProcessing = false;
  bool _isSheetDetected = false;
  Rect? _sheetRect; // To store the detected sheet's boundaries
  img.Image? _lastImage; // Store the last captured image
  String _selectedPaperSize = 'A4'; // Default paper size
  int _numQuestions = ImageProcessor.defaultQuestionsPerPage;
  int _numOptions = ImageProcessor.defaultOptionsPerQuestion;
  List<List<List<bool>>> _allScanResults = []; // Store all scan results for analysis
  AnswerKey? _selectedAnswerKey;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // Placeholder for the answer key. In a real app, this would come from user input.
  // Each inner list represents the correct options for a question (true if correct, false otherwise).
  final List<List<bool>> _answerKey = List.generate(
    ImageProcessor.defaultQuestionsPerPage,
    (_) => List.generate(ImageProcessor.defaultOptionsPerQuestion, (index) => index == 0),
  );

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();

    _controller!.startImageStream((CameraImage image) {
      if (_isProcessing) return;

      _isProcessing = true;
      _processCameraImage(image);
    });

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _processCameraImage(CameraImage cameraImage) async {
    img.Image? image = ImageProcessor.convertYUV420ToImage(cameraImage);
    if (image == null) {
      _isProcessing = false;
      return;
    }

    setState(() {
      _lastImage = image;
    });

    // Apply Canny edge detection to find edges in the image
    img.Image edges = ImageProcessor.applyCannyEdgeDetection(image);

    // Find contours based on the detected edges
    List<Point> contours = ImageProcessor.findContours(edges);

    // Detect the answer sheet's ROI (Region of Interest)
    Rect? sheetRect = _detectAnswerSheet(contours, Size(image.width.toDouble(), image.height.toDouble()));

    if (sheetRect != null) {
      // Detect bubbles within the detected answer sheet's ROI
      List<List<bool>> results = await _detectBubblesInROI(image, sheetRect);

      // Calculate the raw score
      int score = _calculateScore(results);

      // Handle the scan results
      _handleScanResults(results, score);

      // Store the results for later analysis
      _allScanResults.add(results);
    }

    if (mounted) {
      setState(() {
        _isSheetDetected = sheetRect != null;
        _sheetRect = sheetRect;
        _isProcessing = false;
      });
    } else {
      _isProcessing = false;
    }
  }

  // Detects the answer sheet within the contours found in the camera image.
  Rect? _detectAnswerSheet(List<Point> contours, Size imageSize) {
    double maxArea = 0;
    Rect? largestContour;

    for (int i = 0; i < contours.length; i++) {
      // Approximate the contour to a polygon
      List<Point> polygon = _approximatePolygon(contours, i);

      // Check if the polygon has 4 corners (quadrilateral)
      if (polygon.length == 4) {
        // Calculate the area of the polygon
        double area = _calculatePolygonArea(polygon);

        // Check if the area is within a reasonable range and larger than the current max
        if (area > imageSize.width * imageSize.height * 0.1 && area > maxArea) {
          maxArea = area;
          largestContour = _polygonToRect(polygon);
        }
      }
    }

    return largestContour;
  }

  // Approximates a contour to a polygon using the Douglas-Peucker algorithm.
  List<Point> _approximatePolygon(List<Point> contour, int startIndex) {
    List<Point> result = [];
    double epsilon = 0.02 * _calculateContourLength(contour);
    _douglasPeucker(contour, startIndex, epsilon, result);
    return result;
  }

  // Calculates the length of a contour.
  double _calculateContourLength(List<Point> contour) {
    double length = 0;
    for (int i = 0; i < contour.length - 1; i++) {
      length += _distance(contour[i], contour[i + 1]);
    }
    length += _distance(contour.last, contour.first);
    return length;
  }

  // Calculates the distance between two points.
  double _distance(Point p1, Point p2) {
    return math.sqrt(math.pow(p1.x - p2.x, 2) + math.pow(p1.y - p2.y, 2));
  }

  // Applies the Douglas-Peucker algorithm to simplify a list of points (polygon approximation).
  void _douglasPeucker(List<Point> points, int startIndex, double epsilon, List<Point> result) {
    // Find the point with the maximum distance from the line between the start and end points
    double dmax = 0;
    int index = startIndex;
    int endIndex = (startIndex + points.length - 1) % points.length;

    for (int i = (startIndex + 1) % points.length; i != endIndex; i = (i + 1) % points.length) {
      double d = _perpendicularDistance(points[i], points[startIndex], points[endIndex]);
      if (d > dmax) {
        index = i;
        dmax = d;
      }
    }

    // If max distance is greater than epsilon, recursively simplify
    if (dmax > epsilon) {
      // Recursive calls to further simplify the polygon
      _douglasPeucker(points, startIndex, epsilon, result);
      _douglasPeucker(points, index, epsilon, result);
    } else {
      // Add the start and end points to the result
      result.add(points[startIndex]);
      result.add(points[endIndex]);
    }
  }

  // Calculates the perpendicular distance of a point from a line segment.
  double _perpendicularDistance(Point p, Point lineStart, Point lineEnd) {
    double area =
        ((lineEnd.x - lineStart.x) * (p.y - lineStart.y) - (lineEnd.y - lineStart.y) * (p.x - lineStart.x)).abs().toDouble();
    double bottom = math.sqrt(math.pow(lineEnd.x - lineStart.x, 2) + math.pow(lineEnd.y - lineStart.y, 2));
    return area / bottom;
  }

  // Calculates the area of a polygon.
  double _calculatePolygonArea(List<Point> polygon) {
    double area = 0;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      area += (polygon[j].x + polygon[i].x) * (polygon[j].y - polygon[i].y);
      j = i;
    }
    return area.abs() / 2;
  }

  // Converts a polygon (list of points) to a Rect.
  Rect _polygonToRect(List<Point> polygon) {
    int minX = polygon[0].x;
    int maxX = polygon[0].x;
    int minY = polygon[0].y;
    int maxY = polygon[0].y;

    for (int i = 1; i < polygon.length; i++) {
      if (polygon[i].x < minX) {
        minX = polygon[i].x;
      }
      if (polygon[i].x > maxX) {
        maxX = polygon[i].x;
      }
      if (polygon[i].y < minY) {
        minY = polygon[i].y;
      }
      if (polygon[i].y > maxY) {
        maxY = polygon[i].y;
      }
    }

    return Rect.fromLTRB(minX.toDouble(), minY.toDouble(), maxX.toDouble(), maxY.toDouble());
  }

  // Detects filled bubbles within a specified region of interest (ROI) in the image.
  Future<List<List<bool>>> _detectBubblesInROI(img.Image image, Rect roi) async {
    // Extract the ROI from the image
    img.Image croppedImage = img.copyCrop(
      image,
      x: roi.left.toInt(),
      y: roi.top.toInt(),
      width: roi.width.toInt(),
      height: roi.height.toInt(),
    );

    // Apply grayscale and adaptive threshold
    img.Image grayscale = img.grayscale(croppedImage);
    img.Image binaryImage = ImageProcessor.applyAdaptiveThreshold(grayscale);

    // Detect bubbles in the cropped image, passing the number of questions, options, and paper size
    return ImageProcessor.detectBubbles(binaryImage, _numQuestions, _numOptions);
  }

  // handles the scan results
  void _handleScanResults(List<List<bool>> results, int score) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Scan Results'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < results.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text('Question ${i + 1}: ${results[i].map((e) => e ? '1' : '0').join(', ')}'),
                  ),
                const SizedBox(height: 16),
                Text('Raw Score: $score', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _saveImage() async {
    if (_lastImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image to save')),
      );
      return;
    }

    try {
      // Save to local storage
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final localPath = '${directory.path}/scan_$timestamp.png';
      final file = File(localPath);
      await file.writeAsBytes(img.encodePng(_lastImage!));

      // Upload to Firebase Storage
      final storageRef = _storage.ref().child('scans/scan_$timestamp.png');
      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      // Save metadata to Firestore
      await _firestore.collection('scanned_images').add({
        'timestamp': FieldValue.serverTimestamp(),
        'imageUrl': downloadUrl,
        'answerKeyId': _selectedAnswerKey?.id,
        'paperSize': _selectedPaperSize,
        'numQuestions': _numQuestions,
        'numOptions': _numOptions,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving image: $e')),
      );
    }
  }

  int _calculateScore(List<List<bool>> results) {
    if (_selectedAnswerKey == null) return 0;

    int score = 0;
    for (int i = 0; i < results.length; i++) {
      if (i < _selectedAnswerKey!.answers.length) {
        if (_selectedAnswerKey!.bonusQuestions[i]) {
          // Bonus question - any answer is correct
          score++;
        } else {
          // Regular question - check against answer key
          int correctAnswer = _selectedAnswerKey!.answers[i].codeUnitAt(0) - 'A'.codeUnitAt(0);
          if (results[i][correctAnswer]) {
            score++;
          }
        }
      }
    }
    return score;
  }

  void _showItemAnalysis() {
    if (_allScanResults.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No scan results available for analysis')),
      );
      return;
    }

    // Calculate statistics
    List<Map<String, dynamic>> questionStats = List.generate(_numQuestions, (index) {
      int correct = 0;
      Map<int, int> incorrectDistribution = {};

      for (var result in _allScanResults) {
        if (index < result.length) {
          bool isCorrect = false;
          if (_selectedAnswerKey != null && index < _selectedAnswerKey!.answers.length) {
            if (_selectedAnswerKey!.bonusQuestions[index]) {
              isCorrect = true;
            } else {
              int correctAnswer = _selectedAnswerKey!.answers[index].codeUnitAt(0) - 'A'.codeUnitAt(0);
              isCorrect = result[index][correctAnswer];
            }
          }

          if (isCorrect) {
            correct++;
          } else {
            for (int i = 0; i < result[index].length; i++) {
              if (result[index][i]) {
                incorrectDistribution[i] = (incorrectDistribution[i] ?? 0) + 1;
              }
            }
          }
        }
      }

      return {
        'questionNumber': index + 1,
        'correctCount': correct,
        'incorrectCount': _allScanResults.length - correct,
        'incorrectDistribution': incorrectDistribution,
        'difficulty': 1 - (correct / _allScanResults.length),
      };
    });

    // Sort questions by difficulty
    questionStats.sort((a, b) => b['difficulty'].compareTo(a['difficulty']));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Item Analysis'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Responses: ${_allScanResults.length}'),
              const Divider(),
              ...questionStats.map((stat) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${stat['questionNumber']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Correct: ${stat['correctCount']}'),
                    Text('Incorrect: ${stat['incorrectCount']}'),
                    Text('Difficulty: ${(stat['difficulty'] * 100).toStringAsFixed(1)}%'),
                    if (stat['incorrectDistribution'].isNotEmpty)
                      Text('Incorrect Answers: ' +
                          stat['incorrectDistribution']
                              .entries
                              .map((e) =>
                                  '${String.fromCharCode(e.key + 'A'.codeUnitAt(0))}: ${e.value}')
                              .join(', ')),
                    const Divider(),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () => _exportAnalysis(questionStats),
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAnalysis(List<Map<String, dynamic>> stats) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/analysis_$timestamp.csv');

      final buffer = StringBuffer();
      buffer.writeln('Question,Correct,Incorrect,Difficulty,Incorrect Distribution');

      for (var stat in stats) {
        buffer.write('${stat['questionNumber']},');
        buffer.write('${stat['correctCount']},');
        buffer.write('${stat['incorrectCount']},');
        buffer.write('${(stat['difficulty'] * 100).toStringAsFixed(1)}%,');
        buffer.writeln(stat['incorrectDistribution']
            .entries
            .map((e) => '${String.fromCharCode(e.key + 'A'.codeUnitAt(0))}:${e.value}')
            .join(';'));
      }

      await file.writeAsString(buffer.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis exported to ${file.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting analysis: $e')),
      );
    }
  }

  Future<void> _selectAnswerKey(BuildContext context) async {
    final result = await showDialog<AnswerKey>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Answer Key'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('answer_keys').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final answerKey = AnswerKey.fromFirestore(doc);
                  return ListTile(
                    title: Text(answerKey.name),
                    subtitle: Text('Questions: ${answerKey.answers.length}'),
                    onTap: () {
                      Navigator.of(context).pop(answerKey);
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AnswerKeyManager(),
                ),
              );
            },
            child: const Text('Create New'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _selectedAnswerKey = result;
        _numQuestions = result.answers.length;
      });
    }
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Instructions'),
        content: const Text('Here are the instructions for using the scanner.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Answer Sheet Scanner'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: () => _selectAnswerKey(context),
            icon: const Icon(Icons.assignment),
            tooltip: 'Select Answer Key',
          ),
          IconButton(
            onPressed: _showInstructions,
            icon: const Icon(Icons.info_outline),
            tooltip: 'Show Instructions',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _controller != null && _controller!.value.isInitialized
                ? Stack(
                    children: [
                      CameraPreview(_controller!),
                      if (_isProcessing)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      if (_sheetRect != null)
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _isSheetDetected ? Colors.green : Colors.red,
                              width: 2.0,
                            ),
                          ),
                          margin: EdgeInsets.fromLTRB(
                            _sheetRect!.left,
                            _sheetRect!.top,
                            _controller!.value.previewSize!.width - _sheetRect!.right,
                            _controller!.value.previewSize!.height - _sheetRect!.bottom,
                          ),
                        ),
                    ],
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedPaperSize,
                  decoration: const InputDecoration(
                    labelText: 'Paper Size',
                    border: OutlineInputBorder(),
                  ),
                  items: ['A4', 'Letter']
                      .map((size) => DropdownMenuItem(
                            value: size,
                            child: Text(size),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPaperSize = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  keyboardType: TextInputType.number,
                  initialValue: _numQuestions.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Number of Questions',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _numQuestions = int.tryParse(value) ?? ImageProcessor.defaultQuestionsPerPage;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  keyboardType: TextInputType.number,
                  initialValue: _numOptions.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Number of Options per Question',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _numOptions = int.tryParse(value) ?? ImageProcessor.defaultOptionsPerQuestion;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saveImage,
                  child: const Text('Save Image'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _allScanResults.isNotEmpty ? _showItemAnalysis : null,
                  child: const Text('Show Item Analysis'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnswerKey {
  final String id;
  final String name;
  final List<String> answers;
  final List<bool> bonusQuestions;

  AnswerKey({required this.id, required this.name, required this.answers, required this.bonusQuestions});

  factory AnswerKey.fromFirestore(DocumentSnapshot doc) {
    return AnswerKey(
      id: doc.id,
      name: doc['name'],
      answers: List<String>.from(doc['answers']),
      bonusQuestions: List<bool>.from(doc['bonusQuestions']),
    );
  }
}

class AnswerKeyManager extends StatefulWidget {
  const AnswerKeyManager({Key? key}) : super(key: key);

  @override
  _AnswerKeyManagerState createState() => _AnswerKeyManagerState();
}

class _AnswerKeyManagerState extends State<AnswerKeyManager> {
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  List<String> _answers = [];
  List<bool> _bonusQuestions = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Answer Key Manager'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
                onSaved: (value) => _name = value!,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    _createAnswerKey();
                  }
                },
                child: const Text('Create Answer Key'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createAnswerKey() async {
    try {
      await _firestore.collection('answer_keys').add({
        'name': _name,
        'answers': _answers,
        'bonusQuestions': _bonusQuestions,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Answer key created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating answer key: $e')),
      );
    }
  }
}
