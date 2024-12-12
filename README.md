# ECMA Answer Sheet Scanner

## Description

ECMA Answer Sheet Scanner is a Flutter-based mobile application designed to scan and grade multiple-choice answer sheets. It leverages computer vision techniques to detect the answer sheet, identify marked bubbles, and calculate the raw score based on a provided answer key.

## Features

-   **Live Scanning:** The app uses the device's camera to perform live scanning of answer sheets, providing real-time feedback to the user.
-   **ROI Detection:** Implements advanced image processing techniques, including Canny edge detection and contour finding, to accurately detect the region of interest (ROI) containing the answer sheet within the camera frame.
-   **Perspective Correction:** Applies perspective transformation to align the detected answer sheet for accurate bubble detection.
-   **Bubble Detection:** Detects filled bubbles in the answer sheet using adaptive thresholding and analyzes the darkness ratio within each bubble to determine if it's marked.
-   **Customizable Number of Questions and Options:** Allows the user to specify the number of questions and options per question through input fields in the UI.
-   **Multiple Correct Answers:** Supports questions with one or more correct answers. The answer key can be configured to accept multiple marked options as correct.
-   **Raw Score Calculation:** Calculates the raw score by comparing the detected bubbles with the provided answer key, taking into account multiple correct answers.
-   **Error Handling:** Includes basic error handling to catch issues such as failure to decode the image or detect the answer sheet corners.
-   **User Interface:** Provides a user-friendly interface with a live camera preview, ROI visualization, scan results display, and input fields for customization.
-   **Save Image:** Allows the user to save the captured image of the answer sheet to the device's storage.
-   **Item Analysis:** Calculates and displays item analysis data, including the number of times each option was selected for each question.
-   **Instructions:** Provides instructions on how to properly use the app and shade the answer sheet.

## Project Structure

The project follows a standard Flutter project structure:

