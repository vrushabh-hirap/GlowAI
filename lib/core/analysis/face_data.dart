// lib/core/analysis/face_data.dart
// Plain, isolate-transferable data models for ML Kit face detection landmarks and pose.

class Point2D {
  final double x;
  final double y;

  const Point2D(this.x, this.y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
  factory Point2D.fromJson(Map<String, dynamic> json) =>
      Point2D((json['x'] as num).toDouble(), (json['y'] as num).toDouble());
}

class Rect2D {
  final double left;
  final double top;
  final double width;
  final double height;

  const Rect2D({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  double get right => left + width;
  double get bottom => top + height;

  Map<String, dynamic> toJson() => {
        'left': left,
        'top': top,
        'width': width,
        'height': height,
      };

  factory Rect2D.fromJson(Map<String, dynamic> json) => Rect2D(
        left: (json['left'] as num).toDouble(),
        top: (json['top'] as num).toDouble(),
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
      );
}

class FaceData {
  final Rect2D boundingBox;
  final double yaw;   // Euler Y
  final double pitch; // Euler X
  final double roll;  // Euler Z
  final List<Point2D> faceOval;
  final List<Point2D> leftEyebrowTop;
  final List<Point2D> rightEyebrowTop;
  final List<Point2D> leftEye;
  final List<Point2D> rightEye;
  final List<Point2D> upperLipTop;
  final List<Point2D> lowerLipBottom;
  final List<Point2D> noseBridge;
  final List<Point2D> noseBottom;
  final Point2D? leftCheek;
  final Point2D? rightCheek;

  const FaceData({
    required this.boundingBox,
    required this.yaw,
    required this.pitch,
    required this.roll,
    required this.faceOval,
    required this.leftEyebrowTop,
    required this.rightEyebrowTop,
    required this.leftEye,
    required this.rightEye,
    required this.upperLipTop,
    required this.lowerLipBottom,
    required this.noseBridge,
    required this.noseBottom,
    this.leftCheek,
    this.rightCheek,
  });
}
