import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecma/pages/customCam.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';
import 'student_list.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(const AddStudent());
}

class AddStudent extends StatelessWidget {
  const AddStudent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Examination Form',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const ExaminationScreen(),
    );
  }
}

class ExaminationScreen extends StatefulWidget {
  const ExaminationScreen({Key? key}) : super(key: key);

  @override
  _ExaminationScreenState createState() => _ExaminationScreenState();
}

class _ExaminationScreenState extends State<ExaminationScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? selectedSubjectCode;
  String? selectedExamType;
  String? results;
  bool isLoading = false;


  List<String> answerSheets = [];


  List<String> subjectCodes = [];

  List<String> answerKey = [];

  Future<void> fetchAnswerKey() async {
    try {
      if (selectedSubjectCode != null || selectedExamType != null) {
        final QuerySnapshot querySnapshot = await _firestore
            .collection('subjects')
            .where('examType', isEqualTo: selectedExamType)
            .where('subject', isEqualTo: selectedSubjectCode)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          Map<String, dynamic> data =
              querySnapshot.docs.first.data() as Map<String, dynamic>;

          final answers = data['answers'];
          setState(() {
            for (final answer in answers) {
              answerKey.add(answer);
            }

            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(answerKey.join(","))));
          });
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('No document Found')));
        }
      } else {
        print('Please select subject code and exam type');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> fetchSubjects() async {
    try {
      final snapshot = await _firestore.collection('subjects').get();
      setState(() {
        subjectCodes =
            snapshot.docs.map((doc) => doc['subject'].toString()).toList();
      });
    } catch (e) {
      print('Error fetching subjects: $e');
    }
  }

  final List<String> examTypes = [
    'Quiz 1',
    'Quiz 2',
    'Quiz 3',
    'Quiz 4',
    'Exam',
  ];

  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  File? image1;

  Future<void> _openCamera() async {
    final File? capturedImage = await Navigator.push(
        context, MaterialPageRoute(builder: (context) => const CustomCam()));

    if (capturedImage != null) {
      setState(() {
        image1 = capturedImage;
      });
    }
  }

  Future<void> _uploadFile() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        image1 = File(image.path);
      });
    }
  }

  Future<void> _addStudent() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Filled the Subjects')));
    }

    if(results!.isEmpty){
         ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Scan it first before you add the student')));
    }
    try {
      if (image1 != null) {
        String filename = DateTime.now().millisecond.toString();

        String? downloadUrl;

        if (image1 != null) {
          Reference ref = _storage.ref().child('subjectImages/${filename}');
          UploadTask uploadTask = ref.putFile(image1!);
          TaskSnapshot snapshot = await uploadTask;
          downloadUrl = await snapshot.ref.getDownloadURL();
        }

        await _firestore.collection('students').add({
          'name': _nameController.text,
          'subjectCode': selectedSubjectCode,
          'examType': selectedExamType,
          'upload_image': downloadUrl,
          'examResults': results
        });

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added Students successfully')));
        _nameController.clear;
        setState(() {
          image1 = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  int score = 0;
  String percentage = "0.0";
  List<Map<String, dynamic>> detailedResults = [];

Future<void> checkAnswers() async {
  if (answerKey.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please load answer key first')));
    return;
  }

  setState(() {
    isLoading = true;
    detailedResults = [];
    answerSheets.clear();
    score = 0;
    percentage = "0.0";
  });

  try {
    final fileUri = Uri.file(image1!.path);
    final fileBytes = await image1!.readAsBytes();
 
    final model = GenerativeModel(
      model: 'gemini-1.5-pro-002',
      apiKey: 'AIzaSyBwQOMb7dwidhYKCitrxFgqKmmA0pmJfG8',
    );

    final content = [
      Content.multi([
        DataPart('image/jpeg', fileBytes),
        TextPart('''
        You are Expert in OMR Scanning.
        Analyze this OMR sheet image. 
        Path: ${fileUri.path}
        Identify the answers marked by students where each question has four choices (A, B, C, D).
        Dont count the unshaded.
        Base the lenght of the answers on ${answerKey.length}
        Add in your vision a threshold .50
        Return the results in a clear JSON format with question numbers and selected answers.
        Capitalized the Scanned letter
        Example output:
        {
          "1": "A",
          "2": "B",
          "3": "C"
        }
        ''')
      ])
    ];

    final response = await model.generateContent(content);

    setState(() {
      results = response.text!.replaceAll('```json','').replaceAll('```','');
      isLoading = false;

      Map<String,dynamic> jsonData = jsonDecode("[" + results! + "]")[0];

      answerSheets.clear();
      detailedResults.clear();

      for(int i = 0; i < answerKey.length; i++){
   
        String questionKey = (i + 1).toString();
        String studentAnswer = jsonData[questionKey] ?? '';
        answerSheets.add(studentAnswer);

        bool isCorrect = answerKey[i].contains(studentAnswer);
        if (isCorrect) score++;

        detailedResults.add({
          'questionNumber': i + 1,
          'studentAnswer': studentAnswer,
          'correctAnswer': answerKey[i],
          'isCorrect': isCorrect
        });
      }

      // Calculate percentage
      percentage = ((score / answerKey.length) * 100).toStringAsFixed(2);
    });
       
  } catch (e) {
    setState(() {
      results = 'Error processing image: $e';
      isLoading = false;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Processing error: $e')));
  }
}

  Future<void> onScanPressed() async {
    await checkAnswers();
  }

  void onSelectionChanged() {
    if (selectedExamType != null && selectedSubjectCode != null) {
      fetchAnswerKey();
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSubjects();
  }


  void _editAnswer(int index) {
  final List<String> possibleAnswers = ['A', 'B', 'C', 'D'];
  
  showDialog(
    context: context,
    builder: (BuildContext context) {
      String? selectedAnswer = answerSheets[index];
      return AlertDialog(
        title: Text('Edit Answer for Question ${index + 1}'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: possibleAnswers.map((answer) {
                return RadioListTile<String>(
                  title: Text(answer),
                  value: answer,
                  groupValue: selectedAnswer,
                  onChanged: (String? value) {
                    setState(() {
                      selectedAnswer = value;
                    });
                  },
                );
              }).toList(),
            );
          },
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: const Text('Save'),
            onPressed: () {
              // Update the answer in both answerSheets and detailedResults
              this.setState(() {
                answerSheets[index] = selectedAnswer!;
                
                // Recalculate score and detailed results
                score = 0;
                for (int i = 0; i < answerKey.length; i++) {
                  bool isCorrect = answerSheets[i] == answerKey[i];
                  if (isCorrect) score++;

                  detailedResults[i] = {
                    'questionNumber': i + 1,
                    'studentAnswer': answerSheets[i],
                    'correctAnswer': answerKey[i],
                    'isCorrect': isCorrect
                  };
                }

                // Recalculate percentage
                percentage = ((score / answerKey.length) * 100).toStringAsFixed(2);
              });
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}


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
              MaterialPageRoute(builder: (context) => StudentList()),
            );
          },
        ),
        title: const Text(
          'Add Student',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            
            _buildSectionTitle('Student Name'),
            const SizedBox(height: 8),
            _buildTextField('Enter Name', _nameController),
            const SizedBox(height: 16),
            _buildSectionTitle('Subject Code'),
            const SizedBox(height: 8),
            _buildDropdown(
              hint: 'Select Subject Code',
              items: subjectCodes,
              value: selectedSubjectCode,
              onChanged: (value) => setState(() => selectedSubjectCode = value),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Exam Type'),
            const SizedBox(height: 8),
            _buildDropdown(
                hint: 'Select Exam Type',
                items: examTypes,
                value: selectedExamType,
                onChanged: (value) {
                  setState(() => selectedExamType = value);
                  onSelectionChanged();
                }),
            const SizedBox(height: 32),
            image1 == null
                ? Text('No photos uploaded')
                : Image.file(
                    image1!,
                    height: 300,
                    width: 300,
                  ),
            const SizedBox(height: 32),
            _buildSectionTitle('Exam Detection'),
            const SizedBox(height: 8),
            _buildActionButton(
              icon: Icons.upload_file,
              label: 'File Upload',
              onPressed: _uploadFile,
              color: Colors.black,
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              icon: Icons.camera_alt,
              label: 'Open Camera',
              onPressed: _openCamera,
              color: Colors.black,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onScanPressed,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF00BF6D),
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 48),
                shape: const StadiumBorder(),
              ),
              child: const Text("Scan"),
            ),

            const SizedBox(height: 20,),
            if(isLoading)
            Center(child: CircularProgressIndicator(),),

          const SizedBox(height: 16),
     if (answerSheets.isNotEmpty) ...[
  _buildSectionTitle('Detected Answers'),
  Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(8),
    ),
    child: ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: answerSheets.length,
      separatorBuilder: (context, index) => Divider(color: Colors.grey.shade300),
      itemBuilder: (context, index ) {
        bool isCorrect = index < detailedResults.length 
            ? detailedResults[index]['isCorrect'] 
            : false;
        return ListTile(
          title: Text(
            'Question ${index + 1}: ${answerSheets[index]}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isCorrect ? Colors.green : Colors.red,
            ),
          ),
          trailing: IconButton(
            icon: Icon(Icons.edit, color: Colors.grey),
            onPressed: () => _editAnswer(index),
          ),
        );
      },
    ),
  ),

   Padding(
    padding: const EdgeInsets.symmetric(vertical: 16.0),
    child: Text(
      'Score: $score/${answerKey.length} ($percentage%)',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: double.parse(percentage) >= 60 ? Colors.green : Colors.red,
      ),
      textAlign: TextAlign.center,
    ),
  ),
],
         
 

      

            ElevatedButton(
              onPressed: _addStudent,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF00BF6D),
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 48),
                shape: const StadiumBorder(),
              ),
              child: const Text("SAVE"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTextField(String hintText, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      hint: Text(hint),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: const BorderSide(color: Colors.grey),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    if (detailedResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Score: $score/${detailedResults.length} ($percentage%)',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Detailed Results:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: detailedResults.length,
            itemBuilder: (context, index) {
              final result = detailedResults[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Text('Q${result['questionNumber']}: '),
                    Text(
                      'Answer: ${result['studentAnswer']}',
                      style: TextStyle(
                        color: result['isCorrect'] ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(' (Correct: ${result['correctAnswer']})'),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
