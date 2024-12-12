import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';

class AnswerKey {
  final String id;
  final String name;
  final List<String> answers;
  final List<bool> bonusQuestions;
  final DateTime createdAt;
  final String subjectId;

  AnswerKey({
    required this.id,
    required this.name,
    required this.answers,
    required this.bonusQuestions,
    required this.createdAt,
    required this.subjectId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'answers': answers,
      'bonusQuestions': bonusQuestions,
      'createdAt': createdAt.toIso8601String(),
      'subjectId': subjectId,
    };
  }

  factory AnswerKey.fromJson(Map<String, dynamic> json) {
    return AnswerKey(
      id: json['id'],
      name: json['name'],
      answers: List<String>.from(json['answers']),
      bonusQuestions: List<bool>.from(json['bonusQuestions']),
      createdAt: DateTime.parse(json['createdAt']),
      subjectId: json['subjectId'],
    );
  }

  factory AnswerKey.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AnswerKey(
      id: doc.id,
      name: data['name'] ?? '',
      answers: List<String>.from(data['answers'] ?? []),
      bonusQuestions: List<bool>.from(data['bonusQuestions'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      subjectId: data['subjectId'] ?? '',
    );
  }
}

class AnswerKeyManager extends StatefulWidget {
  final String? initialSubjectId;
  
  const AnswerKeyManager({Key? key, this.initialSubjectId}) : super(key: key);

  @override
  _AnswerKeyManagerState createState() => _AnswerKeyManagerState();
}

class _AnswerKeyManagerState extends State<AnswerKeyManager> {
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  List<String> _answers = [];
  List<bool> _bonusQuestions = [];
  String? _selectedSubjectId;
  int _numberOfQuestions = 20; // Default number of questions

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = widget.initialSubjectId;
    _initializeAnswers();
  }

  void _initializeAnswers() {
    _answers = List.filled(_numberOfQuestions, 'A');
    _bonusQuestions = List.filled(_numberOfQuestions, false);
  }

  Future<void> _importFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'csv'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String contents = await file.readAsString();
        List<String> lines = contents.trim().split('\n');
        
        if (lines.isNotEmpty) {
          setState(() {
            _numberOfQuestions = lines.length;
            _answers = lines.map((line) => line.trim().toUpperCase()).toList();
            _bonusQuestions = List.filled(_numberOfQuestions, false);
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing file: $e')),
      );
    }
  }

  Future<void> _saveAnswerKey() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      DocumentReference docRef = await _firestore.collection('answer_keys').add({
        'name': _nameController.text,
        'answers': _answers,
        'bonusQuestions': _bonusQuestions,
        'createdAt': FieldValue.serverTimestamp(),
        'subjectId': _selectedSubjectId,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Answer key saved successfully')),
      );

      // Export to local storage as backup
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/answer_key_${docRef.id}.json');
      final answerKey = AnswerKey(
        id: docRef.id,
        name: _nameController.text,
        answers: _answers,
        bonusQuestions: _bonusQuestions,
        createdAt: DateTime.now(),
        subjectId: _selectedSubjectId ?? '',
      );
      await file.writeAsString(jsonEncode(answerKey.toJson()));

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving answer key: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Answer Key Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: _importFromFile,
            tooltip: 'Import from file',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAnswerKey,
            tooltip: 'Save answer key',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Answer Key Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name for the answer key';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('subjects').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                List<DropdownMenuItem<String>> subjectItems = snapshot.data!.docs
                    .map((doc) => DropdownMenuItem(
                          value: doc.id,
                          child: Text(doc['name'] as String),
                        ))
                    .toList();

                return DropdownButtonFormField<String>(
                  value: _selectedSubjectId,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                  items: subjectItems,
                  onChanged: (value) {
                    setState(() {
                      _selectedSubjectId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a subject';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _numberOfQuestions.toString(),
              decoration: const InputDecoration(
                labelText: 'Number of Questions',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                int? newNumber = int.tryParse(value);
                if (newNumber != null && newNumber > 0) {
                  setState(() {
                    _numberOfQuestions = newNumber;
                    _initializeAnswers();
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Answers and Bonus Questions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _numberOfQuestions,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: Text('Q${index + 1}'),
                    title: DropdownButton<String>(
                      value: _answers[index],
                      items: ['A', 'B', 'C', 'D'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _answers[index] = newValue;
                          });
                        }
                      },
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Bonus'),
                        Checkbox(
                          value: _bonusQuestions[index],
                          onChanged: (bool? value) {
                            if (value != null) {
                              setState(() {
                                _bonusQuestions[index] = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
