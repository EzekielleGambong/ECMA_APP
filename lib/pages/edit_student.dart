import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'student_list.dart';

class UpdateStudent extends StatefulWidget {
  final String studentId;
  const UpdateStudent({Key? key, required this.studentId}) : super(key: key);

  @override 
  UpdateStudentState  createState() => UpdateStudentState();
  

  
}

class UpdateStudentState extends  State<UpdateStudent> {

  final TextEditingController _nameController = TextEditingController();
  String? selectedSubjectCode;
  String? selectedExamType;
  String? results;
  String? ImageUrl;
  
  List<String> subjectCodes = [];

  List<String> answerKey = [];

  Future <void> fetchAnswerKey () async {

    try{

      if(selectedSubjectCode != null || selectedExamType != null){
          final QuerySnapshot querySnapshot = await _firestore
      .collection('subjects')
      .where('examType',isEqualTo: selectedExamType)
      .where('subject',isEqualTo: selectedSubjectCode)
      .get();

    if (querySnapshot.docs.isNotEmpty) {
     
        Map<String,dynamic > data = querySnapshot.docs.first.data() as Map<String,dynamic>;
        

        List<dynamic> answers =  data['answers'];
        setState(() {

          answerKey = List<String>.from(answers);
          if (!mounted) return;
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(answerKey.join(","))));
        });
    
    }else{
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No document Found')));
    }
      }else{
        print('Please select subject code and exam type');
      }

      

 }catch(e){
      if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(e.toString())));
 }
  } 



  Future<void> fetchSubjects() async {
    try {
      final snapshot = await _firestore.collection('subjects').get();
      setState(() {
        subjectCodes = snapshot.docs.map((doc) => doc['subject'].toString()).toList();
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
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        image1 = File(image.path);
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
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Filled the Subjects')));
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

     

        await _firestore.collection('students').doc(widget.studentId).update({
          'name': _nameController.text,
          'subjectCode': selectedSubjectCode,
          'examType': selectedExamType,
          'upload_image': downloadUrl,
          'examResults': results
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added Students successfully')));
        _nameController.clear;
        setState(() {
          image1 = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

Future<void>  scanning () async{

  const apiKey = 'AIzaSyBwQOMb7dwidhYKCitrxFgqKmmA0pmJfG8';
  final  imageBytes = await image1!.readAsBytes();

  final model = GenerativeModel(
    model: 'learnlm-1.5-pro-experimental', 
    apiKey: apiKey,
 );

    final content = [
    Content.multi([
      
    DataPart('image/png', imageBytes),
    TextPart('Scan 5x This is the Answerkey ${answerKey.toList()} and compare this Image is the answer by student'),
    TextPart('count the correct answers and said directly your score and percentage')
     
        ])
    
    ];

  final response = await model.generateContent(content);

    setState(() {
      results = response.text;
    });
}

Future <void> fetchstudents() async{

   DocumentSnapshot documentSnapshot = await _firestore.collection('students').doc(widget.studentId).get();

    if(documentSnapshot.exists){
      Map<String,dynamic> userData = documentSnapshot.data() as Map<String,dynamic>;

      setState(() {

        _nameController.text =  userData['name'];
        selectedSubjectCode = userData['subjectCode'];
        selectedExamType = userData['examType'];
        results = userData['examResults'];
        ImageUrl = userData['upload_image'];
       

      });

    }

}

void  onSelectionChanged() {
    if(selectedExamType != null  &&  selectedSubjectCode != null ){
      fetchAnswerKey();
    }
}

  @override
  void initState() {
    super.initState();
    fetchSubjects(); 
    fetchstudents();
  
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
          'Edit Student',
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
            _buildSectionTitle('Exam Type (Choose Again)'),
            const SizedBox(height: 8),
            _buildDropdown(
              hint: 'Select Exam Type',
              items: examTypes,
              value: selectedExamType,
              onChanged: (value) {
              setState(() => selectedExamType = value);
              onSelectionChanged();
              }),

              image1 == null ? Image.network(ImageUrl!): Image.file(image1!, height:  100, width: 100,),
            
            const SizedBox(height: 32),
            _buildSectionTitle('Exam Detection (Please Reupload Sheets)'),
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
              onPressed: scanning,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF00BF6D),
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 48),
                shape: const StadiumBorder(),
              ),
              child: const Text("Scan"),
            ),

            const SizedBox(height: 32),
            _buildSectionTitle('${results ?? 'Your Score'}'),
            const SizedBox(height: 100),
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
}