-   **lib/**: Contains the Dart source code for the application.
    -   **core/**: Includes core functionalities and utilities.
        -   **image_processor.dart:** Implements the image processing logic, including ROI detection, bubble detection, score calculation, and item analysis.
    -   **pages/**: Contains the UI screens of the application.
        -   **scanner_page.dart:** Implements the main scanner screen with camera preview, ROI overlay, scan results display, and user input fields.
        -   **add_student.dart:** Allows adding new students to the Firestore database.
        -   **analysisInfo.dart:** Displays detailed analysis information for a specific exam.
        -   **analysisList.dart:** Lists all available exam analyses.
        -   **analysisPage.dart:** Provides a UI for analyzing exam sheets using Google's Generative AI.
        -   **login.dart:** Handles user login using Firebase Authentication.
        -   **student_list.dart:** Displays a list of students and their associated subjects.
        -   **welcome.dart:** A welcome screen displayed after successful login.
    -   **main.dart:** The entry point of the Flutter application.

## How to Use

1. **Installation:**
    -   Clone the repository to your local machine.
    -   Ensure you have Flutter and Dart installed on your system.
    -   Run `flutter pub get` in the project directory to install dependencies.

2. **Running the App:**
    -   Connect a physical device or use an emulator/simulator.
    -   Run `flutter run` in the terminal to launch the application.

3. **Scanning an Answer Sheet:**
    -   Grant camera access to the application.
    -   Point the camera at an answer sheet. The app will attempt to detect the sheet in real time.
    -   A green border indicates successful detection of the answer sheet.
    -   The app will automatically scan the sheet and display the results.

4. **Customization:**
    -   Use the input fields at the bottom of the screen to specify the number of questions and options per question.
    -   The app will use these values for subsequent scans.

5. **Answer Key:**
    -   Currently, the answer key is hardcoded in `scanner_page.dart` as a placeholder.
    -   In a real application, you would replace this with a mechanism to input or load the answer key from a file or database.

6. **Saving Images:**
    -   Tap the "Save Image" button to save the captured image of the answer sheet to the device's storage.

7. **Viewing Item Analysis:**
    -   Tap the "Show Item Analysis" button to view the item analysis data for the scanned answer sheets.

8. **Instructions:**
    -   Tap the info icon in the app bar to view instructions on how to use the app and properly shade the answer sheet.

## Code Overview

### `image_processor.dart`

This file contains the `ImageProcessor` class, which is responsible for the core image processing and bubble detection logic.

**Key Methods:**

-   `processAnswerSheet()`: Processes an answer sheet image and returns a list of detected bubbles.
-   `applyAdaptiveThreshold()`: Applies adaptive thresholding to a grayscale image.
-   `_detectCorners()`: Detects the four corners of the answer sheet using Harris corner detection.
-   `_applyPerspectiveTransform()`: Applies perspective transformation to align the answer sheet.
-   `_detectBubbles()`: Detects filled bubbles in the aligned image.
-   `convertYUV420ToImage()`: Converts a `CameraImage` (YUV420 format) to an `img.Image`.
-   `applyCannyEdgeDetection()`: Applies Canny edge detection to an image.
-   `findContours()`: Finds contours in an edge-detected image.
-   `calculateRawScore()`: Calculates the raw score based on detected bubbles and an answer key.
-   `calculateItemAnalysis()`: Calculates item analysis data based on scanned results.

### `scanner_page.dart`

This file implements the main scanner screen, including camera handling, UI elements, and interaction with the `ImageProcessor`.

**Key Methods:**

-   `_initializeCamera()`: Initializes the camera and starts the image stream.
-   `_processCameraImage()`: Processes each camera frame, detects the answer sheet, and triggers bubble detection.
-   `_detectAnswerSheet()`: Detects the answer sheet's ROI using contour detection.
-   `_detectBubblesInROI()`: Calls the `ImageProcessor` to detect bubbles within the ROI.
-   `_handleScanResults()`: Displays the scan results and the calculated score in a dialog.
-   `_saveImage()`: Saves the captured image to the device's storage.
-   `_saveScanResults()`: Saves the scan results to Firestore.
-   `_showItemAnalysis()`: Calculates and displays the item analysis data.
-   `_showInstructions()`: Displays a dialog with instructions on how to use the app.

## Future Improvements

-   Implement a more robust mechanism for inputting the answer key (e.g., from a file or through a dedicated UI screen).
-   Add support for bonus questions (where any answer is considered correct).
-   Implement item analysis to provide statistics on question difficulty and frequency of errors.
-   Allow saving of scanned images for verification purposes.
-   Add instructions or a help screen to guide the user on how to properly use the app and shade the answer sheet.
-   Improve error handling and provide more informative feedback to the user.
-   Add more customization options (e.g., bubble size, threshold values).
-   Improve the answer sheet detection algorithm to better handle variations in lighting, angle, and paper size.
-   Add an option to generate a PDF report of the scan results and item analysis.


## Implemented Features

### 1. Advanced Scanning Features 
- **Camera Integration**
  - Real-time bubble detection with guide overlay
  - Advanced alignment guides
  - Precise corner detection
  - Multi-device camera support
  - Real-time preview with guidelines

- **Image Processing**
  - Adaptive grayscale conversion
  - Dynamic thresholding
  - Advanced perspective correction
  - Edge detection and cropping
  - Enhanced image processing

### 2. Answer Sheet Generation 
- **PDF Generation**
  - Multiple paper size support (A4, Letter, Legal, Custom)
  - Flexible question count (20-200 questions)
  - Customizable layout options
  - Adjustable bubble sizes
  - Custom margins and spacing

### 3. Comprehensive Analysis 
- **Score Calculation**
  - Raw score computation
  - Percentage scoring
  - Multiple correct answer support
  - Bonus question handling
  - Performance metrics

- **Statistical Analysis**
  - Item difficulty analysis
  - Error frequency tracking
  - Performance distribution
  - Detailed student insights
  - Score trends

### 4. User Management 
- **Authentication**
  - Firebase-based login
  - Secure user registration
  - Profile management
  - Role-based access

### 5. Export Capabilities
- **Data Export**
  - CSV export functionality
  - Excel compatibility
  - PDF report generation
  - Batch processing support

### 6. Quality Assurance
- **Validation Features**
  - Answer verification system
  - Double-checking capability
  - Error detection
  - Image quality validation

## Getting Started

### Prerequisites
1. Flutter (latest stable version)
2. Firebase account
3. Android Studio or VS Code

### Installation
1. Clone the repository
2. Run `flutter pub get`
3. Configure Firebase
4. Run the app

## Usage Guide

### Basic Scanning
1. Select 'Start Scanning' from the home screen
2. Follow the camera guide overlay
3. Align the answer sheet within the guides
4. Hold steady for automatic capture
5. Review the detected answers
6. Save or retake if needed

### Creating Answer Sheets
1. Choose 'Create Answer Sheet'
2. Configure paper size and layout
3. Set number of questions (20-200)
4. Choose options per question (up to 6)
5. Add custom instructions if needed
6. Generate and print

### Analyzing Results
1. Access the analysis section
2. View raw scores and percentages
3. Check item analysis
4. Export results as needed
5. Review performance metrics

