import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';

class ImageProcessor {
  // Constants for answer sheet layout (updated for new format)
  static const int defaultQuestionsPerPage = 100;
  static const int defaultOptionsPerQuestion = 4;
  static const double bubbleThreshold = 0.5;

  // Processes an answer sheet image and returns a list of boolean values indicating whether each bubble is filled.
  // The imagePath parameter specifies the path to the image file.
  // The numQuestions parameter specifies the number of questions on the answer sheet.
  // The optionsPerQuestion parameter specifies the number of options for each question.
  static Future<List<List<bool>>> processAnswerSheet(
    String imagePath, {
    int numQuestions = defaultQuestionsPerPage,
    int optionsPerQuestion = defaultOptionsPerQuestion,
    String paperSize = 'A4',
  }) async {
    // Read the image file
    final File imageFile = File(imagePath);
    final Uint8List bytes = await imageFile.readAsBytes();
    final img.Image? image = img.decodeImage(bytes);

    if (image == null) throw Exception('Failed to decode image');

    // Convert to grayscale
    final img.Image grayscale = img.grayscale(image);

    // Apply adaptive threshold
    final img.Image binaryImage = applyAdaptiveThreshold(grayscale);

    // Detect corners
    final List<Point> corners = _detectCorners(binaryImage);
    if (corners.length != 4) {
      throw Exception('Failed to detect answer sheet corners');
    }

    // Apply perspective transform
    final img.Image alignedImage = _applyPerspectiveTransform(binaryImage, corners);

    // Detect and analyze bubbles
    return _detectBubbles(alignedImage, numQuestions, optionsPerQuestion, paperSize);
  }

  // Processes a camera image and returns a list of boolean values indicating whether each bubble is filled.
  static Future<List<List<bool>>> processImage(CameraImage cameraImage) async {
    final img.Image? image = convertYUV420ToImage(cameraImage);
    if (image == null) throw Exception('Failed to convert camera image');

    // Convert to grayscale
    final img.Image grayscale = img.grayscale(image);

    // Apply adaptive threshold
    final img.Image binaryImage = applyAdaptiveThreshold(grayscale);

    // Detect corners
    final List<Point> corners = _detectCorners(binaryImage);
    if (corners.length != 4) {
      throw Exception('Failed to detect answer sheet corners');
    }

    // Apply perspective transform
    final img.Image alignedImage = _applyPerspectiveTransform(binaryImage, corners);

    // Detect and analyze bubbles
    return _detectBubbles(alignedImage, defaultQuestionsPerPage, defaultOptionsPerQuestion, 'A4');
  }

