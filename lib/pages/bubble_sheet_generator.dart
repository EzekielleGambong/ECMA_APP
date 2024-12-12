import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/bubble_sheet_config.dart';
import '../services/analytics_service.dart';
import '../utils/app_metrics.dart';

class BubbleSheetGenerator extends StatefulWidget {
  const BubbleSheetGenerator({Key? key}) : super(key: key);

  @override
  State<BubbleSheetGenerator> createState() => _BubbleSheetGeneratorState();
}

class _BubbleSheetGeneratorState extends State<BubbleSheetGenerator> {
  final _formKey = GlobalKey<FormState>();
  final _schoolNameController = TextEditingController();
  final _examCodeController = TextEditingController();
  final _sectionCodeController = TextEditingController();
  final _numberOfQuestionsController = TextEditingController();
  final _optionsController = TextEditingController(text: '6');
  final _questionsPerRowController = TextEditingController(text: '2');
  String _selectedExamSet = 'A';
  BubbleSheetConfig? _config;

  late pw.MemoryImage pencilIcon;
  late pw.MemoryImage noErasuresIcon;

  final _metrics = AppMetrics();

  @override
  void initState() {
    super.initState();
    _loadAssets();
    AnalyticsService().initializeAnalytics();
  }

  Future<void> _loadAssets() async {
    final pencilData = await rootBundle.load('assets/icons/pencil.svg');
    final noErasuresData = await rootBundle.load('assets/icons/no_erasures.svg');
    setState(() {
      pencilIcon = pw.MemoryImage(
        pencilData.buffer.asUint8List(),
      );
      noErasuresIcon = pw.MemoryImage(
        noErasuresData.buffer.asUint8List(),
      );
    });
  }

  @override
  void dispose() {
    AnalyticsService().dispose();
    super.dispose();
  }

