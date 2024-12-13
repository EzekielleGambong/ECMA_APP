import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'add_student.dart';
import 'home.dart';
import 'analysisInfo.dart';

class StudentList extends StatefulWidget {
  const StudentList({super.key});

  @override
  State<StudentList> createState() => _StudentListState();
}

class _StudentListState extends State<StudentList> {
  final user = FirebaseAuth.instance.currentUser!;
  late final Stream<QuerySnapshot> _studentsStream;
  
  @override
  void initState() {
    super.initState();
    // Initialize stream once
    _studentsStream = FirebaseFirestore.instance
        .collection('students')
        .where('user_email', isEqualTo: user.email)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student List'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Signed in as: ${user.email!}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _studentsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final studentDocs = snapshot.data!.docs;
                if (studentDocs.isEmpty) {
                  return const Center(
                    child: Text('No students found. Add some students to get started!'),
                  );
                }

                return ListView.builder(
                  itemCount: studentDocs.length,
                  itemBuilder: (context, index) {
                    final studentData = studentDocs[index].data() as Map<String, dynamic>;
                    final subjects = List<Map<String, dynamic>>.from(
                      studentData['subjects'] as List<dynamic>? ?? []
                    );
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: ExpansionTile(
                        title: Text(
                          studentData['student_name'] ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'ID: ${studentData['student_id'] ?? 'N/A'}\nCourse: ${studentData['student_course'] ?? 'N/A'}',
                        ),
                        children: subjects.map((subject) => SubjectListTile(
                          subjectName: subject['subjectName'] ?? 'N/A',
                          subjectCode: subject['subjectCode'] ?? 'N/A',
                          subjectDescription: subject['subjectDescription'] ?? 'N/A',
                        )).toList(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddStudent()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class SubjectListTile extends StatelessWidget {
  final String subjectName;
  final String subjectCode;
  final String subjectDescription;

  const SubjectListTile({
    super.key,
    required this.subjectName,
    required this.subjectCode,
    required this.subjectDescription,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 32.0),
      title: Text(subjectName),
      subtitle: Text('$subjectCode\n$subjectDescription'),
      isThreeLine: true,
    );
  }
}
