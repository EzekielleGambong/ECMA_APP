class BubbleSheetConfig {
  final String schoolName;
  final String examCode;
  final String? sectionCode;
  final DateTime examDate;
  final String examSet;
  final int numberOfQuestions;
  final int optionsPerQuestion;  
  final bool includeStudentInfo;
  final bool includeBarcode;
  final String? customInstructions;
  final double? fontSize;
  final double? bubbleSize;
  final int questionsPerRow;     
  final int columnCount;         

  BubbleSheetConfig({
    required this.schoolName,
    required this.examCode,
    this.sectionCode,
    required this.examDate,
    required this.examSet,
    required this.numberOfQuestions,
    this.optionsPerQuestion = 6,  
    this.includeStudentInfo = true,
    this.includeBarcode = true,
    this.customInstructions,
    this.fontSize = 12.0,
    this.bubbleSize = 20.0,
    this.questionsPerRow = 1,    
    this.columnCount = 4,        
  });

  Map<String, dynamic> toJson() => {
    'schoolName': schoolName,
    'examCode': examCode,
    'sectionCode': sectionCode,
    'examDate': examDate.toIso8601String(),
    'examSet': examSet,
    'numberOfQuestions': numberOfQuestions,
    'optionsPerQuestion': optionsPerQuestion,
    'includeStudentInfo': includeStudentInfo,
    'includeBarcode': includeBarcode,
    'customInstructions': customInstructions,
    'fontSize': fontSize,
    'bubbleSize': bubbleSize,
    'questionsPerRow': questionsPerRow,
    'columnCount': columnCount,
  };

  factory BubbleSheetConfig.fromJson(Map<String, dynamic> json) => BubbleSheetConfig(
    schoolName: json['schoolName'],
    examCode: json['examCode'],
    sectionCode: json['sectionCode'],
    examDate: DateTime.parse(json['examDate']),
    examSet: json['examSet'],
    numberOfQuestions: json['numberOfQuestions'],
    optionsPerQuestion: json['optionsPerQuestion'] ?? 6,
    includeStudentInfo: json['includeStudentInfo'] ?? true,
    includeBarcode: json['includeBarcode'] ?? true,
    customInstructions: json['customInstructions'],
    fontSize: json['fontSize']?.toDouble() ?? 12.0,
    bubbleSize: json['bubbleSize']?.toDouble() ?? 20.0,
    questionsPerRow: json['questionsPerRow'] ?? 1,
    columnCount: json['columnCount'] ?? 4,
  );
}
