// lib/features/progress/progress_tracker_screen.dart
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/scan_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../models/scan_result_model.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/chip_tag.dart';
import '../../shared/widgets/glow_button.dart';
import '../../shared/widgets/glow_card.dart';

class ProgressTrackerScreen extends ConsumerStatefulWidget {
  const ProgressTrackerScreen({super.key});

  @override
  ConsumerState<ProgressTrackerScreen> createState() => _ProgressTrackerScreenState();
}

class _ProgressTrackerScreenState extends ConsumerState<ProgressTrackerScreen> {
  double _sliderVal = 0.5;
  String _selectedRange = 'All'; // '7 Days', '30 Days', '90 Days', 'All'
  bool _hidePhotos = false;
  String? _docsPath;

  @override
  void initState() {
    super.initState();
    getApplicationDocumentsDirectory().then((d) {
      if (mounted) setState(() => _docsPath = d.path);
    });
  }

  int _beforeScanIndex = 0;
  int _afterScanIndex = 0;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(scanHistoryProvider);

    return historyAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        appBar: AppHeader(title: 'Progress Tracker'),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: Colors.white,
        appBar: const AppHeader(title: 'Progress Tracker'),
        body: Center(child: Text('Error loading scans: $err')),
      ),
      data: (historyScans) {
        if (historyScans.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: const AppHeader(title: 'Progress Tracker'),
            body: _buildEmptyState(0, context),
          );
        }

    // Filter scans by range
    final now = DateTime.now();
    final filteredScans = historyScans.where((scan) {
      if (_selectedRange == '7 Days') {
        return now.difference(scan.timestamp).inDays <= 7;
      } else if (_selectedRange == '30 Days') {
        return now.difference(scan.timestamp).inDays <= 30;
      } else if (_selectedRange == '90 Days') {
        return now.difference(scan.timestamp).inDays <= 90;
      }
      return true;
    }).toList();

    // Sort chronologically ascending for chart (oldest to newest)
    final chronological = List<ScanResult>.from(filteredScans)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (chronological.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: const AppHeader(title: 'Progress Tracker'),
        body: Center(
          child: Text(
            'No scans in $_selectedRange range.',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final latestScan = chronological.last;
    final firstScan = chronological.first;
    final int scoreDelta = latestScan.overallScore - firstScan.overallScore;

    if (_afterScanIndex >= historyScans.length) _afterScanIndex = 0;
    if (_beforeScanIndex >= historyScans.length || _beforeScanIndex == 0) {
      _beforeScanIndex = historyScans.length > 1 ? historyScans.length - 1 : 0;
    }

    final beforeScan = historyScans[_beforeScanIndex];
    final afterScan = historyScans[_afterScanIndex];

    final bool comparabilityWarning = (beforeScan.overallScore - afterScan.overallScore).abs() > 30;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppHeader(
        title: 'Progress Tracker',
        actions: [
          IconButton(
            icon: Icon(_hidePhotos ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.primaryDark),
            onPressed: () => setState(() => _hidePhotos = !_hidePhotos),
            tooltip: 'Privacy Photo Toggle',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Range Chips
            Row(
              children: [
                const Text(
                  'Range:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['7 Days', '30 Days', '90 Days', 'All'].map((range) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChipTag(
                            label: range,
                            isSelected: _selectedRange == range,
                            onTap: () => setState(() => _selectedRange = range),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Health Score Chart
            GlowCard(
              hasGlow: true,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Overall Skin Health',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Latest: ${latestScan.overallScore}/100',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  RepaintBoundary(
                    child: SizedBox(
                      height: 160,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (val) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                          ),
                          titlesData: FlTitlesData(
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                  int idx = val.toInt();
                                  if (idx >= 0 && idx < chronological.length) {
                                    final dateStr = chronological[idx].timestamp.toIso8601String().substring(5, 10);
                                    return Text(dateStr, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary));
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: chronological.asMap().entries.map((e) {
                                return FlSpot(e.key.toDouble(), e.value.overallScore.toDouble());
                              }).toList(),
                              isCurved: true,
                              color: AppColors.primaryDark,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.primarySoft.withValues(alpha: 0.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        scoreDelta >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        color: scoreDelta >= 0 ? AppColors.success : AppColors.danger,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        scoreDelta.abs() < 3
                            ? 'Skin health is stable'
                            : '${scoreDelta > 0 ? "+" : ""}$scoreDelta pts overall change',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: scoreDelta >= 0 ? AppColors.success : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Key Conditions Deltas
            const Text(
              'Condition Progress Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            GlowCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildConditionDeltaRow(
                    'Acne Lesions',
                    '${firstScan.conditions?.acne.count ?? 0} spots',
                    '${latestScan.conditions?.acne.count ?? 0} spots',
                    (firstScan.conditions?.acne.count ?? 0) - (latestScan.conditions?.acne.count ?? 0),
                  ),
                  const Divider(),
                  _buildConditionDeltaRow(
                    'Redness Severity',
                    '${firstScan.conditions?.redness.score ?? 0}/100',
                    '${latestScan.conditions?.redness.score ?? 0}/100',
                    (firstScan.conditions?.redness.score ?? 0) - (latestScan.conditions?.redness.score ?? 0),
                  ),
                  const Divider(),
                  _buildConditionDeltaRow(
                    'Dark Spots',
                    '${firstScan.conditions?.darkSpots.count ?? 0} spots',
                    '${latestScan.conditions?.darkSpots.count ?? 0} spots',
                    (firstScan.conditions?.darkSpots.count ?? 0) - (latestScan.conditions?.darkSpots.count ?? 0),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Before / After Photo Comparison Slider
            const Text(
              'Before / After Photo Comparison',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),

            GlowCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  if (comparabilityWarning) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lighting or angle differs between these scans. Small visual changes may not be real.',
                              style: TextStyle(fontSize: 10, color: Colors.amber),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Photo View Container
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _hidePhotos
                        ? const Center(
                            child: Text(
                              'Photos hidden for privacy',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          )
                        : Stack(
                            children: [
                              // After image
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: _buildImageWidget(afterScan.overlay.regionsJpegPath ?? ''),
                                ),
                              ),
                              // Before image clipped
                              Positioned.fill(
                                child: ClipRect(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: _sliderVal,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: _buildImageWidget(beforeScan.overlay.regionsJpegPath ?? ''),
                                    ),
                                  ),
                                ),
                              ),
                              // Slider divider line
                              Positioned(
                                top: 0,
                                bottom: 0,
                                left: (MediaQuery.of(context).size.width - 56) * _sliderVal,
                                child: Container(
                                  width: 3,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 10),
                  Slider(
                    value: _sliderVal,
                    activeColor: AppColors.primaryDark,
                    inactiveColor: AppColors.border,
                    onChanged: (val) => setState(() => _sliderVal = val),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Before: ${beforeScan.timestamp.toIso8601String().substring(0, 10)}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      Text(
                        'After: ${afterScan.timestamp.toIso8601String().substring(0, 10)}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildImageWidget(String path) {
    if (path.isNotEmpty && !path.startsWith('/') && _docsPath != null) {
      path = '$_docsPath/$path';
    }
    if (path.isEmpty || !File(path).existsSync()) {
      return Container(
        color: AppColors.primarySoft.withValues(alpha: 0.3),
        child: const Center(
          child: Icon(Icons.face_rounded, size: 48, color: AppColors.primary),
        ),
      );
    }
    return Image.file(File(path), fit: BoxFit.cover);
  }

  Widget _buildConditionDeltaRow(String title, String before, String after, int delta) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Row(
            children: [
              Text('$before → $after', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: delta > 0 ? AppColors.success.withValues(alpha: 0.1) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  delta > 0 ? 'Improving' : 'Stable',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: delta > 0 ? AppColors.success : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(int count, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Scan again in 1–2 weeks to track progress',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              count == 0
                  ? 'Take your first skin scan to begin tracking your improvement history over time.'
                  : 'You have 1 scan logged. Take a second scan to unlock trend lines and before/after comparisons.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            GlowButton(
              label: 'Start Skin Scan',
              icon: Icons.camera_alt_rounded,
              onPressed: () => context.go('/scan/prep'),
            ),
          ],
        ),
      ),
    );
  }
}
