# ECMA - Automated Test Scoring Application Documentation

## 🚀 Overview
ECMA is a Flutter-based automated test scoring application designed to streamline the process of grading multiple-choice examinations. The application provides comprehensive features for test creation, scanning, analysis, and result management.

## 📱 Core Features

### 1. Scanner System (`scanner_page.dart`)
**Keywords**: `CameraPreview`, `ImageProcessor`, `ScannerSettings`
- Real-time answer sheet scanning
- Edge detection and alignment
- Multiple device support
- Tent-style scanning guides
- Device-specific camera optimization

### 2. Answer Sheet Processing (`image_processor.dart`)
**Keywords**: `BubbleDetection`, `ImageAlignment`, `ScoreCalculation`
- Automated bubble detection
- Answer validation
- Score calculation
- Image preprocessing
- Error detection

### 3. Item Analysis (`analysis_page.dart`)
**Keywords**: `FrequencyAnalysis`, `ErrorTracking`, `StatisticalBreakdown`
- Question-by-question analysis
- Error frequency tracking
- Performance metrics
- Statistical reporting
- Trend analysis

### 4. Answer Key Management (`answer_key_manager.dart`)
**Keywords**: `KeyGeneration`, `MultipleAnswers`, `BonusQuestions`
- Multiple correct answers support
- Bonus question handling
- Flexible scoring options
- Answer key templates
- Custom scoring rules

### 5. User Interface Components

#### 5.1 Camera Guide (`widgets/camera_guide.dart`)
**Keywords**: `DeviceDetection`, `GuideAlignment`, `TentStyle`
```dart
Features:
- Device-specific adaptations
- Tent-style alignment guides
- Real-time guide adjustments
- Visual feedback
- Custom guide parameters
```

#### 5.2 Help Screen (`help_screen.dart`)
**Keywords**: `Instructions`, `ShadingGuide`, `TutorialTabs`
- Proper shading instructions
- Scanning guidelines
- Troubleshooting tips
- Best practices
- User guidance

## 🛠 Technical Specifications

### Dependencies
```yaml
Major Dependencies:
- camera: ^0.10.6
- cloud_firestore: ^5.5.1
- firebase_core: ^3.8.1
- firebase_storage: ^12.3.7
- firebase_auth: ^5.3.4
- device_info_plus: ^9.1.2
```

### Key Components

#### 1. Scanner Settings
**Keywords**: `BubbleSize`, `Threshold`, `EdgeDetection`
```dart
Customizable Parameters:
- Bubble size adjustment
- Detection threshold
- Edge sensitivity
- Sheet area limits
- Contrast enhancement
```

#### 2. Analysis Features
**Keywords**: `ItemAnalysis`, `ScoreBreakdown`, `PerformanceMetrics`
- Raw score calculation
- Percentage conversion
- Error frequency analysis
- Performance tracking
- Statistical reporting

## 📊 Data Management

### 1. Storage System
**Keywords**: `ImageStorage`, `ResultsDatabase`, `BackupSystem`
- Scanned image storage
- Result archiving
- Answer key database
- User data management
- Backup functionality

### 2. Authentication
**Keywords**: `UserAuth`, `TeacherAccess`, `StudentVerification`
- User authentication
- Role-based access
- Secure data handling
- Profile management
- Session control

## 🎯 Usage Guidelines

### 1. Answer Sheet Requirements
**Keywords**: `SheetFormat`, `BubbleStandards`, `PaperSize`
- Standard paper sizes (A4/Letter)
- Proper bubble marking
- Clean sheet maintenance
- Margin requirements
- Shading standards

### 2. Scanning Best Practices
**Keywords**: `ScanningTips`, `ImageQuality`, `Accuracy`
- Proper lighting conditions
- Device positioning
- Sheet alignment
- Quality checks
- Error prevention

## 🔄 Process Flow

1. **Test Creation**
   - Configure answer key
   - Set scoring rules
   - Generate answer sheets

2. **Scanning Process**
   - Align sheet using guides
   - Capture image
   - Process and validate

3. **Analysis**
   - Calculate scores
   - Generate statistics
   - Produce reports

4. **Result Management**
   - Store results
   - Generate reports
   - Archive data

## 🛡️ Security Features

### Data Protection
**Keywords**: `Encryption`, `DataPrivacy`, `SecureStorage`
- Encrypted storage
- Secure authentication
- Data backup
- Access control
- Privacy compliance

## 🔧 Maintenance

### Version Control
**Keywords**: `Updates`, `Compatibility`, `BugFixes`
- Regular updates
- Compatibility checks
- Bug tracking
- Performance monitoring
- Feature enhancement

## 📱 Device Compatibility

### Supported Devices
**Keywords**: `DeviceSupport`, `Optimization`, `Performance`
- Android devices
- iOS devices
- Tablet support
- Camera requirements
- Hardware optimization

## 🎓 Future Enhancements

### Planned Features
**Keywords**: `Roadmap`, `Enhancement`, `Development`
- AI-powered scanning
- Advanced analytics
- Batch processing
- Cloud integration
- Performance optimization

---

## 📞 Support

For technical support or feature requests, please contact the development team or raise an issue in the project repository.

---
*Last Updated: December 12, 2024*
