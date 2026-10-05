// lib/features/scan/scan_result_screen.dart
// A7: Full-width score card, file-based overlay loading, correct severity colors.
// Overlays are read from filesystem (relative path resolved to absolute at load time).
// Counts hidden when unreliable; severity/color consistent with A6.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/scan_result_model.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/glow_button.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/score_ring.dart';
import '../../shared/widgets/status_badge.dart';

class ScanResultScreen extends StatefulWidget {
  final ScanResult result;
  const ScanResultScreen({super.key, required this.result});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  // Overlay toggle: 0=Regions, 1=Blemishes, 2=Dark Spots, 3=Redness
  int _overlayIndex = 0;
  final Map<int, Uint8List?> _overlayCache = {};
  String? _docsPath;

  static const _overlayLabels = ['Regions', 'Blemishes', 'Dark Spots', 'Redness'];

  @override
  void initState() {
    super.initState();
    _initDocsPath();
  }

  Future<void> _initDocsPath() async {
    final dir = await getApplicationDocumentsDirectory();
    if (mounted) setState(() => _docsPath = dir.path);
  }

  /// Returns the relative overlay path for the given tab index.
  String? _relativeOverlayPath(int index) {
    final o = widget.result.overlay;
    switch (index) {
      case 0: return o.regionsJpegPath;
      case 1: return o.blemishesJpegPath;
      case 2: return o.darkSpotsJpegPath;
      case 3: return o.rednessJpegPath;
      default: return null;
    }
  }

