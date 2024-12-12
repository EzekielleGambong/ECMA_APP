import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({Key? key}) : super(key: key);

  @override
  AnalysisPageState createState() => AnalysisPageState();
}

class AnalysisPageState extends State<AnalysisPage> {
 final ImagePicker _picker = ImagePicker();

   String? totalquestions;
   String? average_correct_rate;
   String? most_challenging_questions;
   String? potential_learning_gaps;

  List<File>? imageFiles = [];
  String? contentResponse;
  bool isLoading = false;
  String? selectSubject;
  List<String> selectedSubjectCode = [];
  List<String > answerKey = [];
  final _firestore = FirebaseFirestore.instance;

  Future<void> fetchSubjects() async{
      try{
        final snapshot = await _firestore.collection('subjects').get();
        setState(() {
           selectedSubjectCode = snapshot.docs.map((doc)=> doc['subject'].toString()).toList();
        });
      }catch(e){
        if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No Subject Found')));
      }
  }

  Future<void> fetchAnswerKey () async{
        try{
            final QuerySnapshot querySnapshot = await _firestore
            .collection('subjects')
            .where('subject',isEqualTo: selectSubject)
            .get();

          if(querySnapshot.docs.isNotEmpty){
            Map<String,dynamic>  data = querySnapshot.docs.first.data() as Map<String,dynamic>;
            List<dynamic> answers = data['answers'];

            setState(() {
              answerKey = List<String>.from(answers);
               if (!mounted) return;
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(answerKey.join(","))));
            });

          }else{
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No Data Found')));
          }
        }catch (e){
          if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No Data Found')));
        }
  }

  Future<void> _uploadMultipleImage() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    
    if (pickedFiles != null) {
      setState(() {
        imageFiles = pickedFiles.map((XFile pickedFile) => File(pickedFile.path)).toList();
      });
    }
  }
Future<void> analysis() async {
  if (imageFiles == null || imageFiles!.isEmpty) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No Image Uploaded'))
    );
    return;
  }

  if (selectSubject == null || answerKey.isEmpty) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a subject and ensure answer key is loaded'))
    );
    return;
  }

  setState(() {
    isLoading = true;
  });

  try {
    const apiKey = 'AIzaSyBwQOMb7dwidhYKCitrxFgqKmmA0pmJfG8'; // Replace with your actual API key
    
    List<Uint8List> imageListBytes = await Future.wait(
      imageFiles!.map((file) => file.readAsBytes())
    );

    final model = GenerativeModel(
      model: 'gemini-1.5-pro-002',
      apiKey: apiKey
    );

    final content = [
      Content.multi([
        for (final imageBytes in imageListBytes)
        DataPart('image/png', imageBytes),
        TextPart('''Analyze the provided exam answer sheets (images) and generate a comprehensive, structured, and data-driven report based on the following requirements:
Exam Analysis Parameters:
Input Data:
Answer Sheets: Images where each question has four answer choices (A, B, C, D) represented by circles, with one circle shaded to indicate the selected answer.
Correct Answer Key:  ${answerKey.join(', ')}
Total Number of Students: ${imageFiles!.length}
Detailed Analysis Requirements:
For each question, calculate and report the following:
Correct Students: Total number of students who selected the correct answer.
Incorrect Students: Total number of students who selected an incorrect answer.
Incorrect Answer Distribution: A breakdown of the most common incorrect answers, including the number of students who selected each.
Percentage of Incorrect Answers: The percentage of students who answered the question incorrectly.
Provide the analysis in the following structured format:

Question X:
- Correct Answers: [Number of students]
- Incorrect Answers: [Number of students]
- Incorrect Answer Distribution:
  a) [Answer A]: [Number of students]
  b) [Answer B]: [Number of students]
- Percentage of Wrong Answers: [Percentage]
Overall Exam Performance Summary:
Total Questions: Total number of questions analyzed.
Average Correct Answer Rate: Average percentage of correct answers across all questions.
Most Challenging Questions: Identify questions with the highest percentage of incorrect answers.
Potential Learning Gaps: Highlight patterns in incorrect answers that indicate areas where students struggled.
Recommendation Section:
Insights for Students: Provide actionable insights to help students improve their understanding.
Suggestions for Improvement: Recommend specific areas requiring additional focus and study.
Strategies for Learning: Offer strategies to address common errors and misconceptions.

Output Format:
The analysis should be returned as a JSON object with the following structure:
{
  "questions": [
    {
      "question_number": 1,
      "correct_students": 30,
      "incorrect_students": 20,
      "incorrect_answer_distribution": {
        "A": 10,
        "B": 5,
        "C": 5
      },
      "incorrect_percentage": 40
    },
    {
      "question_number": 2,
      "correct_students": 25,
      "incorrect_students": 25,
      "incorrect_answer_distribution": {
        "A": 15,
        "B": 5,
        "C": 5
      },
      "incorrect_percentage": 50
    }
  ],
  "overall_summary": {
    "total_questions": 5,
    "average_correct_rate": 60,
    "most_challenging_questions": [2, 4],
    "potential_learning_gaps": "Students struggled with concepts related to questions 2 and 4."
  },
  "recommendations": {
    "insights": "Focus on understanding the concepts behind questions 2 and 4.",
    "suggestions": "Provide additional practice materials and review sessions for these topics."
  }
}

Additional Notes:
Ensure the analysis is accurate, clear, and actionable.
Accurately interpret the shaded circles in the images to determine the selected answers for each question.
Cross-check the shaded answers against the provided answer key to ensure correctness.
The JSON output should be well-structured and easy to parse programmatically.'''),
        TextPart('Generate a comprehensive, structured analysis report.')
      ])
    ];

    final response = await model.generateContent(content);
 
    setState(() {
      contentResponse = response.text!.replaceAll("```json", "").replaceAll("```", "");
      try{
    Map<String,dynamic> analysisData = jsonDecode("[" + contentResponse! + "]")[0];
    setState(() {
         totalquestions = analysisData['overall_summary']['total_questions'].toString();
         average_correct_rate = analysisData['overall_summary']['average_correct_rate'].toString();
         most_challenging_questions = analysisData['overall_summary']['most_challenging_questions'].toString();
         potential_learning_gaps = analysisData['overall_summary']['potential_learning_gaps'].toString();
    });
      }catch(jsonError){
        if (!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error parsing analysis JSON: $jsonError'))
        );
      }
  
      isLoading = false;
    });

    // Optional: Save detailed analysis to Firestore
    await _saveDetailedAnalysisToFirestore(response.text.toString(), imageFiles!.length);

  } catch (e) {
    setState(() {
      isLoading = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error during detailed analysis: $e'))
    );
  }
}

