import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/bubble_sheet_config.dart';

class BubbleSheetGenerator extends StatefulWidget {
  const BubbleSheetGenerator({Key? key}) : super(key: key);

  @override
  _BubbleSheetGeneratorState createState() => _BubbleSheetGeneratorState();
}

class _BubbleSheetGeneratorState extends State<BubbleSheetGenerator> {
  final _formKey = GlobalKey<FormState>();
  late BubbleSheetConfig _config;
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _examCodeController = TextEditingController();
  final TextEditingController _sectionCodeController = TextEditingController();
  final TextEditingController _numberOfQuestionsController = TextEditingController();
  final TextEditingController _optionsController = TextEditingController(text: '6');
  final TextEditingController _questionsPerRowController = TextEditingController(text: '1');
  String _selectedExamSet = 'A';

  @override
  void initState() {
    super.initState();
    _config = BubbleSheetConfig(
      schoolName: '',
      examCode: '',
      examDate: DateTime.now(),
      examSet: 'A',
      numberOfQuestions: 100,
      optionsPerQuestion: 6,
      questionsPerRow: 1,
    );
  }

  // Flutter UI version of bubble row
  Widget buildBubbleRowUI(int questionNumber) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          width: 30,
          child: Text('$questionNumber.', style: TextStyle(fontSize: 10)),
        ),
        Row(
          children: List.generate(
            _config.optionsPerQuestion,
            (j) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + j),
                  style: TextStyle(fontSize: 6),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // PDF version of bubble row
  pw.Widget _buildPDFBubbleRow(pw.Context context, int questionNumber) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 30,
          child: pw.Text('$questionNumber.', style: pw.TextStyle(fontSize: 10)),
        ),
        pw.Row(
          children: List.generate(
            _config.optionsPerQuestion,
            (j) => pw.Container(
              margin: const pw.EdgeInsets.symmetric(horizontal: 3),
              width: 20,
              height: 20,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                border: pw.Border.all(),
              ),
              child: pw.Center(
                child: pw.Text(
                  String.fromCharCode(65 + j),
                  style: pw.TextStyle(fontSize: 6),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();

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
                  _config.schoolName,
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 10),

              // Exam Information
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Exam Code: ${_config.examCode}'),
                      if (_config.sectionCode?.isNotEmpty ?? false)
                        pw.Text('Section: ${_config.sectionCode}'),
                      pw.Text('Date: ${_config.examDate.toString().split(' ')[0]}'),
                    ],
                  ),
                  pw.Text('Set ${_config.examSet}', style: pw.TextStyle(fontSize: 12)),
                ],
              ),
              pw.SizedBox(height: 20),

              // Student Information
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Student Information:'),
                    pw.SizedBox(height: 5),
                    pw.Row(children: [
                      pw.Text('Name: '),
                      pw.Container(
                        width: 200,
                        height: 15,
                        decoration: pw.BoxDecoration(border: pw.Border.all()),
                      ),
                    ]),
                    pw.SizedBox(height: 5),
                    pw.Row(children: [
                      pw.Text('ID: '),
                      pw.Container(
                        width: 100,
                        height: 15,
                        decoration: pw.BoxDecoration(border: pw.Border.all()),
                      ),
                    ]),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Instructions
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Instructions:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('1. Use a #2 pencil only'),
                    pw.Text('2. Fill the bubble completely'),
                    pw.Text('3. Erase completely to change'),
                    pw.Text('4. Make no stray marks'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Answer Bubbles
              pw.Expanded(
                child: pw.Column(
                  children: [
                    for (int i = 0; i < _config.numberOfQuestions; i += _config.questionsPerRow)
                      pw.Container(
                        margin: const pw.EdgeInsets.symmetric(vertical: 2),
                        child: _buildPDFBubbleRow(context, i + 1),
                      ),
                  ],
                ),
              ),
            ],
          );
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
                        if (number == null || number < 1) return 'Invalid number';
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
                        if (value?.isEmpty ?? true) return 'Required';
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
                        if (value?.isEmpty ?? true) return 'Required';
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
                        numberOfQuestions: int.parse(_numberOfQuestionsController.text),
                        optionsPerQuestion: int.parse(_optionsController.text),
                        questionsPerRow: int.parse(_questionsPerRowController.text),
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
