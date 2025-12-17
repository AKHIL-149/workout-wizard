import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/form_analysis.dart';

/// Chart widget displaying form scores over reps
class FormScoreChart extends StatelessWidget {
  final List<RepAnalysis> repHistory;
  final double height;

  const FormScoreChart({
    super.key,
    required this.repHistory,
    this.height = 250,
  });

  @override
  Widget build(BuildContext context) {
    if (repHistory.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No data yet. Complete some reps!',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        _createLineChartData(context),
      ),
    );
  }

  LineChartData _createLineChartData(BuildContext context) {
    final spots = <FlSpot>[];

    for (int i = 0; i < repHistory.length; i++) {
      spots.add(FlSpot(
        (i + 1).toDouble(),
        repHistory[i].formScore,
      ));
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
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
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value.toInt() > repHistory.length || value < 1) {
                return const Text('');
              }
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
            'Rep Number',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: 20,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}%',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              );
            },
          ),
          axisNameWidget: const Text(
            'Form Score',
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
      minX: 1,
      maxX: repHistory.length.toDouble(),
      minY: 0,
      maxY: 100,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: LinearGradient(
            colors: [
              Colors.blue,
              Colors.green,
            ],
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              final score = spot.y;
              Color color;

              if (score >= 90) {
                color = Colors.green;
              } else if (score >= 70) {
                color = Colors.orange;
              } else {
                color = Colors.red;
              }

              return FlDotCirclePainter(
                radius: 4,
                color: color,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.3),
                Colors.green.withOpacity(0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.black.withOpacity(0.8),
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((spot) {
              final rep = repHistory[spot.x.toInt() - 1];
              return LineTooltipItem(
                'Rep ${spot.x.toInt()}\n${spot.y.toStringAsFixed(1)}% (${rep.grade})',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }
}

/// Compact version showing average score
class AverageFormScoreWidget extends StatelessWidget {
  final double averageScore;

  const AverageFormScoreWidget({
    super.key,
    required this.averageScore,
  });

  @override
  Widget build(BuildContext context) {
    final score = FormScore.fromPercentage(averageScore);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            score.displayColor.withOpacity(0.8),
            score.displayColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: score.displayColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Average Form Score',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            score.grade,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${averageScore.toStringAsFixed(1)}%',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}
