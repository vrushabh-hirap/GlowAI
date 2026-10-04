import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/glow_card.dart';

// TODO(module: progress) connect to Hive scans box for historical multi-scan analysis

class ProgressTrackerScreen extends StatefulWidget {
  const ProgressTrackerScreen({super.key});

  @override
  State<ProgressTrackerScreen> createState() => _ProgressTrackerScreenState();
}

class _ProgressTrackerScreenState extends State<ProgressTrackerScreen> {
  double _sliderVal = 0.5;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Progress & Health Score',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score Trend Chart Header
            const Text(
              'Skin Health Score Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GlowCard(
              hasGlow: true,
              child: Column(
                children: [
                  SizedBox(
                    height: 180,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                switch (val.toInt()) {
                                  case 0:
                                    return const Text('Wk 1', style: TextStyle(fontSize: 11));
                                  case 1:
                                    return const Text('Wk 2', style: TextStyle(fontSize: 11));
                                  case 2:
                                    return const Text('Wk 3', style: TextStyle(fontSize: 11));
                                  case 3:
                                    return const Text('Today', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark));
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 62),
                              FlSpot(1, 68),
                              FlSpot(2, 72),
                              FlSpot(3, 78),
                            ],
                            isCurved: true,
                            color: AppColors.primaryDark,
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.primarySoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.trending_up_rounded, color: AppColors.success, size: 20),
                      SizedBox(width: 6),
                      Text(
                        '+16% improvement over 4 weeks',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.success),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Before / After Comparison Slider
            const Text(
              'Before / After Scan Comparison',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GlowCard(
              child: Column(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        // Background image (After)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset('assets/icon/icon.png', fit: BoxFit.cover),
                          ),
                        ),
                        // Clipped image (Before)
                        Positioned.fill(
                          child: ClipRect(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              widthFactor: _sliderVal,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  color: Colors.pink.shade100,
                                  child: Image.asset('assets/icon/icon.png', fit: BoxFit.cover),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Divider Line
                        Positioned(
                          top: 0,
                          bottom: 0,
                          left: MediaQuery.of(context).size.width * 0.75 * _sliderVal,
                          child: Container(
                            width: 3,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _sliderVal,
                    activeColor: AppColors.primaryDark,
                    inactiveColor: AppColors.border,
                    onChanged: (val) => setState(() => _sliderVal = val),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Before (4 Wks Ago)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      Text('After (Today)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
