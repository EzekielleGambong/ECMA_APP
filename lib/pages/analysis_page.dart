import 'package:flutter/material.dart';
import '../services/offline_storage_service.dart';
import '../models/subject.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  final _offlineStorage = OfflineStorageService();
  bool _isLoading = false;
  Map<String, dynamic> _analysisData = {};
  String _selectedSubject = '';

  @override
  void initState() {
    super.initState();
    _loadAnalysisData();
  }

  Future<void> _loadAnalysisData() async {
    setState(() => _isLoading = true);
    try {
      final subjects = await _offlineStorage.getSubjects();
      final scannedResults = await _offlineStorage.getScannedResults();
      
      // Process data for analysis
      _analysisData = _processAnalysisData(subjects, scannedResults);
      
      if (subjects.isNotEmpty) {
        _selectedSubject = subjects.first.id;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading analysis data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _processAnalysisData(
    List<Subject> subjects,
    Map<String, List<dynamic>> scannedResults,
  ) {
    final analysisData = <String, dynamic>{};
    
    for (final subject in subjects) {
      final subjectId = subject.id;
      final subjectResults = <String, dynamic>{};
      
      // Calculate average scores
      double totalScore = 0;
      int totalExams = 0;
      
      for (final examId in scannedResults.keys) {
        if (examId.startsWith(subjectId)) {
          final examResults = scannedResults[examId]!;
          double examTotal = 0;
          
          for (final result in examResults) {
            examTotal += _calculateScore(result);
          }
          
          final examAverage = examTotal / examResults.length;
          subjectResults[examId] = {
            'average': examAverage,
            'totalStudents': examResults.length,
            'distribution': _calculateDistribution(examResults),
          };
          
          totalScore += examAverage;
          totalExams++;
        }
      }
      
      if (totalExams > 0) {
        subjectResults['overall'] = {
          'average': totalScore / totalExams,
          'totalExams': totalExams,
        };
      }
      
      analysisData[subjectId] = subjectResults;
    }
    
    return analysisData;
  }

  double _calculateScore(Map<String, dynamic> result) {
    // Implement score calculation based on your scoring system
    return 0.0; // Placeholder
  }

  Map<String, int> _calculateDistribution(List<dynamic> results) {
    final distribution = <String, int>{
      'A': 0, 'B': 0, 'C': 0, 'D': 0, 'F': 0,
    };
    
    for (final result in results) {
      final score = _calculateScore(result as Map<String, dynamic>);
      if (score >= 90) distribution['A'] = distribution['A']! + 1;
      else if (score >= 80) distribution['B'] = distribution['B']! + 1;
      else if (score >= 70) distribution['C'] = distribution['C']! + 1;
      else if (score >= 60) distribution['D'] = distribution['D']! + 1;
      else distribution['F'] = distribution['F']! + 1;
    }
    
    return distribution;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalysisData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSubjectSelector(),
                  const SizedBox(height: 16),
                  if (_selectedSubject.isNotEmpty) ...[
                    _buildOverallStats(),
                    const SizedBox(height: 24),
                    _buildPerformanceChart(),
                    const SizedBox(height: 24),
                    _buildDistributionChart(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSubjectSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedSubject,
      decoration: const InputDecoration(
        labelText: 'Select Subject',
        border: OutlineInputBorder(),
      ),
      items: _analysisData.keys.map((subjectId) {
        return DropdownMenuItem(
          value: subjectId,
          child: Text(subjectId),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedSubject = value);
        }
      },
    );
  }

  Widget _buildOverallStats() {
    final subjectData = _analysisData[_selectedSubject];
    if (subjectData == null || !subjectData.containsKey('overall')) {
      return const Text('No data available');
    }

    final overall = subjectData['overall'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Average Score: ${overall['average'].toStringAsFixed(2)}%'),
            Text('Total Exams: ${overall['totalExams']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Trend',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  // Implement chart data based on your requirements
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 0),
                        // Add more spots based on your data
                      ],
                      isCurved: true,
                      color: Colors.blue,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grade Distribution',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  // Implement chart data based on your requirements
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  barGroups: [
                    // Add bar groups based on your data
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
