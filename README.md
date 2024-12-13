# ECMA (Exam Correction & Management Assistant)

## Overview
ECMA is a sophisticated Flutter-based application designed for automated exam correction and management. It utilizes advanced computer vision and machine learning algorithms to process bubble sheet answers, providing real-time scoring and comprehensive analysis.

## Features

### 1. Authentication System
- Secure login/signup using Firebase Authentication
- Offline authentication support
- User profile management
- Role-based access control

### 2. Bubble Sheet Processing
- Real-time scanning using device camera
- File upload support for batch processing
- Advanced image preprocessing
- Accurate bubble detection algorithm
- Support for multiple answer sheet formats

### 3. Answer Key Management
- Create/Edit answer keys
- Multiple subject support
- Version control for answer keys
- Import/Export functionality

### 4. Analysis Tools
- Item analysis
- Student performance tracking
- Subject-wise analysis
- Trend analysis
- Statistical reports

### 5. Offline Support
- Local data caching
- Synchronization when online
- Offline scanning capability
- Data persistence

## Technical Architecture

### System Components
```mermaid
graph TB
    A[Frontend - Flutter UI] --> B[Business Logic]
    B --> C[Local Storage]
    B --> D[Cloud Services]
    
    subgraph "Frontend Components"
        A1[UI Components] --> A2[State Management]
        A2 --> A3[Route Management]
    end
    
    subgraph "Business Logic"
        B1[Authentication] --> B2[Image Processing]
        B2 --> B3[Answer Processing]
        B3 --> B4[Analysis Engine]
    end
    
    subgraph "Storage"
        C1[SQLite] --> C2[Shared Preferences]
        D1[Firebase] --> D2[Cloud Storage]
    end
```

### Authentication Flow
```mermaid
sequenceDiagram
    participant U as User
    participant A as App
    participant F as Firebase
    participant L as Local Storage
    
    U->>A: Open App
    A->>L: Check Local Auth
    alt Is Authenticated Locally
        L->>A: Return Cached Session
        A->>U: Show Home Screen
    else Not Authenticated
        A->>U: Show Login Screen
        U->>A: Enter Credentials
        A->>F: Verify Credentials
        F->>A: Auth Response
        A->>L: Cache Auth Data
        A->>U: Show Home Screen
    end
```

### Scanning Algorithm
```mermaid
graph LR
    A[Image Input] --> B[Preprocessing]
    B --> C[Bubble Detection]
    C --> D[Answer Extraction]
    D --> E[Score Calculation]
    
    subgraph "Preprocessing"
        B1[Grayscale] --> B2[Thresholding]
        B2 --> B3[Noise Reduction]
        B3 --> B4[Edge Detection]
    end
    
    subgraph "Bubble Detection"
        C1[Grid Detection] --> C2[Circle Detection]
        C2 --> C3[Bubble Analysis]
    end
```

## Machine Learning Components

### 1. Image Processing Pipeline
- **Preprocessing**:
  - Grayscale conversion
  - Adaptive thresholding
  - Gaussian blur for noise reduction
  - Perspective correction
  
- **Feature Detection**:
  - Hough Circle Transform for bubble detection
  - Contour detection for grid alignment
  - Corner detection for sheet orientation

### 2. Answer Detection Algorithm
```python
# Pseudocode for bubble detection
def process_bubble_sheet(image):
    preprocessed = preprocess_image(image)
    grid = detect_grid(preprocessed)
    bubbles = detect_bubbles(grid)
    
    for bubble in bubbles:
        filled_percentage = calculate_fill(bubble)
        if filled_percentage > THRESHOLD:
            mark_as_selected(bubble)
    
    return extract_answers(bubbles)
```

## Data Flow

### 1. Scanning Process
```mermaid
flowchart TD
    A[Start Scan] --> B{Camera/File?}
    B -->|Camera| C[Initialize Camera]
    B -->|File| D[File Upload]
    C --> E[Process Image]
    D --> E
    E --> F[Extract Answers]
    F --> G[Compare with Key]
    G --> H[Generate Results]
    H --> I[Save Results]
    I --> J[Display Score]
```

### 2. Analysis Process
```mermaid
flowchart TD
    A[Raw Data] --> B[Data Processing]
    B --> C[Statistical Analysis]
    C --> D[Generate Reports]
    
    subgraph "Analysis Types"
        E[Item Analysis]
        F[Student Performance]
        G[Subject Analysis]
        H[Trend Analysis]
    end
    
    D --> E
    D --> F
    D --> G
    D --> H
```

## Performance Optimizations

### 1. Image Processing
- Chunked processing for large images
- Multi-threaded bubble detection
- Optimized memory usage
- Cache management

### 2. Data Management
- Efficient local storage
- Batch synchronization
- Compressed data storage
- Intelligent caching

## Security Features

### 1. Data Protection
- End-to-end encryption
- Secure local storage
- Protected PDF generation
- Access control

### 2. Authentication
- Biometric authentication option
- Token-based authentication
- Session management
- Secure credential storage

## Future Enhancements

### Planned Features
1. AI-powered answer validation
2. Advanced statistical analysis
3. Custom bubble sheet designer
4. Batch processing improvements
5. Enhanced offline capabilities

## Getting Started

### Prerequisites
- Flutter SDK
- Firebase account
- Android Studio/VS Code
- Camera-enabled device
