import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_scaffold.dart';



// TODO(module: consultation) connect to url_launcher for Jitsi Meet room launch

class CallPlaceholderScreen extends StatefulWidget {
  final String appointmentId;

  const CallPlaceholderScreen({super.key, required this.appointmentId});

  @override
  State<CallPlaceholderScreen> createState() => _CallPlaceholderScreenState();
}

class _CallPlaceholderScreenState extends State<CallPlaceholderScreen> {
  bool _isMuted = false;
  bool _isVideoOff = false;

  @override
  Widget build(BuildContext context) {
    final roomUrl = 'https://meet.jit.si/GlowAI-${widget.appointmentId}';

    return AppScaffold(
      title: 'Video Consultation',
      body: Stack(
        children: [
          // Mock Video Screen Background
          Positioned.fill(
            child: Container(
              color: const Color(0xFF141018),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 3),
                      image: const DecorationImage(
                        image: AssetImage('assets/icon/icon.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Dr. Ananya Sharma',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Connecting to secure Jitsi video room...',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      roomUrl,
                      style: const TextStyle(color: AppColors.primarySoft, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Controls Bar
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: 'mute',
                  backgroundColor: _isMuted ? AppColors.danger : Colors.white24,
                  onPressed: () => setState(() => _isMuted = !_isMuted),
                  child: Icon(_isMuted ? Icons.mic_off_rounded : Icons.mic_rounded, color: Colors.white),
                ),
                FloatingActionButton.large(
                  heroTag: 'end',
                  backgroundColor: AppColors.danger,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Call ended')),
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 36),
                ),
                FloatingActionButton(
                  heroTag: 'cam',
                  backgroundColor: _isVideoOff ? AppColors.danger : Colors.white24,
                  onPressed: () => setState(() => _isVideoOff = !_isVideoOff),
                  child: Icon(_isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
