// lib/features/scan/scan_camera_screen.dart
// A3: Real camera screen with ML Kit face detection and live guidance.
// Front camera, throttled analysis (every 3rd frame), ValueNotifier for chips.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_colors.dart';

class ScanCameraScreen extends StatefulWidget {
  final bool prepared;
  final int? minutesSinceWash;

  const ScanCameraScreen({
    super.key,
    this.prepared = true,
    this.minutesSinceWash,
  });

  @override
  State<ScanCameraScreen> createState() => _ScanCameraScreenState();
}

class _ScanCameraScreenState extends State<ScanCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _permissionDenied = false;
  bool _permissionPermanentlyDenied = false;
  bool _cameraReady = false;

  // ML Kit face detector
  late final FaceDetector _faceDetector;

  // Frame throttle
  bool _processingFrame = false;
  int _frameCount = 0;

  // Countdown
  bool _countingDown = false;
  int _countdownValue = 3;
  Timer? _countdownTimer;
  bool _capturing = false;

  // Captured photo for review
  String? _capturedPath;

  // Current lens (front by default)
  CameraLensDirection _lensDirection = CameraLensDirection.front;

  // Debounce for false-positive "multiple faces" from ML Kit
  int _multiFaceStreak = 0;

  // Guidance state (all via ValueNotifier to avoid full rebuilds)
  final _faceDetectedNotifier = ValueNotifier<bool>(false);
  final _centeredNotifier = ValueNotifier<bool>(false);
  final _distanceOkNotifier = ValueNotifier<bool>(false);
  final _straightNotifier = ValueNotifier<bool>(false);
  final _lightingOkNotifier = ValueNotifier<bool>(false);
  final _holdStillNotifier = ValueNotifier<bool>(false);
  final _hintNotifier = ValueNotifier<String>('Center your face in the oval');
  final _allOkNotifier = ValueNotifier<bool>(false);

  // Hold-still tracking
  Rect? _lastFaceBox;
  int _stableFrameCount = 0;
  static const _stableThreshold = 10; // ~3-4 frames at throttle rate

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableClassification: false,
        enableLandmarks: false,
        enableContours: false,
      ),
    );
    _requestAndInit();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _stopStream();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _requestAndInit() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      if (mounted) setState(() => _permissionPermanentlyDenied = true);
      return;
    }
    if (status.isDenied || status.isRestricted) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }
    await _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras ??= await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) return;

    // Use the currently selected lens, fallback to front
    CameraDescription? preferred;
    for (final c in _cameras!) {
      if (c.lensDirection == _lensDirection) {
        preferred = c;
        break;
      }
    }
    preferred ??= _cameras!.first;
    final cam = preferred;

    await _controller?.dispose();
    _controller = CameraController(
      cam,
      ResolutionPreset.high,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      await _controller!.setFlashMode(FlashMode.off);
      if (mounted) setState(() => _cameraReady = true);
      await _controller!.startImageStream(_onFrame);
    } catch (e) {
      if (mounted) setState(() => _permissionDenied = true);
    }
  }

  void _stopStream() {
    try {
      _controller?.stopImageStream();
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    _stopStream();
    _lensDirection = _lensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    if (mounted) setState(() => _cameraReady = false);
    await _controller?.dispose();
    _controller = null;
    await _initCamera();
  }

  // ── Frame processing ─────────────────────────────────────────────────────

  void _onFrame(CameraImage image) {
    _frameCount++;
    // Throttle: process every 3rd frame
    if (_frameCount % 3 != 0) return;
    if (_processingFrame || _capturing) return;
    _processingFrame = true;

    _analyzeFrame(image).whenComplete(() => _processingFrame = false);
  }

  Future<void> _analyzeFrame(CameraImage image) async {
    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) return;

      final faces = await _faceDetector.processImage(inputImage);

      if (!mounted) return;

      if (faces.isEmpty) {
        _updateGuidance(
          faceDetected: false,
          centered: false,
          distanceOk: false,
          straight: false,
          lightingOk: _estimateLighting(image),
          holdStill: false,
          hint: 'No face detected — look at the camera',
        );
        _stableFrameCount = 0;
        return;
      }

      final previewH0 = _controller!.value.previewSize!.width; // rotated
      // Ignore tiny false-positive detections (posters, photos, TVs in background)
      final realFaces = faces
          .where((f) => f.boundingBox.height / previewH0 >= 0.12)
          .toList();

      if (realFaces.length > 1) {
        _multiFaceStreak++;
        if (_multiFaceStreak >= 2) {
          _updateGuidance(
            faceDetected: false,
            centered: false,
            distanceOk: false,
            straight: false,
            lightingOk: _estimateLighting(image),
            holdStill: false,
            hint: 'Multiple faces detected — only one person please',
          );
        }
        _stableFrameCount = 0;
        return;
      }
      _multiFaceStreak = 0;

      if (realFaces.isEmpty) {
        _updateGuidance(
          faceDetected: false,
          centered: false,
          distanceOk: false,
          straight: false,
          lightingOk: _estimateLighting(image),
          holdStill: false,
          hint: 'No face detected — look at the camera',
        );
        _stableFrameCount = 0;
        return;
      }

      final face = realFaces.first;
      final box = face.boundingBox;
      final previewH = _controller!.value.previewSize!.width; // rotated
      final previewW = _controller!.value.previewSize!.height;

      // Distance check: face height should be 45%–75% of preview height
      final faceHeightRatio = box.height / previewH;
      final distanceOk = faceHeightRatio >= 0.40 && faceHeightRatio <= 0.80;

      // Center check: face center within 20% of image center
      final faceCenterX = box.left + box.width / 2;
      final faceCenterY = box.top + box.height / 2;
      final dx = (faceCenterX - previewW / 2).abs() / previewW;
      final dy = (faceCenterY - previewH / 2).abs() / previewH;
      final centered = dx < 0.20 && dy < 0.20;

      // Pose check: angles within ±12°
      final yaw = face.headEulerAngleY ?? 0;
      final pitch = face.headEulerAngleX ?? 0;
      final roll = face.headEulerAngleZ ?? 0;
      final straight = yaw.abs() < 12 && pitch.abs() < 12 && roll.abs() < 12;

      // Lighting check
      final lightingOk = _estimateLighting(image);

      // Hold still check
      bool holdStill = false;
      if (_lastFaceBox != null) {
        final dx2 = (box.left - _lastFaceBox!.left).abs();
        final dy2 = (box.top - _lastFaceBox!.top).abs();
        if (dx2 < 15 && dy2 < 15) {
          _stableFrameCount++;
          holdStill = _stableFrameCount >= _stableThreshold;
        } else {
          _stableFrameCount = 0;
        }
      }
      _lastFaceBox = box;

      // Hint text
      String hint = '';
      if (!distanceOk) {
        hint = faceHeightRatio < 0.40 ? 'Move closer' : 'Move back a little';
      } else if (!centered) {
        if (dx > 0.20) {
          hint = faceCenterX < previewW / 2 ? 'Move right' : 'Move left';
        } else {
          hint = faceCenterY < previewH / 2 ? 'Move down' : 'Move up';
        }
      } else if (!straight) {
        if (yaw.abs() >= 12) {
          hint = yaw > 0 ? 'Turn left slightly' : 'Turn right slightly';
        } else if (pitch.abs() >= 12) {
          hint = pitch > 0 ? 'Tilt head up' : 'Tilt head down slightly';
        } else {
          hint = 'Keep your head level';
        }
      } else if (!lightingOk) {
        hint = 'Too dark — face a window or turn on a light';
      } else if (!holdStill) {
        hint = 'Hold still…';
      } else {
        hint = 'Perfect! Capturing…';
      }

      _updateGuidance(
        faceDetected: true,
        centered: centered,
        distanceOk: distanceOk,
        straight: straight,
        lightingOk: lightingOk,
        holdStill: holdStill,
        hint: hint,
      );

      // Auto-capture when all checks pass
      final allOk = centered && distanceOk && straight && lightingOk && holdStill;
      if (allOk && !_countingDown && !_capturing) {
        _startCountdown();
      }
    } catch (_) {}
  }

  InputImage? _buildInputImage(CameraImage image) {
    final rotation = _getRotation(
      _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      ).sensorOrientation,
    );

    final format = Platform.isAndroid
        ? InputImageFormat.nv21
        : InputImageFormat.bgra8888;

    final plane = image.planes[0];
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  InputImageRotation _getRotation(int sensorOrientation) {
    switch (sensorOrientation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  /// Rough luminance estimate from Y-plane (NV21) or blue channel (BGRA).
  /// Sample a sparse grid for performance.
  bool _estimateLighting(CameraImage image) {
    try {
      final plane = image.planes[0];
      final bytes = plane.bytes;
      int total = 0;
      int count = 0;
      final step = math.max(1, bytes.length ~/ 200);
      for (int i = 0; i < bytes.length; i += step) {
        total += bytes[i];
        count++;
      }
      final mean = total / count;
      // Y-plane / BGRA: 0–255. Good range: 60–200
      return mean >= 60 && mean <= 210;
    } catch (_) {
      return true;
    }
  }

  void _updateGuidance({
    required bool faceDetected,
    required bool centered,
    required bool distanceOk,
    required bool straight,
    required bool lightingOk,
    required bool holdStill,
    required String hint,
  }) {
    _faceDetectedNotifier.value = faceDetected;
    _centeredNotifier.value = centered;
    _distanceOkNotifier.value = distanceOk;
    _straightNotifier.value = straight;
    _lightingOkNotifier.value = lightingOk;
    _holdStillNotifier.value = holdStill;
    _hintNotifier.value = hint;
    _allOkNotifier.value =
        faceDetected && centered && distanceOk && straight && lightingOk && holdStill;
  }

  // ── Countdown ────────────────────────────────────────────────────────────

  void _startCountdown() {
    if (_countingDown) return;
    setState(() {
      _countingDown = true;
      _countdownValue = 3;
    });
    HapticFeedback.mediumImpact();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _countdownValue--);
      HapticFeedback.selectionClick();
      if (_countdownValue <= 0) {
        t.cancel();
        _capture();
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    if (mounted) setState(() { _countingDown = false; _countdownValue = 3; });
  }

  // ── Capture ───────────────────────────────────────────────────────────────

  Future<void> _capture() async {
    if (_capturing || _controller == null) return;
    setState(() { _capturing = true; _countingDown = false; });
    _stopStream();

    try {
      final xFile = await _controller!.takePicture();
      if (mounted) {
        setState(() => _capturedPath = xFile.path);
      }
    } catch (e) {
      setState(() { _capturing = false; _countingDown = false; });
      await _controller?.startImageStream(_onFrame);
    }
  }

  void _retake() {
    setState(() {
      _capturedPath = null;
      _capturing = false;
      _countingDown = false;
      _stableFrameCount = 0;
    });
    _controller?.startImageStream(_onFrame);
  }

  void _usePhoto() {
    if (_capturedPath == null) return;
    context.push('/scan/analyzing', extra: {
      'imagePath': _capturedPath!,
      'prepared': widget.prepared,
      'minutesSinceWash': widget.minutesSinceWash,
    });
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return;
    if (mounted) {
      setState(() => _capturedPath = picked.path);
    }
  }

  // ── Disposal ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _faceDetector.close();
    _controller?.dispose();
    _faceDetectedNotifier.dispose();
    _centeredNotifier.dispose();
    _distanceOkNotifier.dispose();
    _straightNotifier.dispose();
    _lightingOkNotifier.dispose();
    _holdStillNotifier.dispose();
    _hintNotifier.dispose();
    _allOkNotifier.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_permissionPermanentlyDenied) return _PermissionDeniedView(permanent: true);
    if (_permissionDenied) return _PermissionDeniedView(permanent: false, onRetry: _requestAndInit);

    if (_capturedPath != null) {
      return _PhotoReviewView(
        imagePath: _capturedPath!,
        onRetake: _retake,
        onUse: _usePhoto,
      );
    }

    if (!_cameraReady || _controller == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E1A22),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          _CameraPreviewWidget(controller: _controller!),

          // Oval guide overlay
          ValueListenableBuilder<bool>(
            valueListenable: _allOkNotifier,
            builder: (_, allOk, __) => _OvalGuide(allOk: allOk, countingDown: _countingDown),
          ),

          // Top hint banner
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 20,
            right: 20,
            child: ValueListenableBuilder<String>(
              valueListenable: _hintNotifier,
              builder: (_, hint, __) => _HintBanner(text: hint),
            ),
          ),

          // Camera flip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            right: 20,
            child: _CircleButton(
              icon: CupertinoIcons.switch_camera,
              onTap: _switchCamera,
              small: true,
            ),
          ),

          // Countdown overlay
          if (_countingDown)
            Center(
              child: Text(
                '$_countdownValue',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 100,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 20, color: AppColors.primary)],
                ),
              ),
            ),

          // Guidance chips
          Positioned(
            left: 0,
            right: 0,
            bottom: 160,
            child: _GuidanceChips(
              faceDetected: _faceDetectedNotifier,
              centered: _centeredNotifier,
              distanceOk: _distanceOkNotifier,
              straight: _straightNotifier,
              lightingOk: _lightingOkNotifier,
              holdStill: _holdStillNotifier,
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery button
                _CircleButton(
                  icon: CupertinoIcons.photo,
                  onTap: _pickFromGallery,
                  small: true,
                ),

                // Shutter button
                ValueListenableBuilder<bool>(
                  valueListenable: _allOkNotifier,
                  builder: (_, allOk, __) => GestureDetector(
                    onTap: allOk ? _capture : null,
                    onLongPress: () {
                      // Long press override with warning
                      if (!_countingDown) _capture();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: allOk ? AppColors.primary : Colors.white30,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: allOk
                            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.6), blurRadius: 20)]
                            : [],
                      ),
                      child: const Icon(CupertinoIcons.camera_fill, color: Colors.white, size: 36),
                    ),
                  ),
                ),

                // Cancel countdown
                _CircleButton(
                  icon: CupertinoIcons.xmark,
                  onTap: _countingDown ? _cancelCountdown : () => context.pop(),
                  small: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _CameraPreviewWidget extends StatelessWidget {
  final CameraController controller;
  const _CameraPreviewWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.previewSize!.height,
          height: controller.value.previewSize!.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

class _OvalGuide extends StatelessWidget {
  final bool allOk;
  final bool countingDown;
  const _OvalGuide({required this.allOk, required this.countingDown});

  @override
  Widget build(BuildContext context) {
    final color = countingDown
        ? AppColors.success
        : allOk
            ? AppColors.primary
            : Colors.amber;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 260,
        height: 360,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.elliptical(130, 180)),
          border: Border.all(color: color, width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _HintBanner extends StatelessWidget {
  final String text;
  const _HintBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: ValueKey(text),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _GuidanceChips extends StatelessWidget {
  final ValueNotifier<bool> faceDetected;
  final ValueNotifier<bool> centered;
  final ValueNotifier<bool> distanceOk;
  final ValueNotifier<bool> straight;
  final ValueNotifier<bool> lightingOk;
  final ValueNotifier<bool> holdStill;

  const _GuidanceChips({
    required this.faceDetected,
    required this.centered,
    required this.distanceOk,
    required this.straight,
    required this.lightingOk,
    required this.holdStill,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        _Chip(label: 'Face detected', notifier: faceDetected),
        _Chip(label: 'Centered', notifier: centered),
        _Chip(label: 'Distance', notifier: distanceOk),
        _Chip(label: 'Straight', notifier: straight),
        _Chip(label: 'Lighting', notifier: lightingOk),
        _Chip(label: 'Hold still', notifier: holdStill),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final ValueNotifier<bool> notifier;
  const _Chip({required this.label, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (_, ok, __) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: ok
              ? const Color(0xFF34C38F).withValues(alpha: 0.85)
              : Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ok ? const Color(0xFF34C38F) : Colors.white24,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ok ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
              color: ok ? Colors.white : Colors.white54,
              size: 13,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ok ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool small;
  const _CircleButton({required this.icon, required this.onTap, this.small = false});

  @override
  Widget build(BuildContext context) {
    final size = small ? 52.0 : 64.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: small ? 24 : 28),
      ),
    );
  }
}

// ── Photo review ─────────────────────────────────────────────────────────────

class _PhotoReviewView extends StatelessWidget {
  final String imagePath;
  final VoidCallback onRetake;
  final VoidCallback onUse;

  const _PhotoReviewView({
    required this.imagePath,
    required this.onRetake,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(imagePath), fit: BoxFit.cover),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Use this photo?',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Make sure your face is well-lit and clearly visible.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(CupertinoIcons.arrow_counterclockwise, color: Colors.white),
                          label: const Text('Retake', style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: onRetake,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(CupertinoIcons.checkmark, color: Colors.white),
                          label: const Text('Use Photo', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: onUse,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: _CircleButton(icon: CupertinoIcons.xmark, onTap: onRetake),
          ),
        ],
      ),
    );
  }
}

// ── Permission views ─────────────────────────────────────────────────────────

class _PermissionDeniedView extends StatelessWidget {
  final bool permanent;
  final VoidCallback? onRetry;

  const _PermissionDeniedView({required this.permanent, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.camera_fill, size: 64, color: AppColors.textHint),
              const SizedBox(height: 24),
              Text(
                permanent ? 'Camera Permission Required' : 'Camera Access Needed',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                permanent
                    ? 'GlowAI needs camera access to scan your skin. Please enable it in Settings > GlowAI > Camera.'
                    : 'GlowAI uses the camera to analyze your skin. Please allow camera access to continue.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 32),
              if (permanent)
                ElevatedButton(
                  onPressed: openAppSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  child: const Text('Open Settings', style: TextStyle(color: Colors.white)),
                )
              else
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  child: const Text('Allow Camera', style: TextStyle(color: Colors.white)),
                ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
