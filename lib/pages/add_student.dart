import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'customCam.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AddStudent extends StatefulWidget {
  const AddStudent({super.key});

  @override
  State<AddStudent> createState() => _AddStudentState();
}

class _AddStudentState extends State<AddStudent> {
  final user = FirebaseAuth.instance.currentUser!;
  final _studentId = TextEditingController();
  final _studentName = TextEditingController();
  final _studentCourse = TextEditingController();
  final _studentSection = TextEditingController();
  final _studentSubject = TextEditingController();
  final _studentAnswerkey = TextEditingController();
  File? _pickedImage;

  Future<void> addStudent() async {
    await FirebaseFirestore.instance.collection('students').add({
      'student_id': _studentId.text,
      'student_name': _studentName.text,
      'student_course': _studentCourse.text,
      'student_section': _studentSection.text,
      'student_subject': _studentSubject.text,
      'student_answerkey': _studentAnswerkey.text,
      'user_email': user.email,
    });
  }

  Future<void> _openCamera() async {
    final File? capturedImage = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CustomCam()),
    );

    if (capturedImage != null) {
      setState(() {
        _pickedImage = capturedImage;
      });
    } else {
      // Handle the case where the user canceled the camera operation
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Scan it first before you add the student')));
    }
  }

  Future<void> _uploadImageToFirebase() async {
    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No image selected.')));
      return;
    }

    try {
      // Upload the image to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child('images/${DateTime.now()}.png');
      final UploadTask uploadTask = storageRef.putFile(_pickedImage!);
      final TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);

      // Get the download URL of the uploaded image
      final String downloadURL = await taskSnapshot.ref.getDownloadURL();

      // Save the download URL to Firestore
      await FirebaseFirestore.instance.collection('images').add({
        'url': downloadURL,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image uploaded successfully.')));
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
    }
  }

  Future<void> onScanPressed() async {
    await checkAnswers();
    if (_pickedImage != null) {
      await _uploadImageToFirebase();
    }
  }

  Future<void> checkAnswers() async {
    // Replace 'YOUR_API_KEY' with your actual API key from a secure source
    const apiKey = 'YOUR_API_KEY'; 

    final model = GenerativeModel(model: 'gemini-pro-vision', apiKey: apiKey);
    final List<Content> contents = [];
    final imageBytes = await _pickedImage!.readAsBytes();
    contents.add(
      Content.multi([
        DataPart('image/png', imageBytes),
        TextPart('''
        You are Expert in OMR Scanning.
        Analyze this OMR sheet image.
        Return the results in a clear JSON format with question numbers and selected answers.
        Capitalized the Scanned letter
        Example output:
        {
        "1": "A",
        "2": "B",
        "3": "C",
        "4": "D",
        "5": "A",
        }
        '''),
      ]),
    );

    final response = await model.generateContent(contents);
    print(response.text);
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(height: 5),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Student'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _studentId,
                decoration: const InputDecoration(labelText: 'Student ID'),
              ),
              TextField(
                controller: _studentName,
                decoration: const InputDecoration(labelText: 'Student Name'),
              ),
              TextField(
                controller: _studentCourse,
                decoration: const InputDecoration(labelText: 'Student Course'),
              ),
              TextField(
                controller: _studentSection,
                decoration: const InputDecoration(labelText: 'Student Section'),
              ),
              TextField(
                controller: _studentSubject,
                decoration: const InputDecoration(labelText: 'Student Subject'),
              ),
              TextField(
                controller: _studentAnswerkey,
                decoration: const InputDecoration(labelText: 'Student Answer Key'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.camera_alt,
                    label: 'Open Camera',
                    onPressed: _openCamera,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    icon: Icons.photo,
                    label: 'Choose from Gallery',
                    onPressed: () async {
                      // Implement file picker logic here
                    },
                    color: Colors.black,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onScanPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Scan"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  addStudent();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Add Student',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
