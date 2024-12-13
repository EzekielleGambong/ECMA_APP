import 'dart:ui';  // Add this import for Rect

class BubblePosition {
  final int x;
  final int y;
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
    x: json['x'] as int,
    y: json['y'] as int,
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

class BubbleSheetConfig {
  final String schoolName;
  final String examCode;
  final String? sectionCode;
  final DateTime examDate;
  final String examSet;
  final List<Section> sections;
  final bool includeStudentInfo;
  final bool includeBarcode;
  final String? customInstructions;
  final double? fontSize;
  final double? bubbleSize;
  final int questionsPerRow;     
  final int columnCount;         
  final double topMargin;
  final double leftMargin;
  final double bubbleSpacing;
  final double bubbleRadius;
  final int questionsPerColumn;
  final GridSquareConfig gridSquareConfig;

  BubbleSheetConfig({
    required this.schoolName,
    required this.examCode,
    this.sectionCode,
    required this.examDate,
    required this.examSet,
    required this.sections,
    this.includeStudentInfo = true,
    this.includeBarcode = true,
    this.customInstructions,
    this.fontSize = 12.0,
    this.bubbleSize = 20.0,
    this.questionsPerRow = 1,    
    this.columnCount = 4,
    this.topMargin = 50.0,
    this.leftMargin = 50.0,
    this.bubbleSpacing = 5.0,
    this.bubbleRadius = 10.0,
    this.questionsPerColumn = 25,        
    this.gridSquareConfig = const GridSquareConfig(),
  });

  int get numberOfQuestions => sections.fold(0, (sum, section) => sum + section.questions.length);

  Map<String, dynamic> toJson() => {
    'schoolName': schoolName,
    'examCode': examCode,
    'sectionCode': sectionCode,
    'examDate': examDate.toIso8601String(),
    'examSet': examSet,
    'sections': sections.map((s) => s.toJson()).toList(),
    'includeStudentInfo': includeStudentInfo,
    'includeBarcode': includeBarcode,
    'customInstructions': customInstructions,
    'fontSize': fontSize,
    'bubbleSize': bubbleSize,
    'questionsPerRow': questionsPerRow,
    'columnCount': columnCount,
    'topMargin': topMargin,
    'leftMargin': leftMargin,
    'bubbleSpacing': bubbleSpacing,
    'bubbleRadius': bubbleRadius,
    'questionsPerColumn': questionsPerColumn,
    'gridSquareConfig': gridSquareConfig.toJson(),
  };

  factory BubbleSheetConfig.fromJson(Map<String, dynamic> json) => BubbleSheetConfig(
    schoolName: json['schoolName'] as String,
    examCode: json['examCode'] as String,
    sectionCode: json['sectionCode'] as String?,
    examDate: DateTime.parse(json['examDate'] as String),
    examSet: json['examSet'] as String,
    sections: (json['sections'] as List).map((s) => Section.fromJson(s)).toList(),
    includeStudentInfo: json['includeStudentInfo'] as bool? ?? true,
    includeBarcode: json['includeBarcode'] as bool? ?? true,
    customInstructions: json['customInstructions'] as String?,
    fontSize: json['fontSize']?.toDouble(),
    bubbleSize: json['bubbleSize']?.toDouble(),
    questionsPerRow: json['questionsPerRow'] as int? ?? 1,
    columnCount: json['columnCount'] as int? ?? 4,
    topMargin: json['topMargin']?.toDouble() ?? 50.0,
    leftMargin: json['leftMargin']?.toDouble() ?? 50.0,
    bubbleSpacing: json['bubbleSpacing']?.toDouble() ?? 5.0,
    bubbleRadius: json['bubbleRadius']?.toDouble() ?? 10.0,
    questionsPerColumn: json['questionsPerColumn'] as int? ?? 25,
    gridSquareConfig: json['gridSquareConfig'] != null 
      ? GridSquareConfig.fromJson(json['gridSquareConfig'])
      : const GridSquareConfig(),
  );

  // Helper method to calculate positions
  double getQuestionY(int questionIndex) {
    return (questionIndex % questionsPerRow) * (bubbleSize ?? 20.0);
  }

  double getQuestionX(int questionIndex) {
    return (questionIndex ~/ questionsPerRow) * (bubbleSize ?? 20.0) * 6;
  }

  // Calculate grid square positions
  List<Rect> getGridSquares() {
    final squares = <Rect>[];
    final startX = (bubbleSize ?? 20.0) * 6 * questionsPerRow;
    final startY = 0.0;

    for (int i = 0; i < gridSquareConfig.numSquares; i++) {
      final x = startX + i * (gridSquareConfig.size + gridSquareConfig.spacing);
      squares.add(Rect.fromLTWH(
        x,
        startY,
        gridSquareConfig.size,
        gridSquareConfig.size,
      ));
    }

    return squares;
  }
}
