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
      final config = BubbleSheetConfig(
        schoolName: _schoolNameController.text,
        examCode: _examCodeController.text,
        sectionCode: _sectionCodeController.text,
        examDate: DateTime.now(),
        examSet: _selectedExamSet,
        sections: [
          Section(
            id: 'main',
            questions: List.generate(
              int.parse(_numberOfQuestionsController.text),
              (index) => Question(
                id: 'q${index + 1}',
                bubbles: List.generate(
                  int.parse(_optionsController.text),
                  (optionIndex) => BubblePosition(
                    x: 30 + (optionIndex * 22),
                    y: 40 + (index * 22),
                    value: String.fromCharCode('A'.codeUnitAt(0) + optionIndex),
                  ),
                ),
              ),
            ),
          ),
        ],
        questionsPerRow: int.parse(_questionsPerRowController.text),
        bubbleSize: 16.0, // Reduced size for better performance
        bubbleSpacing: 6.0,
        topMargin: 40.0,
        leftMargin: 30.0,
        fontSize: 10.0,
        bubbleRadius: 8.0,
        includeStudentInfo: true,
        includeBarcode: false,
        gridSquareConfig: const GridSquareConfig(
          size: 16.0,
          spacing: 4.0,
          numSquares: 4,
          cornerRadius: 2.0,
          strokeWidth: 0.5,
        ),
      );

      // Generate PDF in chunks
      for (var i = 0; i < config.sections[0].questions.length; i += 25) {
        final endIndex = (i + 25 < config.sections[0].questions.length) ? i + 25 : config.sections[0].questions.length;
        await _addQuestionsToPage(pdf, config, i, endIndex);
      }

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

  Future<void> _addQuestionsToPage(pw.Document pdf, BubbleSheetConfig config, int startQuestion, int endQuestion) async {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(config),
              pw.SizedBox(height: 10),

              // Student Information
              if (config.includeStudentInfo) ...[
                _buildStudentInfo(),
                pw.SizedBox(height: 15),
              ],

              // Instructions
              _buildInstructions(config),
              pw.SizedBox(height: 15),

              // Answer Sheet with optimized rendering
              pw.Expanded(
                child: _buildAnswerSheet(config, startQuestion, endQuestion),
              ),
            ],
          );
        },
      ),
    );
  }

  pw.Widget _buildHeader(BubbleSheetConfig config) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(config.schoolName,
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Text('Set ${config.examSet}',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Row(
          children: [
            pw.Text('Exam: ${config.examCode}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(width: 15),
            if (config.sectionCode?.isNotEmpty ?? false)
              pw.Text('Section: ${config.sectionCode}', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildStudentInfo() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Name: _________________________________', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 8),
          pw.Text('ID: ___________________________________', style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  pw.Widget _buildInstructions(BubbleSheetConfig config) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Instructions:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('• Use No. 2 pencil only', style: const pw.TextStyle(fontSize: 9)),
          pw.Text('• Fill bubbles completely', style: const pw.TextStyle(fontSize: 9)),
          pw.Text('• Erase completely to change', style: const pw.TextStyle(fontSize: 9)),
          pw.Text('• No stray marks', style: const pw.TextStyle(fontSize: 9)),
          if (config.customInstructions != null)
            pw.Text(config.customInstructions!, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  pw.Widget _buildAnswerSheet(BubbleSheetConfig config, int startQuestion, int endQuestion) {
    return pw.Column(
      children: List.generate(
        endQuestion - startQuestion,
        (index) => _buildQuestionRow(startQuestion + index, config),
      ),
    );
  }

  pw.Widget _buildQuestionRow(int questionIndex, BubbleSheetConfig config) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Container(
            width: 25,
            alignment: pw.Alignment.centerRight,
            child: pw.Text('${questionIndex + 1}.', style: const pw.TextStyle(fontSize: 9)),
          ),
          pw.SizedBox(width: 5),
          ...List.generate(
            config.sections[0].questions[questionIndex].bubbles.length,
            (optionIndex) => pw.Padding(
              padding: pw.EdgeInsets.only(right: config.bubbleSpacing),
              child: pw.Container(
                width: config.bubbleRadius * 2,
                height: config.bubbleRadius * 2,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  border: pw.Border.all(width: 0.5),
                ),
                child: pw.Center(
                  child: pw.Text(
                    config.sections[0].questions[questionIndex].bubbles[optionIndex].value,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
