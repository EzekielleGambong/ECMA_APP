import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AnalysisInfo extends StatefulWidget {
  final String analysisId;
  final String subjectName;

  const AnalysisInfo({Key? key, required this.analysisId, required this.subjectName}) : super(key: key);

  @override
  _AnalysisInfoState createState() => _AnalysisInfoState();
}

class _AnalysisInfoState extends State<AnalysisInfo> {
  String? contentResponse;
  bool isLoading = true;
  String errorMessage = '';

  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    fetchInfo();
  }

  Future<void> fetchInfo() async {
    try {
      DocumentSnapshot documentSnapshot = await _firestore
          .collection("exam_detailed_analyses")
          .doc(widget.analysisId)
          .get();

      if (documentSnapshot.exists) {
        setState(() {
          // Use null-aware operator to safely get the value
          contentResponse = documentSnapshot.data() is Map 
              ? (documentSnapshot.data() as Map)['detailedAnalysisResult'] as String?
              : null;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Analysis not found';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching analysis: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analysis Info: ${widget.subjectName}'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : contentResponse != null
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Analysis Result:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Safely use contentResponse
                                Text(contentResponse ?? 'No analysis available'),
                              ],
                            ),
                          ),
                        )
                      ],
                    )
                  : const Center(
                      child: Text('No analysis found'),
                    ),
    );
  }
}
