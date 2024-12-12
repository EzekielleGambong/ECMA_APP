import 'package:cloud_firestore/cloud_firestore.dart';

import 'edit_subj.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'welcome.dart';
import 'add_subj.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const SubjectList());
}

// ignore: camel_case_types
class subjectData {
  final String id;
  final String examType;
  final String subject;

  subjectData({
    required this.id,
    required this.examType,
    required this.subject,
  });

  factory subjectData.fromFireStore(DocumentSnapshot doc) {
    Map<String, dynamic> dataSubject = doc.data() as Map<String, dynamic>;

    return subjectData(
        id: doc.id,
        examType: dataSubject['examType'],
        subject: dataSubject['subject']);
  }

  Map<String, dynamic> toFireStore() {
    return {'id': id, 'examType': examType, 'subject': subject};
  }
}

class SubjectList extends StatelessWidget {
  const SubjectList({Key? key}) : super(key: key);

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
  SubjectListScreen({super.key});

  @override
  _SubjectListScreenState createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  final _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';

  Stream<List<subjectData>> subjectList() {
    return _firestore.collection('subjects').snapshots().map((QuerySnapshot snapshot) {
      return snapshot.docs.map((doc) => subjectData.fromFireStore(doc)).toList();
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
            Navigator.push(context, MaterialPageRoute(builder: (context) => WelcomePage()));
          },
        ),
        title: const Text(
          'List of Subjects',
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
              onSearchChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase(); // Update the search query
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<subjectData>>(
                stream: subjectList(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final subjects = snapshot.data;

                  if (subjects == null || subjects.isEmpty) {
                    return const Center(child: Text('No subjects available'));
                  }

                  // Filter subjects based on search query
                  final filteredSubjects = subjects.where((subject) {
                    return subject.subject.toLowerCase().contains(_searchQuery);
                  }).toList();

                  if (filteredSubjects.isEmpty) {
                    return const Center(child: Text('No subjects match your search'));
                  }

                  return ListView.builder(
                    itemCount: filteredSubjects.length,
                    itemBuilder: (context, index) {
                      final subject = filteredSubjects[index];
                      return SubjectListTile(
                        subjectCode: subject.subject,
                        subjectKey: subject.id,
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
              MaterialPageRoute(builder: (context) => AddSubj()),
            );
          },
          child: const Icon(Icons.add, color: Colors.white, size: 32),
          backgroundColor: const Color(0xFF00BF6D),
          elevation: 4,
        ),
      ),
    );
  }
}

class SearchBar extends StatelessWidget {
  final Function(String) onSearchChanged;

  const SearchBar({required this.onSearchChanged, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search subjects',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: onSearchChanged,
      ),
    );
  }
}

class SubjectListTile extends StatelessWidget {
  final String subjectCode;
  final String subjectKey;

  SubjectListTile(
      {Key? key, required this.subjectCode, required this.subjectKey})
      : super(key: key);

      final _firestore = FirebaseFirestore.instance;

       void _showOptionDialog(BuildContext context,String subjectKey){
      showDialog(context: context,
      builder: (context)=> AlertDialog(
        title: const Text('Select an Action'),
        content: const Text('Do you want to Edit or Delete this Item'),
        actions: [
          TextButton(onPressed: (){

        Navigator.push( context, MaterialPageRoute( builder: (context) => EditSubj( subjectKey: subjectKey, )), );;

          }, child: Text('Edit')),

          TextButton(onPressed: (){
              
              _firestore.collection('subjects').doc(subjectKey).delete();

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully Deleted a Subject'),backgroundColor:Colors.green,));
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
          _showOptionDialog(context, subjectKey);
         
        },
      ),
    );
  }
}
