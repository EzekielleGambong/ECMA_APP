import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecma/pages/add_student.dart';
import 'package:ecma/pages/home.dart';
import 'edit_student.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'welcome.dart';



class studentData {
  final String id;
  final String name;
  final String examType;

  final String SubjectCode;

  studentData(
      {required this.id,
      required this.examType,
      required this.name,
      required this.SubjectCode});

  factory studentData.fromFireStore(DocumentSnapshot doc) {
    Map<String, dynamic> dataSubject = doc.data() as Map<String, dynamic>;

    return studentData(
        id: doc.id,
        name: dataSubject['name'],
        examType: dataSubject['examType'],
        SubjectCode: dataSubject['subjectCode']);
  }

  Map<String, dynamic> toFireStore() {
    return {
      'id': id,
      'examType': examType,
      'subjectCode': SubjectCode,
      'name': name
    };
  }
}

class StudentList extends StatelessWidget {
  const StudentList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Subject List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
      ),
      home: SubjectListScreen(),
    );
  }
}

class SubjectListScreen extends StatefulWidget {
  const SubjectListScreen({Key? key}) : super(key: key);

  @override
  _SubjectListScreenState createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  final _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';

  Stream<List<studentData>> studentList() {
    return _firestore
        .collection('students')
        .snapshots()
        .map((QuerySnapshot snapshot) {
      return snapshot.docs
          .map((doc) => studentData.fromFireStore(doc))
          .toList();
    });
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
             Navigator.push(context, MaterialPageRoute(builder: (context)=> WelcomePage()));
          },
        ),
        title: const Text(
          'List of Students',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            SearchBar(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<studentData>>(
                stream: studentList(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

           
                  final students = snapshot.data;

                  if (students == null || students.isEmpty) {
                    return const Center(child: Text('No students available'));
                  }

           
                  final filteredStudents = students.where((student) {
             
                    return student.name.toLowerCase().contains(_searchQuery) ||
                           student.SubjectCode.toLowerCase().contains(_searchQuery) ||
                           student.examType.toLowerCase().contains(_searchQuery);
                  }).toList();

                
                  return ListView.builder(
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      return SubjectListTile(
                        subjectCode: student.name,
                        studentkey: student.id,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(right: 16.0, bottom: 16.0),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddStudent()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8.0),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 32,
            ),
          ),
          backgroundColor: const Color(0xFF00BF6D),
          elevation: 4,
        ),
      ),
    );
  }
}

class SearchBar extends StatelessWidget {
  final Function(String) onChanged;

  const SearchBar({Key? key, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search Students',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
class SubjectListTile extends StatelessWidget {
  final String subjectCode;
  final String studentkey;
   SubjectListTile({Key? key, required this.subjectCode, required this.studentkey}): super(key: key);
        final _firestore = FirebaseFirestore.instance;
       void _showOptionDialog(BuildContext context,String studentId){
      showDialog(context: context,
      builder: (context)=> AlertDialog(
        title: const Text('Select an Action'),
        content: const Text('Do you want to Edit or Delete this Item'),
        actions: [
          TextButton(onPressed: (){

                Navigator.push(context, MaterialPageRoute(builder: (context)=> UpdateStudent(studentId: studentId)));

          }, child: Text('Edit')),

          TextButton(onPressed: (){
              
              _firestore.collection('students').doc(studentId).delete();

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully Deleted a Student'),backgroundColor:Colors.green,));
                Navigator.of(context).pop();
          }, child: const Text('Delete'))
        ],

  ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        title: Text(
          subjectCode,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          _showOptionDialog(context,studentkey);
        },
      ),
    );
  }
}
