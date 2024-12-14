import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'analysisInfo.dart';
import 'analysisPage.dart';
import 'welcome.dart';

class analysisList extends StatefulWidget {
  const analysisList({super.key});

  @override
  State<analysisList> createState() => _analysisListState();
}

class _analysisListState extends State<analysisList> {
  final user = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis List'),
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
                    return const WelcomePage();
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
                    .collection('exam_detailed_analyses')
                    .where('user_email', isEqualTo: user.email)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  final analysisDocs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: analysisDocs.length,
                    itemBuilder: (context, index) {
                      final analysisData = analysisDocs[index].data() as Map<String, dynamic>;
                      final analysisId = analysisDocs[index].id;
                      return SubjectListTile(
                        analysisId: analysisId,
                        analysisName: analysisData['analysis_name'] ?? 'N/A',
                        subjectName: analysisData['subject_name'] ?? 'N/A',
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
                return const AnalysisPage();
              },
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class SubjectListTile extends StatefulWidget {
  final String analysisId;
  final String analysisName;
  final String subjectName;

  const SubjectListTile({
    super.key,
    required this.analysisId,
    required this.analysisName,
    required this.subjectName,
  });

  @override
  State<SubjectListTile> createState() => _SubjectListTileState();
}

class _SubjectListTileState extends State<SubjectListTile> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(widget.analysisName),
        subtitle: Text('Subject: ${widget.subjectName}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            // Show a confirmation dialog
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Confirm Delete'),
                  content: const Text('Are you sure you want to delete this analysis?'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                    ),
                    TextButton(
                      child: const Text('Delete'),
                      onPressed: () async {
                        // Delete the analysis from Firestore
                        try {
                          await FirebaseFirestore.instance
                              .collection('exam_detailed_analyses')
                              .doc(widget.analysisId)
                              .delete();
                          // After deleting, refresh the list of analyses
                          setState(() {});
                          Navigator.of(context).pop(); // Close the dialog
                        } catch (e) {
                          print('Error deleting analysis: $e');
                          Navigator.of(context).pop(); // Close the dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to delete analysis.'),
                            ),
                          );
                        }
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
                  subjectName: widget.subjectName, analysisId: widget.analysisId,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
