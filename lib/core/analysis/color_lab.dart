// lib/core/analysis/color_lab.dart
// Precision color science: sRGB <-> CIELAB (float L*, a*, b*) under D65 illuminant,
// matching scikit-image conventions (skimage.color.rgb2lab).

import 'dart:math' as math;
import 'dart:typed_data';

class LabColor {
  final double l; // L* 0 to 100
  final double a; // a* roughly -128 to +127
  final double b; // b* roughly -128 to +127

  const LabColor(this.l, this.a, this.b);

  double get chroma => math.sqrt(a * a + b * b);
  double get hueAngle => math.atan2(b, a) * (180.0 / math.pi);
}

class ColorLab {
  ColorLab._();

  // Reference White D65
  static const double _xn = 0.95047;
  static const double _yn = 1.00000;
  static const double _zn = 1.08883;

  static const double _delta = 6.0 / 29.0;
  static const double _deltaSq = _delta * _delta;
  static const double _deltaCb = _deltaSq * _delta; // 0.008856

  static double _f(double t) {
    if (t > _deltaCb) {
      return math.pow(t, 1.0 / 3.0).toDouble();
    }
    return (t / (3.0 * _deltaSq)) + (4.0 / 29.0);
  }

  static double _invF(double t) {
    if (t > _delta) {
      return t * t * t;
    }
    return 3.0 * _deltaSq * (t - 4.0 / 29.0);
  }

  static double _gammaToLinear(double c) {
    if (c <= 0.04045) {
      return c / 12.92;
    }
    return math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  static double _linearToGamma(double c) {
    if (c <= 0.0031308) {
      return 12.92 * c;
    }
    return 1.055 * math.pow(c, 1.0 / 2.4) - 0.055;
  }

  /// Converts single RGB [0..255] to LabColor.
  static LabColor rgbToLab(int r, int g, int bVal) {
    final rLin = _gammaToLinear(r / 255.0);
    final gLin = _gammaToLinear(g / 255.0);
    final bLin = _gammaToLinear(bVal / 255.0);

    final x = rLin * 0.4124564 + gLin * 0.3575761 + bLin * 0.1804375;
    final y = rLin * 0.2126729 + gLin * 0.7151522 + bLin * 0.0721750;
    final z = rLin * 0.0193339 + gLin * 0.1191920 + bLin * 0.9503041;

    final fx = _f(x / _xn);
    final fy = _f(y / _yn);
    final fz = _f(z / _zn);

    final l = 116.0 * fy - 16.0;
    final a = 500.0 * (fx - fy);
    final b = 200.0 * (fy - fz);

    return LabColor(l, a, b);
  }

  /// Converts Lab (L*, a*, b*) back to sRGB Hex string "#RRGGBB".
  static String labToHex(double l, double a, double b) {
    final fy = (l + 16.0) / 116.0;
    final fx = a / 500.0 + fy;
    final fz = fy - b / 200.0;

    final x = _xn * _invF(fx);
    final y = _yn * _invF(fy);
    final z = _zn * _invF(fz);

    final rLin = x * 3.2404542 - y * 1.5371385 - z * 0.4985314;
    final gLin = -x * 0.9692660 + y * 1.8760108 + z * 0.0415560;
    final bLin = x * 0.0556434 - y * 0.2040259 + z * 1.0572252;

    final r = (_linearToGamma(rLin) * 255.0).round().clamp(0, 255);
    final g = (_linearToGamma(gLin) * 255.0).round().clamp(0, 255);
    final bVal = (_linearToGamma(bLin) * 255.0).round().clamp(0, 255);

    final rHex = r.toRadixString(16).padLeft(2, '0').toUpperCase();
    final gHex = g.toRadixString(16).padLeft(2, '0').toUpperCase();
    final bHex = bVal.toRadixString(16).padLeft(2, '0').toUpperCase();

    return '#$rHex$gHex$bHex';
  }

  /// Calculates ITA (Individual Typology Angle) in degrees.
  /// ITA = atan((L* - 50) / b*) * (180 / pi)
  static double calculateIta(double l, double b) {
    if (b.abs() < 1e-6) return 0.0;
    return math.atan2(l - 50.0, b) * (180.0 / math.pi);
  }

  /// Batch converts RGB buffer (width x height, 3 bytes per pixel RGB) to 3 Float32Lists (L, A, B).
  static List<Float32List> rgbBufferToLabFloat(
      Uint8List rgbBytes, int width, int height) {
    final count = width * height;
    final lBuf = Float32List(count);
    final aBuf = Float32List(count);
    final bBuf = Float32List(count);

    for (int i = 0; i < count; i++) {
      final r = rgbBytes[i * 3];
      final g = rgbBytes[i * 3 + 1];
      final bVal = rgbBytes[i * 3 + 2];

      final lab = rgbToLab(r, g, bVal);
      lBuf[i] = lab.l.singlePrecision;
      aBuf[i] = lab.a.singlePrecision;
      bBuf[i] = lab.b.singlePrecision;
    }

    return [lBuf, aBuf, bBuf];
  }
}

extension SinglePrecision on double {
  double get singlePrecision => this;
}
