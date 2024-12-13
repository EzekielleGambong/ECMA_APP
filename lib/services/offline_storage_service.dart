import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/bubble_sheet_config.dart';
import '../models/subject.dart'; // Import the Subject model

class OfflineStorageService {
  static const String _bubbleSheetsKey = 'offline_bubble_sheets';
  static const String _scannedResultsKey = 'offline_scanned_results';
  static const String _userDataKey = 'offline_user_data';
  static const String _subjectsKey = 'offline_subjects';
  static const String _studentsKey = 'offline_students';
  
  // Singleton instance
  static final OfflineStorageService _instance = OfflineStorageService._internal();
  factory OfflineStorageService() => _instance;
  OfflineStorageService._internal();

  late final SharedPreferences _prefs;
  bool _initialized = false;

  List<Subject> _subjects = []; // Initialize subjects list

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    await _loadSubjects(); // Load subjects from storage
  }

  // Save bubble sheet configuration
  Future<void> saveBubbleSheet(String id, BubbleSheetConfig config) async {
    await _ensureInitialized();
    final sheets = await getBubbleSheets();
    sheets[id] = config.toJson();
    await _prefs.setString(_bubbleSheetsKey, jsonEncode(sheets));
  }

  // Get all saved bubble sheets
  Future<Map<String, dynamic>> getBubbleSheets() async {
    await _ensureInitialized();
    final String? sheetsJson = _prefs.getString(_bubbleSheetsKey);
    if (sheetsJson == null) return {};
    return Map<String, dynamic>.from(jsonDecode(sheetsJson));
  }

  // Save scanned result
  Future<void> saveScannedResult(String examId, Map<String, dynamic> result) async {
    await _ensureInitialized();
    final results = await getScannedResults();
    if (!results.containsKey(examId)) {
      results[examId] = [];
    }
    results[examId].add(result);
    await _prefs.setString(_scannedResultsKey, jsonEncode(results));
  }

  // Get all scanned results
  Future<Map<String, List<dynamic>>> getScannedResults() async {
    await _ensureInitialized();
    final String? resultsJson = _prefs.getString(_scannedResultsKey);
    if (resultsJson == null) return {};
    return Map<String, List<dynamic>>.from(jsonDecode(resultsJson));
  }

  // Save user data for offline access
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _ensureInitialized();
    await _prefs.setString(_userDataKey, jsonEncode(userData));
  }

  // Get saved user data
  Future<Map<String, dynamic>?> getUserData() async {
    await _ensureInitialized();
    final String? userDataJson = _prefs.getString(_userDataKey);
    if (userDataJson == null) return null;
    return Map<String, dynamic>.from(jsonDecode(userDataJson));
  }

  // Save PDF file locally
  Future<String> savePDFLocally(String examId, List<int> pdfBytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/bubble_sheets/$examId.pdf');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  // Get locally saved PDF
  Future<File?> getLocalPDF(String examId) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/bubble_sheets/$examId.pdf');
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  // Clear all offline data
  Future<void> clearAllData() async {
    await _ensureInitialized();
    await _prefs.clear();
    final directory = await getApplicationDocumentsDirectory();
    final bubbleSheetsDir = Directory('${directory.path}/bubble_sheets');
    if (await bubbleSheetsDir.exists()) {
      await bubbleSheetsDir.delete(recursive: true);
    }
  }

  // Subject management methods
  Future<void> addSubject(Subject subject) async {
    await _ensureInitialized();
    _subjects.add(subject);
    await _saveSubjects();
  }

  Future<void> deleteSubject(String id) async {
    await _ensureInitialized();
    _subjects.removeWhere((subject) => subject.id == id);
    await _saveSubjects();
  }

  Future<List<Subject>> getSubjects() async {
    await _ensureInitialized();
    return _subjects;
  }

  Future<void> _saveSubjects() async {
    await _ensureInitialized();
    final subjectsJson = _subjects.map((subject) => subject.toJson()).toList();
    await _prefs.setString(_subjectsKey, jsonEncode(subjectsJson));
  }

  Future<void> _loadSubjects() async {
    await _ensureInitialized();
    final String? subjectsJson = _prefs.getString(_subjectsKey);
    if (subjectsJson != null) {
      final List<dynamic> subjectsList = jsonDecode(subjectsJson);
      _subjects = subjectsList.map((json) => Subject.fromJson(json)).toList();
    }
  }

  // Students Management
  Future<List<Map<String, dynamic>>> getStudents() async {
    await _ensureInitialized();
    final String? studentsJson = _prefs.getString(_studentsKey);
    if (studentsJson == null) return [];
    final List<dynamic> decoded = jsonDecode(studentsJson);
    return List<Map<String, dynamic>>.from(decoded);
  }

  Future<void> addStudent(Map<String, dynamic> student) async {
    await _ensureInitialized();
    final students = await getStudents();
    student['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    students.add(student);
    await _prefs.setString(_studentsKey, jsonEncode(students));
  }

  Future<void> updateStudent(String studentId, Map<String, dynamic> updates) async {
    await _ensureInitialized();
    final students = await getStudents();
    final index = students.indexWhere((student) => student['id'] == studentId);
    if (index != -1) {
      students[index] = {...students[index], ...updates};
      await _prefs.setString(_studentsKey, jsonEncode(students));
    }
  }

  Future<void> deleteStudent(String studentId) async {
    await _ensureInitialized();
    final students = await getStudents();
    students.removeWhere((student) => student['id'] == studentId);
    await _prefs.setString(_studentsKey, jsonEncode(students));
  }

  // Analysis Data
  Future<Map<String, List<Map<String, dynamic>>>> getAnalysisData() async {
    await _ensureInitialized();
    final subjects = await getSubjects();
    final scannedResults = await getScannedResults();
    
    final analysisData = <String, List<Map<String, dynamic>>>{};
    
    for (final subject in subjects) {
      final subjectId = subject.id;
      final subjectResults = <Map<String, dynamic>>[];
      
      for (final entry in scannedResults.entries) {
        if (entry.key.startsWith(subjectId)) {
          for (final result in entry.value) {
            subjectResults.add({
              'examId': entry.key,
              'result': result,
              'timestamp': result['timestamp'],
            });
          }
        }
      }
      
      analysisData[subjectId] = subjectResults;
    }
    
    return analysisData;
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }
}
