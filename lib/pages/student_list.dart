import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_student.dart';
import 'home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'analysisInfo.dart';

class StudentList extends StatefulWidget {
  const StudentList({super.key});

  @override
  State<StudentList> createState() => _StudentListState();
}

class _StudentListState extends State<StudentList> {
  final user = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student List'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const HomePage();
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('signed in as: ${user.email!}'),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('students')
                    .where('user_email', isEqualTo: user.email)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  final studentDocs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: studentDocs.length,
                    itemBuilder: (context, index) {
                      final studentData = studentDocs[index].data() as Map<String, dynamic>;
                      // Assuming each student has a 'subjects' field which is a list of maps
                      final subjects = studentData['subjects'] as List<dynamic>? ?? [];
                      return ExpansionTile(
                        title: Text(studentData['student_name'] ?? 'N/A'),
                        subtitle: Text(
                            'ID: ${studentData['student_id'] ?? 'N/A'}, Course: ${studentData['student_course'] ?? 'N/A'}'),
                        children: [
                          for (final subject in subjects)
                            SubjectListTile(
                              subjectName: subject['subjectName'] ?? 'N/A',
                              subjectCode: subject['subjectCode'] ?? 'N/A',
                              subjectDescription: subject['subjectDescription'] ?? 'N/A',
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return const AddStudent();
              },
            ),
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
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(subjectName),
        subtitle: Text('$subjectCode\n$subjectDescription'),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            // Show a confirmation dialog
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Confirm Delete'),
                  content: const Text('Are you sure you want to delete this subject?'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                    ),
                    TextButton(
                      child: const Text('Delete'),
                      onPressed: () {
                        // TODO: Implement delete functionality
                        // This is where you would delete the subject from the database
                        // After deleting, you might want to refresh the list of subjects
                        Navigator.of(context).pop(); // Close the dialog
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return AnalysisInfo(
                  subjectName: subjectName, analysisId: '',
                );
              },
            ),
          );
        },
      ),
    );
  }
}
