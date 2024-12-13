# ECMA_APP Documentation

## Overview
ECMA_APP is a Flutter application designed for automated bubble sheet scanning and processing. It provides functionality for creating, scanning, and analyzing bubble sheet answer forms commonly used in educational settings.

## Core Features
- Bubble sheet generation with customizable layouts
- Real-time camera-based sheet detection and scanning
- Answer key management and scoring
- Statistical analysis of results
- PDF export capabilities

## Project Structure

### Models

#### BubbleSheetConfig
A configuration class for defining bubble sheet properties:
- `schoolName`: Name of the school
- `examCode`: Unique identifier for the exam
- `sectionCode`: Optional section identifier
- `examDate`: Date of the exam
- `examSet`: Exam set identifier
- `numberOfQuestions`: Total number of questions
- `optionsPerQuestion`: Number of answer choices per question
- `questionsPerRow`: Number of questions displayed in each row
- `bubbleSize`: Size of answer bubbles
- `gridSquareConfig`: Configuration for alignment grid squares

#### GridSquareConfig
Configuration for alignment markers:
- `size`: Size of each grid square
- `spacing`: Space between grid squares
- `numSquares`: Number of squares to draw
- `cornerRadius`: Radius for rounded corners
- `strokeWidth`: Width of grid lines

### Pages

#### ScannerPage
Main scanning interface:
- Real-time camera preview
- Sheet detection and alignment
- Answer bubble recognition
- Score calculation
- Results display

#### BubbleSheetGenerator
PDF generation interface:
- School and exam information input
- Layout customization
- PDF preview
- Export functionality

#### AnalysisPage
Results analysis interface:
- Score statistics
- Item analysis
- Performance metrics
- Data visualization

### Widgets

#### CameraGuide
Camera overlay widget for scanning guidance:
- Alignment markers
- Device-specific adjustments
- Visual feedback for sheet detection
- Dynamic scaling based on device characteristics

### Services

#### AnalyticsService
Service for processing and analyzing scan results:
- Score calculation
- Statistical analysis
- Data persistence
- Export capabilities

## Technical Details

### Dependencies
- `camera`: For device camera access and image capture
- `pdf`: For generating PDF documents
- `image`: For image processing
- `firebase_core`: Firebase integration
- `cloud_firestore`: Cloud database
- `firebase_storage`: File storage

### Key Algorithms
1. Sheet Detection:
   - Contour detection
   - Perspective transformation
   - Grid square alignment

2. Bubble Recognition:
   - Threshold-based detection
   - Bubble center identification
   - Answer selection validation

3. Score Calculation:
   - Answer key matching
   - Bonus question handling
   - Statistical computations

## Usage Instructions

### Generating Bubble Sheets
1. Enter school and exam information
2. Configure sheet layout
3. Preview and adjust settings
4. Generate and export PDF

### Scanning Answers
1. Position sheet within camera guide
2. Maintain proper lighting
3. Wait for automatic detection
4. Verify scan results

### Analyzing Results
1. View individual scores
2. Access statistical summaries
3. Export analysis reports
4. Track performance trends

## Performance Considerations
- Camera resolution requirements
- Processing speed optimizations
- Memory management for large datasets
- PDF generation efficiency

## Security Features
- Firebase authentication
- Data encryption
- Access control
- Secure file storage

## Future Enhancements
- Multiple answer key support
- Enhanced statistical analysis
- Batch processing capabilities
- Custom scoring algorithms
- Integration with learning management systems

## Known Limitations
- Lighting sensitivity
- Device compatibility requirements
- Processing speed on older devices
- Maximum sheet size constraints

## Best Practices
- Regular calibration checks
- Proper lighting conditions
- Clean and undamaged sheets
- Regular data backups
- Performance monitoring

## Support and Maintenance
- Regular updates for compatibility
- Bug fixing procedures
- Performance optimization
- User feedback integration
