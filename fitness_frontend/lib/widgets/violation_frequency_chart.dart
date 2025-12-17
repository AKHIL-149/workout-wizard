import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/form_analysis.dart';

/// Chart showing frequency of form violations
class ViolationFrequencyChart extends StatelessWidget {
  final Map<String, int> violationFrequency;
  final double height;

  const ViolationFrequencyChart({
    super.key,
    required this.violationFrequency,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    if (violationFrequency.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Perfect form!\nNo violations detected',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sort violations by frequency
    final sortedViolations = violationFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 5
    final topViolations = sortedViolations.take(5).toList();

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      child: BarChart(
        _createBarChartData(topViolations),
        swapAnimationDuration: const Duration(milliseconds: 250),
        swapAnimationCurve: Curves.easeInOut,
      ),
    );
  }

  BarChartData _createBarChartData(List<MapEntry<String, int>> violations) {
    final barGroups = <BarChartGroupData>[];

    for (int i = 0; i < violations.length; i++) {
      final entry = violations[i];
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: entry.value.toDouble(),
              gradient: _getGradientForViolation(entry.key),
              width: 40,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
    }

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: (violations.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2),
      barGroups: barGroups,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 80,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= violations.length) {
                return const Text('');
              }

              final violationType = violations[value.toInt()].key;
              final displayName = _formatViolationType(violationType);

              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Transform.rotate(
                  angle: -0.5,
                  child: Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              );
            },
          ),
          axisNameWidget: const Text(
            'Count',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: Colors.black.withOpacity(0.8),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final entry = violations[group.x.toInt()];
            return BarTooltipItem(
              '${_formatViolationType(entry.key)}\n${entry.value} times',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            );
          },
        ),
      ),
    );
  }

  LinearGradient _getGradientForViolation(String violationType) {
    // Severity-based colors
    final severity = _getViolationSeverity(violationType);

    switch (severity) {
      case Severity.critical:
        return LinearGradient(
          colors: [Colors.red[400]!, Colors.red[700]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case Severity.warning:
        return LinearGradient(
          colors: [Colors.orange[400]!, Colors.orange[700]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case Severity.info:
        return LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[700]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
    }
  }

  Severity _getViolationSeverity(String violationType) {
    // Map violation types to severity
    const criticalViolations = [
      ViolationType.kneeCave,
      ViolationType.backRounding,
    ];

    const infoViolations = [
      ViolationType.headPosition,
      ViolationType.tooFastEccentric,
      ViolationType.tooFastConcentric,
      ViolationType.gripWidth,
    ];

    if (criticalViolations.contains(violationType)) {
      return Severity.critical;
    } else if (infoViolations.contains(violationType)) {
      return Severity.info;
    } else {
      return Severity.warning;
    }
  }

  String _formatViolationType(String violationType) {
    // Convert SNAKE_CASE to Title Case
    return violationType
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}

/// Widget showing list of violations with descriptions
class ViolationListWidget extends StatelessWidget {
  final Map<String, int> violationFrequency;

  const ViolationListWidget({
    super.key,
    required this.violationFrequency,
  });

  @override
  Widget build(BuildContext context) {
    if (violationFrequency.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedViolations = violationFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Common Issues',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...sortedViolations.map((entry) {
          final severity = _getViolationSeverity(entry.key);
          return _buildViolationItem(
            violationType: entry.key,
            count: entry.value,
            severity: severity,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildViolationItem({
    required String violationType,
    required int count,
    required Severity severity,
  }) {
    Color color;
    IconData icon;

    switch (severity) {
      case Severity.critical:
        color = Colors.red;
        icon = Icons.error;
        break;
      case Severity.warning:
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case Severity.info:
        color = Colors.blue;
        icon = Icons.info;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatViolationType(violationType),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Occurred $count ${count == 1 ? 'time' : 'times'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Severity _getViolationSeverity(String violationType) {
    const criticalViolations = [
      ViolationType.kneeCave,
      ViolationType.backRounding,
    ];

    const infoViolations = [
      ViolationType.headPosition,
      ViolationType.tooFastEccentric,
      ViolationType.tooFastConcentric,
      ViolationType.gripWidth,
    ];

    if (criticalViolations.contains(violationType)) {
      return Severity.critical;
    } else if (infoViolations.contains(violationType)) {
      return Severity.info;
    } else {
      return Severity.warning;
    }
  }

  String _formatViolationType(String violationType) {
    return violationType
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
