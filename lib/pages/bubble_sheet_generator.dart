import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:ui';
import 'package:printing/printing.dart';
import '../models/bubble_sheet_config.dart';
import '../services/analytics_service.dart';
import '../utils/app_metrics.dart';

class BubbleSheetGenerator extends StatefulWidget {
  final Key? key;

  const BubbleSheetGenerator({this.key}) : super(key: key);

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
                      color: PdfColors.black,
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
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          color: PdfColors.black,
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

  Future<Uint8List> generateBubbleSheet() async {
    final pdf = pw.Document();
    final config = BubbleSheetConfig(
      schoolName: _schoolNameController.text,
      examCode: _examCodeController.text,
      sectionCode: _sectionCodeController.text,
      examDate: DateTime.now(),
      examSet: _selectedExamSet,
      numberOfQuestions: int.parse(_numberOfQuestionsController.text),
      optionsPerQuestion: int.parse(_optionsController.text),
      questionsPerRow: int.parse(_questionsPerRowController.text),
    );

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Stack(
            children: [
              pw.Positioned(
                child: pw.Container(
                  child: pw.CustomPaint(
                    painter: (context, size) {
                      final squares = config.getGridSquares();
                      for (final square in squares) {
                        context.setStrokeColor(PdfColors.black);
                        context.setLineWidth(config.gridSquareConfig.strokeWidth);
                        context.moveTo(square.left, square.top);
                        context.lineTo(square.left + square.width, square.top);
                        context.lineTo(square.left + square.width, square.top + square.height);
                        context.lineTo(square.left, square.top + square.height);
                        context.lineTo(square.left, square.top);
                        context.strokePath();
                      }
                    },
                  ),
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(height: config.topMargin),
                  ...List.generate(
                    config.questionsPerColumn,
                    (questionIndex) => pw.Row(
                      children: [
                        pw.SizedBox(width: config.leftMargin),
                        pw.Text('${questionIndex + 1}.'),
                        pw.SizedBox(width: 10),
                        ...List.generate(
                          config.optionsPerQuestion,
                          (optionIndex) => pw.Padding(
                            padding: pw.EdgeInsets.only(right: config.bubbleSpacing),
                            child: pw.Container(
                              width: config.bubbleRadius * 2,
                              height: config.bubbleRadius * 2,
                              decoration: pw.BoxDecoration(
                                shape: pw.BoxShape.circle,
                                border: pw.Border.all(width: 1),
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  String.fromCharCode('A'.codeUnitAt(0) + optionIndex),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Positioned(
                bottom: 50,
                left: config.leftMargin,
                child: pw.Row(
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Name:'),
                        pw.Container(
                          width: 200,
                          decoration: pw.BoxDecoration(
                            border: pw.Border(bottom: pw.BorderSide()),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(width: 50),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Signature:'),
                        pw.Container(
                          width: 200,
                          decoration: pw.BoxDecoration(
                            border: pw.Border(bottom: pw.BorderSide()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _generatePDF() async {
    if (!_metrics.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network connection required: Please Contact your administrator.')),
      );
      return;
    }

    final pdfBytes = await generateBubbleSheet();

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
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
