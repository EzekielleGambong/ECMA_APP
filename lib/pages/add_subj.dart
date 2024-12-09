import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'subject_list.dart';

void main() {
  runApp(const AddSubj());
}

class AddSubj extends StatelessWidget {
  const AddSubj({Key? key}) : super(key: key);

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

class ExaminationScreen extends StatelessWidget {
  const ExaminationScreen({Key? key}) : super(key: key);

 


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
          'Add Subject',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: const ExaminationBody(),
    );
  }
}

class ExaminationBody extends StatefulWidget {
  const ExaminationBody({Key? key}) : super(key: key);

  @override
  _ExaminationBodyState createState() => _ExaminationBodyState();
}

class _ExaminationBodyState extends State<ExaminationBody> {
  String? selectedExamType;

   final _firestore = FirebaseFirestore.instance;
   final _storage = FirebaseStorage.instance;

  final TextEditingController _subjectController =  TextEditingController();
 
  List<TextEditingController> controllers = []; 
  int numberFields = 0;

 

    Future<void> _showNumberInputModals () async{

          final TextEditingController numberController = TextEditingController();

          await showDialog(
          context: context, 
          builder: (BuildContext context){
                return AlertDialog(
                    title:const Text('Enter Number of Answer key '),
                    content: TextField(
                      controller: numberController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Number of Answer key',),
                      
                    ),
                    actions: <Widget>[
                      ElevatedButton(
                        onPressed: (){
                         setState(() {
                           numberFields = int.parse(numberController.text);
                           controllers = List.generate(numberFields, (index)=> TextEditingController());
                         });

                          Navigator.of(context).pop();
                        }, child: const Text('Confirm'))
                    ],
                );
          
          }
          );
    }

   Future<void> _addSubject() async {
  String subject = _subjectController.text;
  String? examType = selectedExamType;
  
  
  List<String> answer = [];
  for(int i = 0; i < numberFields; i++){
    answer.add(controllers[i].text);
  }
  
  
  if(subject.isEmpty || examType == null || answer.isEmpty){
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill out all fields'))
    );
    return;
  }

  try {
  
    final QuerySnapshot querySnapshot = await _firestore
      .collection('subjects')
      .where('subject', isEqualTo: subject)
      .get();

   
    if (querySnapshot.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject already exists!'))
      );
      return;
    }

   
    await _firestore.collection('subjects').add({
      'subject': subject,
      'examType': examType,
      'answers': answer,
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Successfully Added'))
    );
  } catch(e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString()))
    );
  }
}

void _removeLastAnswerKey() {
    if (numberFields > 0) {
      setState(() {
        numberFields--;
        controllers.last.dispose(); // Dispose the last controller
        controllers.removeLast(); // Remove the last controller
      });
    }
  }
  

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              
             //Subject Input 

           Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subject',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _subjectController ,
          decoration: InputDecoration(
            hintText: 'Enter Subject',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    ),
   const SizedBox(height: 16),

   //Examp Drop Down
     Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Exam Type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedExamType,
          items: [
            'Quiz 1',
            'Quiz 2',
            'Quiz 3',
            'Quiz 4',
            'Exam',
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
              horizontal: 16,
              vertical: 12,
            ),
          ),
          hint: const Text('Select Exam Type'),
        ),
      ],
    ),
  
              const SizedBox(height: 32),

      //Exam Detection
     Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Exam Detection',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.list,
                          label: 'Create Answer Key',
                          onPressed: _showNumberInputModals,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.remove_circle_outline,
                          label: 'Remove Answer Key',
                          onPressed: _removeLastAnswerKey,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 300,
                    child: SingleChildScrollView(
                      child: Column(
                        children: List.generate(numberFields, (index) {
                          return TextField(
                            controller: controllers[index],
                            decoration: InputDecoration(hintText: 'Field ${index + 1}'),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Total Number: ${numberFields.toString()}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                ],
              ),



      const SizedBox(height: 2),
      //Save Button
      Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ElevatedButton(
        onPressed:_addSubject,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF00BF6D),
          foregroundColor: Colors.white,
          minimumSize: const Size(200, 48),
          shape: const StadiumBorder(),
        ),
        child: const Text("SAVE"),
      ),
    ),
  
            ],
          ),
        ),
      ),
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
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: const BorderSide(color: Colors.grey),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }


}