  // PDF version of bubble row
  pw.Widget _buildPDFBubbleRow(pw.Context context, int questionNumber) {
    if (questionNumber > _config!.numberOfQuestions) return pw.Container();

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Container(
            width: 30,
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(right: 8),
            child: pw.Text(
              questionNumber.toString().padLeft(3, '0'),
              style: pw.TextStyle(fontSize: 10),
            ),
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children: List.generate(
              _config!.optionsPerQuestion,
              (j) => pw.Container(
                margin: const pw.EdgeInsets.symmetric(horizontal: 3),
                width: 16,
                height: 16,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  border: pw.Border.all(
                    color: PdfColor.fromHex('#000000'),
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildAnswerGrid(pw.Context context) {
    final questionsPerColumn = (_config!.numberOfQuestions / 4).ceil();
    final columns = List.generate(4, (columnIndex) {
      final startNumber = columnIndex * questionsPerColumn + 1;
      return pw.Expanded(
        child: pw.Column(
          children: List.generate(
            questionsPerColumn,
            (index) {
              final questionNumber = startNumber + index;
              if (questionNumber > _config!.numberOfQuestions) {
                return pw.Container(); // Empty container for overflow
              }
              return _buildPDFBubbleRow(context, questionNumber);
            },
          ),
        ),
      );
    });

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: columns,
    );
  }

  pw.Widget _buildStudentIdBubbles(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Student ID Number:',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children: [
              for (int digit = 0; digit < 11; digit++)
                pw.Container(
                  margin: const pw.EdgeInsets.only(right: 4),
                  child: pw.Column(
                    children: [
                      pw.Container(
                        width: 20,
                        height: 20,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(width: 0.5),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      for (int num = 0; num < 10; num++)
                        pw.Container(
                          margin: const pw.EdgeInsets.symmetric(vertical: 1),
                          width: 14,
                          height: 14,
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            border: pw.Border.all(width: 0.5),
                          ),
                          child: pw.Center(
                            child: pw.Text(
                              '$num',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInstructions(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 0.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          pw.Column(
            children: [
              pw.Text('Use a number 2 pencil only',
                  style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 4),
              pw.Container(
                width: 20,
                height: 20,
                child: pw.Image(pencilIcon),
              ),
            ],
          ),
          pw.Column(
            children: [
              pw.Text('Darken completely the\ncircle corresponding to\nyour answer',
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 4),
              pw.Row(
                children: [
                  pw.Container(
                    width: 12,
                    height: 12,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: PdfColor.fromHex('#000000'),
                    ),
                  ),
                  pw.SizedBox(width: 4),
                  pw.Container(
                    width: 12,
                    height: 12,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(width: 0.5),
                    ),
                  ),
                  pw.SizedBox(width: 4),
                  pw.Container(
                    width: 12,
                    height: 12,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(width: 0.5),
                    ),
                    child: pw.Center(
                      child: pw.Container(
                        width: 6,
                        height: 6,
                        decoration: const pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          color: PdfColor.fromHex('#000000'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.Column(
            children: [
              pw.Text('STRICTLY NO\nERASURES',
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 4),
              pw.Container(
                width: 20,
                height: 20,
                child: pw.Image(noErasuresIcon),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _generatePDF() async {
    if (!_metrics.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network connection required: Please Contact your administrator.')),
      );
      return;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          List<pw.Widget> widgets = [];

          // Header
          widgets.add(
            pw.Center(
              child: pw.Text(
                _config!.schoolName.toUpperCase(),
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 10));

          // Student Information and Exam Info in a Row
          widgets.add(
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left side - Student Info
                pw.Expanded(
                  flex: 3,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 0.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Step 1. Student Information',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 8),
                        _buildStudentIdBubbles(context),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                // Right side - Exam Info
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 0.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Step 2. Exam Information',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 8),
                        pw.Text('Section Code: ${_config!.sectionCode}'),
                        pw.Text('Exam Code: ${_config!.examCode}'),
                        pw.Text('Date: ${_config!.examDate.toString().split(' ')[0]}'),
                        pw.Row(
                          children: [
                            pw.Text('Exam Set: '),
                            pw.Container(
                              width: 16,
                              height: 16,
                              decoration: pw.BoxDecoration(
                                shape: pw.BoxShape.circle,
                                border: pw.Border.all(width: 0.5),
                              ),
                              child: pw.Center(
                                child: pw.Text(_config!.examSet),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
          widgets.add(pw.SizedBox(height: 10));

          // Instructions
          widgets.add(
            pw.Container(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Step 3. Marking Instructions',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  _buildInstructions(context),
                ],
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 20));

          // Answer Grid
          widgets.add(_buildAnswerGrid(context));

          // Footer
          widgets.add(
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 10),
              child: pw.Text(
                'This is a computer generated form. Photocopying will make this form INVALID.',
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
            ),
          );

          return widgets;
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bubble Sheet Generator'),
      ),
      body: !_metrics.isValid
          ? const Center(child: Text('Please Contact Developer'))
          : Form(
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
                              if (value?.isEmpty ?? true) {
                                return 'Required';
                              }
                              final number = int.tryParse(value!);
                              if (number == null || number < 1) {
                                return 'Invalid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _optionsController,
                            decoration: const InputDecoration(
                              labelText: 'Options per Question',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Required';
                              }
                              final number = int.tryParse(value!);
                              if (number == null || number < 2 || number > 6) {
                                return 'Must be 2-6';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _questionsPerRowController,
                            decoration: const InputDecoration(
                              labelText: 'Questions per Row',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Required';
                              }
                              final number = int.tryParse(value!);
                              if (number == null || number < 1 || number > 2) {
                                return 'Must be 1-2';
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
                              setState(() {
                                _selectedExamSet = newValue!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            _config = BubbleSheetConfig(
                              schoolName: _schoolNameController.text,
                              examCode: _examCodeController.text,
                              sectionCode: _sectionCodeController.text,
                              examDate: DateTime.now(),
                              examSet: _selectedExamSet,
                              numberOfQuestions:
                                  int.parse(_numberOfQuestionsController.text),
                              optionsPerQuestion: int.parse(_optionsController.text),
                              questionsPerRow:
                                  int.parse(_questionsPerRowController.text),
                            );
                            _generatePDF();
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Generate Bubble Sheet'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
