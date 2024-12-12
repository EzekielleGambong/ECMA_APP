import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'subject_list.dart';

class EditSubj extends StatelessWidget {
  final String subjectKey;
  const EditSubj({Key? key, required this.subjectKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Examination Form',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: ExaminationScreen(
        subjectKey: subjectKey,
      ),
    );
  }
}

class ExaminationScreen extends StatelessWidget {
  final String subjectKey;
  const ExaminationScreen({Key? key, required this.subjectKey})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SubjectList(),
              ),
            );
          },
        ),
        title: const Text(
          'Edit Subject',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ExaminationBody(
        subjectKey: subjectKey,
      ),
    );
  }
}

class ExaminationBody extends StatefulWidget {
  final String subjectKey;
  const ExaminationBody({Key? key, required this.subjectKey}) : super(key: key);

  @override
  _ExaminationBodyState createState() => _ExaminationBodyState();
}

class _ExaminationBodyState extends State<ExaminationBody> {
  String? selectedExamType;
  final _firestore = FirebaseFirestore.instance;
  final TextEditingController _subjectController = TextEditingController();
  List<TextEditingController> controllers = [];
  int numberFields = 0;
  bool isLoading = true; // Loader state

  @override
  void initState() {
    super.initState();
    _loadData(); // Load data when the widget is created
  }

  Future<void> _loadData() async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('subjects').doc(widget.subjectKey).get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          _subjectController.text = data['subject'];
          selectedExamType = data['examType'];
          List<dynamic> answers = data['answers'] ?? [];
          numberFields = answers.length;
          controllers = List.generate(numberFields, (index) {
            TextEditingController controller = TextEditingController();
            controller.text = answers[index];
            return controller;
          });
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
    }
  }

  Future<void> _updateSubject() async {
    String subject = _subjectController.text;
    String? examType = selectedExamType;

    List<String> answers = [];
    for (int i = 0; i < numberFields; i++) {
      answers.add(controllers[i].text);
    }

    if (subject.isEmpty || examType == null || answers.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill out all fields')));
      return;
    }

    try {
      await _firestore.collection('subjects').doc(widget.subjectKey).update({
        'subject': subject,
        'examType': examType,
        'answers': answers,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Successfully Updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(
            child:
                CircularProgressIndicator()) // Show loader while fetching data
        : GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Subject',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _subjectController,
                          decoration: InputDecoration(
                            hintText: 'Enter Subject',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Exam Type',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedExamType,
                          items: [
                            'Quiz 1',
                            'Quiz 2',
                            'Quiz 3',
                            'Quiz 4',
                            'Exam'
                          ].map((examType) {
                            return DropdownMenuItem(
                              value: examType,
                              child: Text(examType),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedExamType = value;
                            });
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          hint: const Text('Select Exam Type'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Answer Keys',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 300,
                          child: SingleChildScrollView(
                            child: Column(
                              children: List.generate(numberFields, (index) {
                                return TextField(
                                  controller: controllers[index],
                                  decoration: InputDecoration(
                                      hintText: 'Answer ${index + 1}'),
                                );
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Total Number: ${numberFields.toString()}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: ElevatedButton(
                        onPressed: _updateSubject,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFF00BF6D),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(200, 48),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text("UPDATE"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}