  // Applies adaptive thresholding to a grayscale image.
  static img.Image applyAdaptiveThreshold(img.Image grayscale) {
    final img.Image output = img.Image.from(grayscale);
    const int windowSize = 15;
    const int c = 2;

    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        int sum = 0;
        int count = 0;

        // Calculate local mean
        for (int wy = -windowSize ~/ 2; wy <= windowSize ~/ 2; wy++) {
          for (int wx = -windowSize ~/ 2; wx <= windowSize ~/ 2; wx++) {
            final int nx = x + wx;
            final int ny = y + wy;
            if (nx >= 0 && nx < grayscale.width && ny >= 0 && ny < grayscale.height) {
              sum += img.getLuminance(grayscale.getPixel(nx, ny)).toInt();
              count++;
            }
          }
        }

        final int mean = (sum / count).round();
        final int pixel = img.getLuminance(grayscale.getPixel(x, y)).toInt();
        output.setPixelRgba(
          x,
          y,
          pixel < mean - c ? 0 : 255,
          pixel < mean - c ? 0 : 255,
          pixel < mean - c ? 0 : 255,
          255,
        );
      }
    }

    return output;
  }

  static List<Point> _detectCorners(img.Image binaryImage) {
    // Implement Harris corner detection
    final List<Point> corners = [];
    final img.Image sobelX = _applySobelX(binaryImage);
    final img.Image sobelY = _applySobelY(binaryImage);

    // Calculate corner response using Harris corner detection
    final List<List<double>> cornerResponse = List.generate(
      binaryImage.height,
      (y) => List.generate(binaryImage.width, (x) {
        final double ix = img.getLuminance(sobelX.getPixel(x, y)) / 255.0;
        final double iy = img.getLuminance(sobelY.getPixel(x, y)) / 255.0;
        final double ixx = ix * ix;
        final double iyy = iy * iy;
        final double ixy = ix * iy;
        return (ixx * iyy - ixy * ixy) - 0.04 * ((ixx + iyy) * (ixx + iyy));
      }),
    );

    // Find local maxima
    const int windowSize = 10;
    for (int y = windowSize; y < binaryImage.height - windowSize; y++) {
      for (int x = windowSize; x < binaryImage.width - windowSize; x++) {
        if (cornerResponse[y][x] > 0.1) {
          bool isLocalMax = true;
          for (int dy = -windowSize; dy <= windowSize && isLocalMax; dy++) {
            for (int dx = -windowSize; dx <= windowSize && isLocalMax; dx++) {
              if (dx == 0 && dy == 0) continue;
              if (cornerResponse[y + dy][x + dx] >= cornerResponse[y][x]) {
                isLocalMax = false;
              }
            }
          }
          if (isLocalMax) {
            corners.add(Point(x, y));
          }
        }
      }
    }

    // Sort corners to get the four corners of the answer sheet
    corners.sort((a, b) {
      if ((a.y - b.y).abs() < 50) {
        return a.x.compareTo(b.x);
      }
      return a.y.compareTo(b.y);
    });

    // Return the four corners in clockwise order
    return corners.take(4).toList();
  }

  static img.Image _applySobelX(img.Image input) {
    final img.Image output = img.Image.from(input);
    const List<List<int>> kernel = [
      [-1, 0, 1],
      [-2, 0, 2],
      [-1, 0, 1]
    ];

    _applyKernel(input, output, kernel);
    return output;
  }

  static img.Image _applySobelY(img.Image input) {
    final img.Image output = img.Image.from(input);
    const List<List<int>> kernel = [
      [-1, -2, -1],
      [0, 0, 0],
      [1, 2, 1]
    ];

    _applyKernel(input, output, kernel);
    return output;
  }

  static void _applyKernel(img.Image input, img.Image output, List<List<int>> kernel) {
    for (int y = 1; y < input.height - 1; y++) {
      for (int x = 1; x < input.width - 1; x++) {
        int sum = 0;

        for (int ky = 0; ky < 3; ky++) {
          for (int kx = 0; kx < 3; kx++) {
            final int pixel = img.getLuminance(input.getPixel(x + kx - 1, y + ky - 1)).toInt();
            sum += pixel * kernel[ky][kx];
          }
        }

        sum = sum.abs();
        if (sum > 255) sum = 255;
        output.setPixelRgba(x, y, sum, sum, sum, 255);
      }
    }
  }

  static img.Image _applyPerspectiveTransform(img.Image input, List<Point> corners) {
    // Define the output image size
    const int outputWidth = 800;
    const int outputHeight = 1100;
    final Uint8List bytes = Uint8List(outputWidth * outputHeight * 4);
    final ByteBuffer buffer = bytes.buffer;
    final img.Image output = img.Image.fromBytes(
      width: outputWidth,
      height: outputHeight,
      bytes: buffer,
      numChannels: 4,
    );
    // Fill with white
    for (int y = 0; y < output.height; y++) {
      for (int x = 0; x < output.width; x++) {
        output.setPixelRgba(x, y, 255, 255, 255, 255);
      }
    }

    // Define the target corners (rectangle)
    final List<Point> targetCorners = [
      Point(0, 0),
      Point(outputWidth - 1, 0),
      Point(outputWidth - 1, outputHeight - 1),
      Point(0, outputHeight - 1),
    ];

    // Calculate perspective transform matrix
    final Matrix3 matrix = _getPerspectiveTransform(corners, targetCorners);

    // Apply transform
    for (int y = 0; y < outputHeight; y++) {
      for (int x = 0; x < outputWidth; x++) {
        final Point source = _transformPoint(x.toDouble(), y.toDouble(), matrix);
        if (source.x >= 0 && source.x < input.width && source.y >= 0 && source.y < input.height) {
          output.setPixel(x, y, input.getPixel(source.x, source.y));
        }
      }
    }

    return output;
  }

  // Detects filled bubbles in an aligned image.
  // numQuestions: The number of questions to process.
  // optionsPerQuestion: The number of options per question.
  static List<List<bool>> _detectBubbles(img.Image alignedImage, int numQuestions, int optionsPerQuestion, String paperSize) {
    final List<List<bool>> results = List.generate(numQuestions, (_) => List.filled(optionsPerQuestion, false));
    const int bubbleSize = 25; // Increased bubble size

    // Default values for A4
    int startX = 65; 
    int startY = 295; 
    int questionSpacing = 40; 
    int optionSpacing = 30; 

    // Adjust parameters based on paper size
    if (paperSize == 'Letter') {
      startX = 55;
      startY = 285;
      questionSpacing = 38;
      optionSpacing = 28;
    }

    for (int q = 0; q < numQuestions; q++) {
      final int questionY = startY + q * questionSpacing;

      // Check each option (A, B, C, D)
      for (int opt = 0; opt < optionsPerQuestion; opt++) {
        final int optionX = startX + opt * optionSpacing;
        int darkPixels = 0;

        // Count dark pixels in bubble area
        for (int dy = -bubbleSize ~/ 2; dy < bubbleSize ~/ 2; dy++) {
          for (int dx = -bubbleSize ~/ 2; dx < bubbleSize ~/ 2; dx++) {
            final int x = optionX + dx;
            final int y = questionY + dy;

            if (x >= 0 && x < alignedImage.width && y >= 0 && y < alignedImage.height) {
              final int pixel = img.getLuminance(alignedImage.getPixel(x, y)).toInt();
              if (pixel < 128) {
                darkPixels++;
              }
            }
          }
        }

        // Mark as true if a bubble meets the threshold
        final double fillRatio = darkPixels / (bubbleSize * bubbleSize);
        results[q][opt] = fillRatio > bubbleThreshold;
      }
    }

    return results;
  }

  static Matrix3 _getPerspectiveTransform(List<Point> from, List<Point> to) {
    if (from.length != 4 || to.length != 4) {
      throw Exception('Both point lists must contain exactly 4 points');
    }

    // Create matrix for linear equation system
    final List<List<double>> matrix = List.generate(8, (_) => List.filled(9, 0.0));

    for (int i = 0; i < 4; i++) {
      final double x = from[i].x.toDouble();
      final double y = from[i].y.toDouble();
      final double X = to[i].x.toDouble();
      final double Y = to[i].y.toDouble();

      matrix[i * 2] = [x, y, 1, 0, 0, 0, -X * x, -X * y, -X];
      matrix[i * 2 + 1] = [0, 0, 0, x, y, 1, -Y * x, -Y * y, -Y];
    }

    // Solve the equation using Gaussian elimination
    final List<double> result = _solveLinearSystem(matrix);

    return Matrix3(
      result[0], result[1], result[2],
      result[3], result[4], result[5],
      result[6], result[7], result[8],
    );
  }

  static List<double> _solveLinearSystem(List<List<double>> matrix) {
    final int n = matrix.length;

    // Gaussian elimination
    for (int i = 0; i < n; i++) {
      double maxEl = matrix[i][i].abs();
      int maxRow = i;

      for (int k = i + 1; k < n; k++) {
        if (matrix[k][i].abs() > maxEl) {
          maxEl = matrix[k][i].abs();
          maxRow = k;
        }
      }

      if (maxEl == 0) {
        throw Exception('Matrix is singular');
      }

      if (maxRow != i) {
        final temp = matrix[i];
        matrix[i] = matrix[maxRow];
        matrix[maxRow] = temp;
      }

      for (int k = i + 1; k < n; k++) {
        final double c = -matrix[k][i] / matrix[i][i];
        for (int j = i; j <= n; j++) {
          if (i == j) {
            matrix[k][j] = 0;
          } else {
            matrix[k][j] += c * matrix[i][j];
          }
        }
      }
    }

    // Back substitution
    final List<double> result = List.filled(n, 0);
    for (int i = n - 1; i >= 0; i--) {
      double sum = 0.0;
      for (int j = i + 1; j < n; j++) {
        sum += matrix[i][j] * result[j];
      }
      result[i] = (matrix[i][n] - sum) / matrix[i][i];
    }

    return result;
  }

  static Point _transformPoint(double x, double y, Matrix3 matrix) {
    final double w = matrix.m20 * x + matrix.m21 * y + matrix.m22;
    final double px = (matrix.m00 * x + matrix.m01 * y + matrix.m02) / w;
    final double py = (matrix.m10 * x + matrix.m11 * y + matrix.m12) / w;
    return Point(px.round(), py.round());
  }

  static img.Image? convertYUV420ToImage(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;

    final img.Image image = img.Image(width: width, height: height);

    final planes = cameraImage.planes;

    const int yPlane = 0;
    const int uvPlane = 1;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex = uvPlane * ((y ~/ 2) * width) + (x ~/ 2) * 2;
        final int index = y * width + x;

        final yp = planes[yPlane].bytes[index];
        final up = planes[uvPlane].bytes[uvIndex];
        final vp = planes[uvPlane].bytes[uvIndex + 1];

        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round().clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }

    return image;
  }

  static List<List<bool>> detectBubbles(img.Image image, int numQuestions, int numOptions) {
    return _detectBubbles(image, numQuestions, numOptions, 'A4');
  }

  // Applies Canny edge detection to an image.
  static img.Image applyCannyEdgeDetection(img.Image image, {double threshold1 = 50, double threshold2 = 150}) {
    // Apply Gaussian blur to reduce noise
    final img.Image blurredImage = img.gaussianBlur(image, radius: 2);

    // Calculate image gradients using Sobel operators
    final img.Image sobelX = _applySobelX(blurredImage);
    final img.Image sobelY = _applySobelY(blurredImage);

    // Calculate gradient magnitude and direction
    final img.Image gradientMagnitude = img.Image.from(image);
    final List<List<double>> gradientDirection = List.generate(
      image.height,
      (y) => List.generate(image.width, (x) => 0.0),
    );

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final int ix = img.getLuminance(sobelX.getPixel(x, y)).toInt();
        final int iy = img.getLuminance(sobelY.getPixel(x, y)).toInt();
        final int magnitude = math.sqrt(ix * ix + iy * iy).round();
        gradientMagnitude.setPixelRgba(x, y, magnitude, magnitude, magnitude, 255);

        // Calculate gradient direction in radians
        gradientDirection[y][x] = math.atan2(iy, ix);
      }
    }

    // Non-maximum suppression
    final img.Image nonMaxSuppressed = img.Image.from(gradientMagnitude);
    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        final double angle = gradientDirection[y][x];
        final int magnitude = img.getLuminance(gradientMagnitude.getPixel(x, y)).toInt();

        // Convert angle to degrees and normalize to 0-180 range
        double angleDegrees = angle * 180 / math.pi;
        if (angleDegrees < 0) angleDegrees += 180;

        // Determine the neighboring pixels to compare based on the gradient direction
        int q = 255;
        int r = 255;

        if ((0 <= angleDegrees && angleDegrees < 22.5) || (157.5 <= angleDegrees && angleDegrees <= 180)) {
          q = img.getLuminance(gradientMagnitude.getPixel(x + 1, y)).toInt();
          r = img.getLuminance(gradientMagnitude.getPixel(x - 1, y)).toInt();
        } else if (22.5 <= angleDegrees && angleDegrees < 67.5) {
          q = img.getLuminance(gradientMagnitude.getPixel(x + 1, y - 1)).toInt();
          r = img.getLuminance(gradientMagnitude.getPixel(x - 1, y + 1)).toInt();
        } else if (67.5 <= angleDegrees && angleDegrees < 112.5) {
          q = img.getLuminance(gradientMagnitude.getPixel(x, y + 1)).toInt();
          r = img.getLuminance(gradientMagnitude.getPixel(x, y - 1)).toInt();
        } else if (112.5 <= angleDegrees && angleDegrees < 157.5) {
          q = img.getLuminance(gradientMagnitude.getPixel(x - 1, y - 1)).toInt();
          r = img.getLuminance(gradientMagnitude.getPixel(x + 1, y + 1)).toInt();
        }

        // Suppress non-maximum pixels
        if (magnitude >= q && magnitude >= r) {
          nonMaxSuppressed.setPixelRgba(x, y, magnitude, magnitude, magnitude, 255);
        } else {
          nonMaxSuppressed.setPixelRgba(x, y, 0, 0, 0, 255);
        }
      }
    }

    // Hysteresis thresholding
    final img.Image result = img.Image.from(nonMaxSuppressed);
    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        final int magnitude = img.getLuminance(nonMaxSuppressed.getPixel(x, y)).toInt();

        if (magnitude >= threshold2) {
          result.setPixelRgba(x, y, 255, 255, 255, 255);
        } else if (magnitude >= threshold1) {
          // Check if any of the 8 neighboring pixels are strong edges
          bool isStrongNeighbor = false;
          for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
              if (dy == 0 && dx == 0) continue;
              final int neighborMagnitude = img.getLuminance(nonMaxSuppressed.getPixel(x + dx, y + dy)).toInt();
              if (neighborMagnitude >= threshold2) {
                isStrongNeighbor = true;
                break;
              }
            }
            if (isStrongNeighbor) break;
          }

          if (isStrongNeighbor) {
            result.setPixelRgba(x, y, 255, 255, 255, 255);
          } else {
            result.setPixelRgba(x, y, 0, 0, 0, 255);
          }
        } else {
          result.setPixelRgba(x, y, 0, 0, 0, 255);
        }
      }
    }

    return result;
  }

  // Finds contours in an edge-detected image.
  static List<Point> findContours(img.Image edgeImage) {
    final List<Point> contours = [];

    // Create a copy of the image to mark visited pixels
    final img.Image visited = img.Image.from(edgeImage);

    // Iterate through the image to find starting points for contours
    for (int y = 0; y < edgeImage.height; y++) {
      for (int x = 0; x < edgeImage.width; x++) {
        // Check if the pixel is an edge and hasn't been visited yet
        if (img.getLuminance(edgeImage.getPixel(x, y)) > 0 && img.getLuminance(visited.getPixel(x, y)) == 0) {
          final List<Point> contour = [];
          _followContour(edgeImage, visited, x, y, contour);
          if (contour.length > 50) { // Filter out small contours
            contours.addAll(contour);
          }
        }
      }
    }

    return contours;
  }

  static void _followContour(img.Image edgeImage, img.Image visited, int x, int y, List<Point> contour) {
    // Mark the current pixel as visited
    visited.setPixelRgba(x, y, 255, 255, 255, 255);

    // Add the current point to the contour
    contour.add(Point(x, y));

    // Define the 8-connected neighborhood
    final List<int> dx = [-1, 0, 1, -1, 1, -1, 0, 1];
    final List<int> dy = [-1, -1, -1, 0, 0, 1, 1, 1];

    // Explore the neighbors
    for (int i = 0; i < 8; i++) {
      final int nx = x + dx[i];
      final int ny = y + dy[i];

      // Check if the neighbor is within bounds, is an edge, and hasn't been visited
      if (nx >= 0 && nx < edgeImage.width && ny >= 0 && ny < edgeImage.height &&
          img.getLuminance(edgeImage.getPixel(nx, ny)) > 0 && img.getLuminance(visited.getPixel(nx, ny)) == 0) {
        _followContour(edgeImage, visited, nx, ny, contour);
        return; // Backtrack after finding the next point in the contour
      }
    }
  }

  // Calculates the raw score based on the detected bubbles and the answer key.
  static int calculateRawScore(List<List<bool>> detectedBubbles, List<List<bool>> answerKey) {
    int score = 0;
    for (int i = 0; i < detectedBubbles.length; i++) {
      if (i < answerKey.length) {
        bool correct = true;
        for (int j = 0; j < detectedBubbles[i].length; j++) {
          if (j < answerKey[i].length) {
            if (detectedBubbles[i][j] != answerKey[i][j]) {
              correct = false;
              break;
            }
          }
        }
        if (correct) {
          score++;
        }
      }
    }
    return score;
  }

  // Performs item analysis on the scanned results.
  static Map<String, dynamic> calculateItemAnalysis(List<List<List<bool>>> allResults, int numQuestions, int numOptions) {
    final Map<String, dynamic> analysis = {};

    // Initialize the analysis data structure
    for (int i = 0; i < numQuestions; i++) {
      analysis['Question ${i + 1}'] = List.generate(numOptions, (index) => 0);
    }

    // Count the number of times each option was selected for each question
    for (final results in allResults) {
      for (int i = 0; i < results.length; i++) {
        for (int j = 0; j < results[i].length; j++) {
          if (results[i][j]) {
            analysis['Question ${i + 1}'][j]++;
          }
        }
      }
    }

    return analysis;
  }
}

class Point {
  final int x;
  final int y;

  Point(this.x, this.y);
}

class Matrix3 {
  final double m00, m01, m02;
  final double m10, m11, m12;
  final double m20, m21, m22;

  Matrix3(
    this.m00, this.m01, this.m02,
    this.m10, this.m11, this.m12,
    this.m20, this.m21, this.m22,
  );
}
