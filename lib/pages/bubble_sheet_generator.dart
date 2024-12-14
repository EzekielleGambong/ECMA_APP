import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:ui';
import 'package:printing/printing.dart';
import '../models/bubble_sheet_config.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/offline_storage_service.dart';
import '../services/bubble_sheet_scanner.dart';

class BubbleSheetGenerator extends StatefulWidget {
  const BubbleSheetGenerator({super.key});

  @override
  State<BubbleSheetGenerator> createState() => _BubbleSheetGeneratorState();
}

class _BubbleSheetGeneratorState extends State<BubbleSheetGenerator> {
  final _formKey = GlobalKey<FormState>();
  final _schoolNameController = TextEditingController();
  final _examCodeController = TextEditingController();
  final _sectionCodeController = TextEditingController();
  final _numberOfQuestionsController = TextEditingController();
  final _optionsController = TextEditingController(text: '4');
  final _questionsPerRowController = TextEditingController(text: '1');
  String _selectedExamSet = 'A';
  bool _isLoading = false;
  bool _isGeneratingPDF = false;
  final _offlineStorage = OfflineStorageService();
  final _scanner = BubbleSheetScanner();
  bool _isGenerating = false;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _initializeOfflineStorage();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = connectivityResult == ConnectivityResult.none;
    });
  }

  Future<void> _initializeOfflineStorage() async {
    await _offlineStorage.initialize();
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    _examCodeController.dispose();
    _sectionCodeController.dispose();
    _numberOfQuestionsController.dispose();
    _optionsController.dispose();
    _questionsPerRowController.dispose();
    super.dispose();
  }

  Future<void> _generatePDF() async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final pdf = pw.Document();
      final totalQuestions = int.parse(_numberOfQuestionsController.text);
      final numColumns = BubbleSheetConfig.calculateColumns(totalQuestions);
      final questionsPerColumn = (totalQuestions / numColumns).ceil();
      
      final config = BubbleSheetConfig(
        schoolName: _schoolNameController.text,
        examCode: _examCodeController.text,
        sectionCode: _sectionCodeController.text,
        examDate: DateTime.now(),
        examSet: _selectedExamSet,
        totalQuestions: totalQuestions,
        numColumns: numColumns,
        questionsPerRow: 1,
        sections: [
          Section(
            id: 'main',
            questions: List.generate(
              totalQuestions,
              (index) => Question(
                id: 'q${index + 1}',
                bubbles: List.generate(
                  int.parse(_optionsController.text),
                  (optionIndex) {
                    final column = index ~/ questionsPerColumn;
                    final row = index % questionsPerColumn;
                    return BubblePosition(
                      x: (50 + (column * 120) + (optionIndex * 20)) / 500,
                      y: (150 + (row * 20)) / 700,
                      value: String.fromCharCode('A'.codeUnitAt(0) + optionIndex),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
        cornerSquares: [
          CornerSquare(x: 0.05, y: 0.05, size: 10),
          CornerSquare(x: 0.95, y: 0.05, size: 10),
          CornerSquare(x: 0.05, y: 0.95, size: 10),
          CornerSquare(x: 0.95, y: 0.95, size: 10),
        ],
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    config.schoolName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                
                // Student Information Section
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Name: _______________________'),
                            pw.SizedBox(height: 5),
                            pw.Text('Student Number: _____________'),
                          ],
                        ),
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Section Code: ${config.sectionCode}'),
                          pw.Text('Exam Code: ${config.examCode}'),
                          pw.Text('Date: ${config.examDate.toString().split(' ')[0]}'),
                          pw.Text('Exam Set: ${config.examSet}'),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Instructions
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 10),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Use a number 2 pencil only'),
                      pw.Text('Darken completely the circle'),
                      pw.Text('STRICTLY NO ERASURES'),
                    ],
                  ),
                ),
                
                // Answer Grid
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Stack(
                    children: [
                      // Corner squares for scanning
                      ...config.cornerSquares.map((corner) => pw.Positioned(
                        left: corner.x * 500, // Adjust based on your page size
                        top: corner.y * 700,  // Adjust based on your page size
                        child: pw.Container(
                          width: corner.size,
                          height: corner.size,
                          color: PdfColors.black,
                        ),
                      )),
                      
                      // Answer grid
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: List.generate(
                          config.numColumns,
                          (columnIndex) {
                            final startQuestion = columnIndex * questionsPerColumn;
                            final endQuestion = (columnIndex + 1) * questionsPerColumn;
                            return pw.Expanded(
                              child: pw.Column(
                                children: List.generate(
                                  questionsPerColumn,
                                  (rowIndex) {
                                    final questionNumber = startQuestion + rowIndex + 1;
                                    if (questionNumber > totalQuestions) return pw.Container();
                                    return pw.Container(
                                      height: 20,
                                      child: pw.Row(
                                        children: [
                                          pw.Container(
                                            width: 30,
                                            alignment: pw.Alignment.centerRight,
                                            child: pw.Text('$questionNumber.'),
                                          ),
                                          pw.Row(
                                            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                                            children: List.generate(
                                              int.parse(_optionsController.text),
                                              (optionIndex) => pw.Container(
                                                width: 15,
                                                height: 15,
                                                decoration: pw.BoxDecoration(
                                                  shape: pw.BoxShape.circle,
                                                  border: pw.Border.all(),
                                                ),
                                                margin: const pw.EdgeInsets.symmetric(horizontal: 2),
                                                child: pw.Center(
                                                  child: pw.Text(
                                                    String.fromCharCode('A'.codeUnitAt(0) + optionIndex),
                                                    style: pw.TextStyle(fontSize: 8),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Footer
                pw.Positioned(
                  bottom: 10,
                  child: pw.Center(
                    child: pw.Text(
                      'This is a computer generated form. Photocopying will make this form INVALID.',
                      style: pw.TextStyle(fontSize: 8),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();

      // Save locally for offline access
      final examId = DateTime.now().millisecondsSinceEpoch.toString();
      await _offlineStorage.saveBubbleSheet(examId, config);
      await _offlineStorage.savePDFLocally(examId, pdfBytes);

      // Print or preview
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        format: PdfPageFormat.a4,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _scanBubbleSheet(File imageFile) async {
    try {
      final sheets = await _offlineStorage.getBubbleSheets();
      if (sheets.isEmpty) {
        throw Exception('No bubble sheet configurations found');
      }

      // Use the most recent configuration
      final latestConfig = BubbleSheetConfig.fromJson(
        sheets.entries.last.value as Map<String, dynamic>
      );

      final results = await _scanner.scanBubbleSheet(imageFile, latestConfig);
      
      if (results['processed'] == true) {
        await _offlineStorage.saveScannedResult(
          latestConfig.examCode,
          results,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan completed successfully')),
        );
      } else {
        throw Exception(results['error'] ?? 'Unknown scanning error');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bubble Sheet Generator'),
        actions: [
          IconButton(
            icon: Icon(_isOffline ? Icons.cloud_off : Icons.cloud_done),
            onPressed: () => _checkConnectivity(),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _schoolNameController,
                decoration: const InputDecoration(
                  labelText: 'School Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _examCodeController,
                decoration: const InputDecoration(
                  labelText: 'Exam Code',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sectionCodeController,
                decoration: const InputDecoration(
                  labelText: 'Section Code (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _numberOfQuestionsController,
                      decoration: const InputDecoration(
                        labelText: 'Number of Questions',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        final number = int.tryParse(value!);
                        if (number == null || number < 1 || number > 100) {
                          return 'Must be 1-100';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedExamSet,
                      decoration: const InputDecoration(
                        labelText: 'Exam Set',
                        border: OutlineInputBorder(),
                      ),
                      items: ['A', 'B', 'C', 'D'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text('Set $value'),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() => _selectedExamSet = newValue);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: (_isLoading || _isGeneratingPDF)
                      ? null
                      : () {
                          if (_formKey.currentState?.validate() ?? false) {
                            _generatePDF();
                          }
                        },
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Generate Bubble Sheet'),
                ),
              ),
              if (_isOffline)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  color: Colors.orange.shade100,
                  child: const Text(
                    'Working in offline mode. Changes will be synced when online.',
                    style: TextStyle(color: Colors.deepOrange),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