// Enhanced Firestore saving method
Future<void> _saveDetailedAnalysisToFirestore(String analysisResult, int totalStudents) async {
  try {
    await _firestore.collection('exam_detailed_analyses').add({
      'subject': selectSubject,
      'analysisDate': FieldValue.serverTimestamp(),
      'totalStudents': totalStudents,
      'detailedAnalysisResult': analysisResult,
      'answerKey': answerKey,
      'metadata': {
        'imageCount': totalStudents,
        'analysisTimestamp': DateTime.now().toIso8601String()
      }
    });
  } catch (e) {
    print('Error saving detailed analysis to Firestore: $e');
  }
}

  void  onSelectionChanged() {
    if( selectSubject != null ){
      fetchAnswerKey();
    }
}

  @override
  void initState() {
    super.initState();
    fetchSubjects();
  }



 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Exam Sheet Analysis'),
      centerTitle: true,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child:Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
     
          _buildSubjectDropdown(),
          
          const SizedBox(height: 16),
          
        
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _uploadMultipleImage,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Upload Exam Sheets'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildImageGridView(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
     
          _buildAnalysisButton(),
          
          const SizedBox(height: 16),
        
            if(isLoading)
            const Center(child: CircularProgressIndicator(),),

            const SizedBox(height: 8),
          
     
          _buildAnalysisResults(),
        ],
      ),
      )
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
    isExpanded: true,
    decoration: InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      labelText: hint,
    ),
    items: items.map((item) {
      return DropdownMenuItem<String>(
        value: item,
        child: Text(
          item,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }).toList(),
    onChanged: onChanged,
    hint: Text(
      hint,
      style: const TextStyle(color: Colors.grey),
    ),
    validator: (value) {
      if (value == null) {
        return 'Please select a subject';
      }
      return null;
    },
  );
}

Widget _buildSubjectDropdown() {
  return _buildDropdown(
    hint: 'Select Subject Code',
    items: selectedSubjectCode,
    value: selectSubject,
    onChanged: (value) {
      setState(() => selectSubject = value);
      onSelectionChanged();
    },
  );
}

Widget _buildImageGridView() {
  if (imageFiles == null || imageFiles!.isEmpty) {
    return const Center(
      child: Text(
        'No images uploaded',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
  
  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
    ),
    itemCount: imageFiles!.length,
    itemBuilder: (context, index) {
      return _buildImageThumbnail(index);
    },
  );
}

Widget _buildImageThumbnail(int index) {
  return Stack(
    fit: StackFit.expand,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          imageFiles![index],
          fit: BoxFit.cover,
        ),
      ),
      Positioned(
        top: 4,
        right: 4,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                imageFiles!.removeAt(index);
              });
            },
          ),
        ),
      ),
    ],
  );
}

Widget _buildAnalysisButton() {
  return ElevatedButton.icon(
    onPressed: (imageFiles != null && imageFiles!.isNotEmpty && selectSubject != null) 
      ? (isLoading ? null : analysis) 
      : null,
    icon: isLoading 
      ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : const Icon(Icons.analytics_outlined),
    label: Text(
      isLoading ? 'Analyzing...' : 'Analyze Exam Sheets',
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 50),
      backgroundColor: (imageFiles != null && imageFiles!.isNotEmpty && selectSubject != null) 
        ? null 
        : Colors.grey,
    ),
  );
}

Widget _buildAnalysisResults() {
  if (contentResponse == null) {
    return const SizedBox.shrink();
  }

  return Card(
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analysis Results',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildResultRow('Total Questions', totalquestions),
          _buildResultRow('Average Correct Rate', average_correct_rate),
          _buildResultRow('Most Challenging Questions', most_challenging_questions),
          _buildResultRow('Potential Learning Gaps', potential_learning_gaps),
        ],
      ),
    ),
  );



}

Widget _buildResultRow(String label, String? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          value ?? 'Not Available',
          maxLines: 3,
          style: TextStyle(
            color: value != null ? Colors.black : Colors.grey,
          ),
        ),
      ],
    ),
  );
}
}
