import 'dart:ui';  // Add this import for Rect

class BubblePosition {
  final double x;
  final double y;
  final String value;

  const BubblePosition({
    required this.x,
    required this.y,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'value': value,
  };

  factory BubblePosition.fromJson(Map<String, dynamic> json) => BubblePosition(
    x: json['x'] as double,
    y: json['y'] as double,
    value: json['value'] as String,
  );
}

class Question {
  final String id;
  final List<BubblePosition> bubbles;

  const Question({
    required this.id,
    required this.bubbles,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'bubbles': bubbles.map((b) => b.toJson()).toList(),
  };

  factory Question.fromJson(Map<String, dynamic> json) => Question(
    id: json['id'] as String,
    bubbles: (json['bubbles'] as List).map((b) => BubblePosition.fromJson(b)).toList(),
  );
}

class Section {
  final String id;
  final List<Question> questions;

  const Section({
    required this.id,
    required this.questions,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'questions': questions.map((q) => q.toJson()).toList(),
  };

  factory Section.fromJson(Map<String, dynamic> json) => Section(
    id: json['id'] as String,
    questions: (json['questions'] as List).map((q) => Question.fromJson(q)).toList(),
  );
}

class GridSquareConfig {
  final double size;  // Size of each grid square
  final double spacing;  // Spacing between grid squares
  final int numSquares;  // Number of squares to draw
  final double cornerRadius;  // Radius for rounded corners
  final double strokeWidth;  // Width of the grid lines

  const GridSquareConfig({
    this.size = 20.0,
    this.spacing = 5.0,
    this.numSquares = 4,
    this.cornerRadius = 3.0,
    this.strokeWidth = 2.0,
  });

  // Calculate total width including spacing
  double get totalWidth => (size * numSquares) + (spacing * (numSquares - 1));

  static GridSquareConfig fromJson(Map<String, dynamic> json) => GridSquareConfig(
    size: json['size']?.toDouble() ?? 20.0,
    spacing: json['spacing']?.toDouble() ?? 5.0,
    numSquares: json['numSquares'] ?? 4,
    cornerRadius: json['cornerRadius']?.toDouble() ?? 3.0,
    strokeWidth: json['strokeWidth']?.toDouble() ?? 2.0,
  );

  Map<String, dynamic> toJson() => {
    'size': size,
    'spacing': spacing,
    'numSquares': numSquares,
    'cornerRadius': cornerRadius,
    'strokeWidth': strokeWidth,
  };
}

class CornerSquare {
  final double x;
  final double y;
  final double size;

  const CornerSquare({
    required this.x,
    required this.y,
    this.size = 20.0,
  });

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'size': size,
  };

  factory CornerSquare.fromJson(Map<String, dynamic> json) => CornerSquare(
    x: json['x'] as double,
    y: json['y'] as double,
    size: json['size'] as double? ?? 20.0,
  );
}

class BubbleSheetConfig {
  final String schoolName;
  final String examCode;
  final String sectionCode;
  final DateTime examDate;
  final String examSet;
  final List<Section> sections;
  final int questionsPerRow;
  final double bubbleSize;
  final String studentName;
  final String studentNumber;
  final int totalQuestions;
  final int numColumns;
  final List<CornerSquare> cornerSquares;

  const BubbleSheetConfig({
    required this.schoolName,
    required this.examCode,
    required this.sectionCode,
    required this.examDate,
    required this.examSet,
    required this.sections,
    required this.questionsPerRow,
    this.bubbleSize = 16.0,
    this.studentName = '',
    this.studentNumber = '',
    required this.totalQuestions,
    required this.numColumns,
    List<CornerSquare>? cornerSquares,
  }) : this.cornerSquares = cornerSquares ?? const [
    CornerSquare(x: 0.05, y: 0.05),  // Top-left
    CornerSquare(x: 0.95, y: 0.05),  // Top-right
    CornerSquare(x: 0.05, y: 0.95),  // Bottom-left
    CornerSquare(x: 0.95, y: 0.95),  // Bottom-right
  ];

  factory BubbleSheetConfig.fromJson(Map<String, dynamic> json) => BubbleSheetConfig(
    schoolName: json['schoolName'] as String,
    examCode: json['examCode'] as String,
    sectionCode: json['sectionCode'] as String,
    examDate: DateTime.parse(json['examDate'] as String),
    examSet: json['examSet'] as String,
    sections: (json['sections'] as List).map((s) => Section.fromJson(s)).toList(),
    questionsPerRow: json['questionsPerRow'] as int,
    bubbleSize: json['bubbleSize']?.toDouble() ?? 16.0,
    studentName: json['studentName'] as String? ?? '',
    studentNumber: json['studentNumber'] as String? ?? '',
    totalQuestions: json['totalQuestions'] as int,
    numColumns: json['numColumns'] as int,
    cornerSquares: (json['cornerSquares'] as List?)?.map((s) => CornerSquare.fromJson(s)).toList(),
  );

  Map<String, dynamic> toJson() => {
    'schoolName': schoolName,
    'examCode': examCode,
    'sectionCode': sectionCode,
    'examDate': examDate.toIso8601String(),
    'examSet': examSet,
    'sections': sections.map((s) => s.toJson()).toList(),
    'questionsPerRow': questionsPerRow,
    'bubbleSize': bubbleSize,
    'studentName': studentName,
    'studentNumber': studentNumber,
    'totalQuestions': totalQuestions,
    'numColumns': numColumns,
    'cornerSquares': cornerSquares.map((s) => s.toJson()).toList(),
  };

  // Calculate number of columns based on total questions
  static int calculateColumns(int totalQuestions) {
    if (totalQuestions <= 25) return 1;
    if (totalQuestions <= 50) return 2;
    if (totalQuestions <= 75) return 3;
    return 4;
  }
}