  /// Resolves relative path → absolute path and loads bytes.
  Future<Uint8List?> _loadOverlay(int index) async {
    if (_overlayCache.containsKey(index)) return _overlayCache[index];

    final relPath = _relativeOverlayPath(index);
    if (relPath == null || relPath.isEmpty) {
      _overlayCache[index] = null;
      return null;
    }

    // Resolve absolute path
    final docs = _docsPath ?? (await getApplicationDocumentsDirectory()).path;
    // If it's already absolute (old legacy records), use as-is
    final absPath = relPath.startsWith('/') ? relPath : '$docs/$relPath';

    final file = File(absPath);
    if (!file.existsSync()) {
      _overlayCache[index] = null;
      return null;
    }
    try {
      final bytes = file.readAsBytesSync();
      _overlayCache[index] = bytes;
      return bytes;
    } catch (_) {
      _overlayCache[index] = null;
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final hasConditions = r.conditions != null;

    return AppScaffold(
      title: 'Scan Results',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // full-width children
          children: [
            // ── Overall score header — FULL WIDTH (A7) ─────────────────
            _HealthCard(result: r),
            const SizedBox(height: 12),

            // ── Photo thumbnail ─────────────────────────────────────────
            if (r.localImagePath != null && File(r.localImagePath!).existsSync())
              _PhotoThumbnail(imagePath: r.localImagePath!),

            // ── Prep / quality warning ──────────────────────────────────
            if (!r.prep.prepared || r.quality.score < 70) ...[
              const SizedBox(height: 12),
              _WarningBanner(
                message: !r.prep.prepared
                    ? 'Scanned before the 30-minute wait — oil and skin-type readings may be less accurate.'
                    : 'Photo quality ${r.quality.score}/100. Results may be less precise.',
              ),
            ],

            // ── Skin type ───────────────────────────────────────────────
            if (r.skinType != null) ...[
              const SizedBox(height: 16),
              _SectionTitle('Skin Type'),
              const SizedBox(height: 8),
              _ConditionCard(
                icon: CupertinoIcons.drop_fill,
                title: r.skinType!.label,
                subtitle:
                    'T-zone shine: ${(r.skinType!.tzoneShine * 100).toStringAsFixed(1)}%  ·  Cheek shine: ${(r.skinType!.cheekShine * 100).toStringAsFixed(1)}%',
                score: null,
                confidence: r.skinType!.confidence,
                severity: null,
              ),
            ],

            // ── Skin tone ───────────────────────────────────────────────
            if (r.skinTone != null) ...[
              const SizedBox(height: 16),
              _SectionTitle('Skin Tone'),
              const SizedBox(height: 8),
              GlowCard(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _hexColor(r.skinTone!.hex),
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.skinTone!.label.isNotEmpty
                                ? r.skinTone!.label
                                : 'Level ${r.skinTone!.level}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Undertone: ${r.skinTone!.undertone}  ·  ITA: ${r.skinTone!.itaDegrees.toStringAsFixed(1)}°',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ReliabilityChip(confidence: r.skinTone!.confidence),
                  ],
                ),
              ),
            ],

            // ── Conditions ──────────────────────────────────────────────
            if (hasConditions) ...[
              const SizedBox(height: 20),
              _SectionTitle('Skin Conditions'),
              const SizedBox(height: 8),
              // Acne
              _ConditionCard(
                icon: CupertinoIcons.flame_fill,
                title: 'Acne & Inflamed Spots',
                subtitle: _acneSubtitle(r.conditions!.acne),
                score: r.conditions!.acne.score,
                confidence: r.conditions!.acne.confidence,
                severity: r.conditions!.acne.severity,
              ),
              const SizedBox(height: 10),
              // Redness
              _ConditionCard(
                icon: CupertinoIcons.heart_fill,
                title: 'Redness',
                subtitle: 'Score: ${r.conditions!.redness.score}/100',
                score: r.conditions!.redness.score,
                confidence: r.conditions!.redness.confidence,
                severity: r.conditions!.redness.severity,
              ),
              const SizedBox(height: 10),
              // Dark Spots
              _ConditionCard(
                icon: CupertinoIcons.circle_fill,
                title: 'Dark Spots',
                subtitle: _darkSpotSubtitle(r.conditions!.darkSpots),
                score: r.conditions!.darkSpots.score,
                confidence: r.conditions!.darkSpots.confidence,
                severity: r.conditions!.darkSpots.severity,
              ),
              const SizedBox(height: 10),
              // Pigmentation
              _ConditionCard(
                icon: CupertinoIcons.layers_fill,
                title: 'Pigmentation Evenness',
                subtitle: 'Score: ${r.conditions!.pigmentation.score}/100',
                score: r.conditions!.pigmentation.score,
                confidence: r.conditions!.pigmentation.confidence,
                severity: r.conditions!.pigmentation.severity,
              ),
              const SizedBox(height: 10),
              // Texture
              _ConditionCard(
                icon: Icons.grid_4x4_outlined,
                title: 'Texture Smoothness',
                subtitle: 'Score: ${r.conditions!.texture.score}/100',
                score: r.conditions!.texture.score,
                confidence: r.conditions!.texture.confidence,
                severity: r.conditions!.texture.severity,
              ),
            ],

            // ── Annotated overlay — visual center (A7) ──────────────────
            const SizedBox(height: 24),
            _SectionTitle('Annotated View'),
            const SizedBox(height: 8),
            _OverlaySection(
              overlayLabels: _overlayLabels,
              selectedIndex: _overlayIndex,
              onToggle: (i) {
                setState(() => _overlayIndex = i);
              },
              loadOverlay: _loadOverlay,
            ),

            // ── Insights ─────────────────────────────────────────────────
            if (r.insights.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionTitle('Insights'),
              const SizedBox(height: 8),
              GlowCard(
                child: Column(
                  children: r.insights
                      .map((s) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(CupertinoIcons.info_circle_fill,
                                    size: 16, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    s,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],

            // ── Risk / severity tile ──────────────────────────────────────
            const SizedBox(height: 16),
            GlowCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BadgeTile(
                    label: 'Severity',
                    value: r.severity,
                    color: _severityColor(r.severity),
                    icon: Icons.warning_amber_rounded,
                  ),
                  Container(width: 1, height: 36, color: AppColors.border),
                  _BadgeTile(
                    label: 'Risk',
                    value: r.risk,
                    color: _riskColor(r.risk),
                    icon: Icons.shield_outlined,
                  ),
                ],
              ),
            ),

            // ── Disclaimer ────────────────────────────────────────────────
            const SizedBox(height: 16),
            _DisclaimerBanner(text: r.disclaimer),

            // ── CTAs ──────────────────────────────────────────────────────
            const SizedBox(height: 24),
            GlowButton(
              label: 'View Full Report',
              icon: Icons.description_rounded,
              width: double.infinity,
              onPressed: () => context.push('/report', extra: r),
            ),
            if (r.seeDoctor) ...[
              const SizedBox(height: 12),
              GlowButton(
                label: 'Consult a Dermatologist',
                icon: Icons.health_and_safety_rounded,
                width: double.infinity,
                style: GlowButtonStyle.primary,
                onPressed: () => context.go('/patient/consult'),
              ),
            ],
            const SizedBox(height: 12),
            GlowButton(
              label: 'Scan Again',
              icon: CupertinoIcons.camera_fill,
              width: double.infinity,
              style: GlowButtonStyle.secondary,
              onPressed: () => context.go('/patient/scan'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Subtitle helpers ───────────────────────────────────────────────────────

  String _acneSubtitle(ConditionResult acne) {
    if (acne.severity == 'Unreliable') return 'Reading not reliable — check lighting or facial hair';
    if (acne.count != null) {
      return '${acne.count} inflamed spot${acne.count == 1 ? "" : "s"} detected';
    }
    return 'Score: ${acne.score}/100';
  }

  String _darkSpotSubtitle(ConditionResult ds) {
    if (ds.severity == 'Unreliable') return 'Reading not reliable — check lighting or facial hair';
    if (ds.count != null) {
      return '${ds.count} spot${ds.count == 1 ? "" : "s"} found';
    }
    return 'Score: ${ds.score}/100';
  }

  Color _hexColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.primarySoft;
    }
  }

  // A6.3 — severity drives color
  static Color _severityColor(String severity) {
    switch (severity) {
      case 'None':     return AppColors.success;
      case 'Mild':     return AppColors.success;
      case 'Moderate': return AppColors.warning;
      case 'Severe':   return AppColors.danger;
      default:         return AppColors.textSecondary;
    }
  }

  static Color _riskColor(String risk) {
    switch (risk) {
      case 'Low':    return AppColors.success;
      case 'Medium': return AppColors.warning;
      case 'High':   return AppColors.danger;
      default:       return AppColors.textSecondary;
    }
  }
}

// ── Full-width health card (A7 fix) ─────────────────────────────────────────

class _HealthCard extends StatelessWidget {
  final ScanResult result;
  const _HealthCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      hasGlow: true,
      child: Row(
        children: [
          ScoreRing(score: result.overallScore, radius: 52, lineWidth: 10),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Skin Health',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM yyyy • HH:mm').format(result.timestamp),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                StatusBadge(label: result.severity),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Photo thumbnail ──────────────────────────────────────────────────────────

class _PhotoThumbnail extends StatelessWidget {
  final String imagePath;
  const _PhotoThumbnail({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Captured Photo',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(imagePath),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Overlay section ──────────────────────────────────────────────────────────

class _OverlaySection extends StatefulWidget {
  final List<String> overlayLabels;
  final int selectedIndex;
  final void Function(int) onToggle;
  final Future<Uint8List?> Function(int) loadOverlay;

  const _OverlaySection({
    required this.overlayLabels,
    required this.selectedIndex,
    required this.onToggle,
    required this.loadOverlay,
  });

  @override
  State<_OverlaySection> createState() => _OverlaySectionState();
}

class _OverlaySectionState extends State<_OverlaySection> {
  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: List.generate(widget.overlayLabels.length, (i) {
              final selected = i == widget.selectedIndex;
              return GestureDetector(
                onTap: () => widget.onToggle(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.overlayLabels[i],
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          // Overlay image loaded from file
          FutureBuilder<Uint8List?>(
            future: widget.loadOverlay(widget.selectedIndex),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 220,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }
              if (snap.data == null) {
                return Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(CupertinoIcons.photo, size: 36, color: AppColors.textHint),
                        SizedBox(height: 8),
                        Text(
                          'Overlay not available\nfor this layer',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: AppColors.textHint,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tip: Scan again in good lighting',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: InteractiveViewer(
                  maxScale: 6,
                  child: Image.memory(
                    snap.data!,
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      );
}

class _ConditionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int? score;
  final double confidence;
  final String? severity;

  const _ConditionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.score,
    required this.confidence,
    required this.severity,
  });

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _severityColor(severity), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _ReliabilityChip(confidence: confidence),
              if (severity != null && severity != 'None' && severity != 'Unknown') ...[
                const SizedBox(width: 6),
                StatusBadge(label: severity!),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          // Bar: length = score, color = severity (A6.3)
          if (score != null && severity != 'Unreliable') ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score! / 100.0,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(_severityColor(severity)),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// A6.3: color follows severity, not the raw score number.
  static Color _severityColor(String? severity) {
    switch (severity) {
      case 'None':       return AppColors.success;
      case 'Mild':       return AppColors.success;
      case 'Moderate':   return AppColors.warning;
      case 'Severe':     return AppColors.danger;
      case 'Unreliable': return AppColors.textHint;
      default:           return AppColors.primary;
    }
  }
}

/// Replaces the raw percentage chip with Low/Medium/High text.
class _ReliabilityChip extends StatelessWidget {
  final double confidence;
  const _ReliabilityChip({required this.confidence});

  @override
  Widget build(BuildContext context) {
    late Color color;
    late String label;
    if (confidence >= 0.70) {
      color = AppColors.success;
      label = 'High';
    } else if (confidence >= 0.45) {
      color = AppColors.warning;
      label = 'Med';
    } else {
      color = AppColors.danger;
      label = 'Low';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final String message;
  const _WarningBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.exclamationmark_triangle_fill,
              color: AppColors.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  final String text;
  const _DisclaimerBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, color: AppColors.primaryDark, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _BadgeTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
