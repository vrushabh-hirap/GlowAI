import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/scan_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/tappable.dart';

// TODO(module: scan) connect to camera package camera preview and camera controller

class ScanCameraScreen extends ConsumerWidget {
  const ScanCameraScreen({super.key});

  void _capture(BuildContext context, WidgetRef ref, String imagePath) {
    ref.read(scanResultProvider.notifier).runMockScan(imagePath);
    context.push('/scan/analyzing');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: 'Face Scan Preview',
      body: Stack(
        children: [
          // Mock Camera Viewport
          Positioned.fill(
            child: Container(
              color: const Color(0xFF1E1A22),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.face_retouching_natural_rounded,
                    size: 80,
                    color: Colors.white38,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Camera Feed Preview (Mock)',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Face Oval Guide Overlay
          Center(
            child: Container(
              width: 270,
              height: 370,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.elliptical(135, 185)),
                border: Border.all(
                  color: AppColors.primary,
                  width: 3.5,
                ),
                boxShadow: AppShadows.glow,
              ),
            ),
          ),

          // Top Hint Banner
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wb_sunny_rounded, color: AppColors.warning, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Ensure even, natural lighting inside the oval',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Control Panel
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery Pick Button
                Tappable(
                  onTap: () => _capture(context, ref, 'assets/icon/icon.png'),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 26),
                  ),
                ),

                // Capture Button with Glow Ring
                Tappable(
                  onTap: () => _capture(context, ref, 'assets/icon/icon.png'),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                      boxShadow: AppShadows.glow,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 36),
                  ),
                ),

                // Flip Camera Button
                Tappable(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Flipped camera view (mock)')),
                    );
                  },
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 26),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
