

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecma/pages/analysisInfo.dart';
import 'package:ecma/pages/analysisPage.dart';
import 'package:ecma/pages/edit_student.dart';
import 'package:ecma/pages/welcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class analysisList extends StatelessWidget  {
    const analysisList ({Key? key});

  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Analysis List',
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
          'List of Analysis',
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
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('exam_detailed_analyses').snapshots(), 
                builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Text('Has error: ${snapshot.error}');
                  }

                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                
                  final filteredAnalyses = snapshot.data!.docs.where((doc) {
                    final subjectCode = doc['subject'].toString().toLowerCase();
                    return subjectCode.contains(_searchQuery);
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredAnalyses.length,
                    itemBuilder: (context, index) {
                      final listAnalysis = filteredAnalyses[index];
                      return SubjectListTile(
                        subjectCode: listAnalysis['subject'], 
                        studentkey: listAnalysis.id
                      );
                    }
                  );
                }
              )
            )
          ],
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(right: 16.0, bottom: 16.0),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => analysisPage()),
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
          hintText: 'Search Analysis',
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

                Navigator.push(context, MaterialPageRoute(builder: (context)=> AnalysisInfo(analysisId: studentId)));

          }, child: Text('View')),

          TextButton(onPressed: (){
              
              _firestore.collection('exam_detailed_analyses').doc(studentId).delete();

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully Deleted a Analysis'),backgroundColor:Colors.green,));
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
