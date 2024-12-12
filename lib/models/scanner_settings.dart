import 'package:shared_preferences/shared_preferences.dart';

class ScannerSettings {
  double bubbleSize;
  double bubbleThreshold;
  double edgeDetectionSensitivity;
  double minSheetArea;
  double maxSheetArea;
  bool autoSaveScans;
  bool enhanceContrast;
  
  ScannerSettings({
    this.bubbleSize = 25.0,
    this.bubbleThreshold = 0.5,
    this.edgeDetectionSensitivity = 50.0,
    this.minSheetArea = 0.3,
    this.maxSheetArea = 0.9,
    this.autoSaveScans = true,
    this.enhanceContrast = true,
  });

  static Future<ScannerSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ScannerSettings(
      bubbleSize: prefs.getDouble('bubbleSize') ?? 25.0,
      bubbleThreshold: prefs.getDouble('bubbleThreshold') ?? 0.5,
      edgeDetectionSensitivity: prefs.getDouble('edgeDetectionSensitivity') ?? 50.0,
      minSheetArea: prefs.getDouble('minSheetArea') ?? 0.3,
      maxSheetArea: prefs.getDouble('maxSheetArea') ?? 0.9,
      autoSaveScans: prefs.getBool('autoSaveScans') ?? true,
      enhanceContrast: prefs.getBool('enhanceContrast') ?? true,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('bubbleSize', bubbleSize);
    await prefs.setDouble('bubbleThreshold', bubbleThreshold);
    await prefs.setDouble('edgeDetectionSensitivity', edgeDetectionSensitivity);
    await prefs.setDouble('minSheetArea', minSheetArea);
    await prefs.setDouble('maxSheetArea', maxSheetArea);
    await prefs.setBool('autoSaveScans', autoSaveScans);
    await prefs.setBool('enhanceContrast', enhanceContrast);
  }
}
