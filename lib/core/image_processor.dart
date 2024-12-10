import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

class ImageProcessor {
  // Constants for answer sheet layout
  static const int QUESTIONS_PER_PAGE = 50;
  static const int OPTIONS_PER_QUESTION = 6;
  static const double BUBBLE_THRESHOLD = 0.5;

  static Future<List<bool>> processAnswerSheet(String imagePath) async {
    // Read the image file
    final File imageFile = File(imagePath);
    final Uint8List bytes = await imageFile.readAsBytes();
    final img.Image? image = img.decodeImage(bytes);

    if (image == null) throw Exception('Failed to decode image');

    // Convert to grayscale
    final img.Image grayscale = img.grayscale(image);

    // Apply adaptive threshold
    final img.Image binaryImage = _applyAdaptiveThreshold(grayscale);

    // Detect corners
    final List<Point> corners = _detectCorners(binaryImage);
    if (corners.length != 4) {
      throw Exception('Failed to detect answer sheet corners');
    }

    // Apply perspective transform
    final img.Image alignedImage = _applyPerspectiveTransform(binaryImage, corners);

    // Detect and analyze bubbles
    return _detectBubbles(alignedImage);
  }

  static img.Image _applyAdaptiveThreshold(img.Image grayscale) {
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
        output.setPixelRgba(x, y, 
          pixel < mean - c ? 0 : 255,
          pixel < mean - c ? 0 : 255,
          pixel < mean - c ? 0 : 255,
          255
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

  void processImage(img.Image output) {
    // Fill the image with white color
    for (int y = 0; y < output.height; y++) {
      for (int x = 0; x < output.width; x++) {
        output.setPixelRgba(x, y, 255, 255, 255, 255);
      }
    }
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

  static List<bool> _detectBubbles(img.Image alignedImage) {
    final List<bool> results = List.filled(QUESTIONS_PER_PAGE, false);
    const int bubbleSize = 20;
    
    // Define the grid layout for bubbles
    const int startX = 100;
    const int startY = 150;
    const int questionSpacing = 40;
    const int optionSpacing = 30;

    for (int q = 0; q < QUESTIONS_PER_PAGE; q++) {
      int maxDarkPixels = 0;
      int selectedOption = -1;

      final int questionY = startY + q * questionSpacing;

      // Check each option (A, B, C, D, E, F)
      for (int opt = 0; opt < OPTIONS_PER_QUESTION; opt++) {
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

        // Update if this is the darkest bubble for this question
        if (darkPixels > maxDarkPixels) {
          maxDarkPixels = darkPixels;
          selectedOption = opt;
        }
      }

      // Mark as true if a bubble was selected and meets the threshold
      final double fillRatio = maxDarkPixels / (bubbleSize * bubbleSize);
      results[q] = selectedOption >= 0 && fillRatio > BUBBLE_THRESHOLD;
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