import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/progression_metrics.dart';

enum ChartType { volume, weight }

/// Reusable chart widget for displaying progression data
class ProgressionChart extends StatefulWidget {
  final List<VolumeDataPoint>? volumeHistory;
  final List<WeightDataPoint>? weightHistory;
  final ChartType chartType;
  final String title;

  const ProgressionChart({
    super.key,
    this.volumeHistory,
    this.weightHistory,
    required this.chartType,
    required this.title,
  });

  @override
  State<ProgressionChart> createState() => _ProgressionChartState();
}

class _ProgressionChartState extends State<ProgressionChart> {
  @override
  Widget build(BuildContext context) {
    if (widget.chartType == ChartType.volume && widget.volumeHistory == null) {
      return _buildEmptyState();
    }
    if (widget.chartType == ChartType.weight && widget.weightHistory == null) {
      return _buildEmptyState();
    }

    final spots = widget.chartType == ChartType.volume
        ? _buildVolumeSpots()
        : _buildWeightSpots();

    if (spots.isEmpty) {
      return _buildEmptyState();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _getHorizontalInterval(),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
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
                          return _buildBottomTitle(value.toInt());
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        interval: _getHorizontalInterval(),
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade300),
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  minX: 0,
                  maxX: (spots.length - 1).toDouble(),
                  minY: _getMinY(spots),
                  maxY: _getMaxY(spots),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Theme.of(context).primaryColor,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final date = _getDateForIndex(spot.x.toInt());
                          final value = spot.y.toStringAsFixed(1);
                          return LineTooltipItem(
                            '${DateFormat('MMM d').format(date)}\n$value ${widget.chartType == ChartType.volume ? 'kg' : 'kg'}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _buildVolumeSpots() {
    if (widget.volumeHistory == null) return [];

    return widget.volumeHistory!.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.volume);
    }).toList();
  }

  List<FlSpot> _buildWeightSpots() {
    if (widget.weightHistory == null) return [];

    return widget.weightHistory!.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();
  }

  Widget _buildBottomTitle(int index) {
    final date = _getDateForIndex(index);

    // Show date for first, last, and middle points
    if (index == 0 ||
        index == _getDataLength() - 1 ||
        index == _getDataLength() ~/ 2) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          DateFormat('M/d').format(date),
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
          ),
        ),
      );
    }

    return const SizedBox();
  }

  DateTime _getDateForIndex(int index) {
    if (widget.chartType == ChartType.volume) {
      return widget.volumeHistory![index].date;
    } else {
      return widget.weightHistory![index].date;
    }
  }

  int _getDataLength() {
    return widget.chartType == ChartType.volume
        ? (widget.volumeHistory?.length ?? 0)
        : (widget.weightHistory?.length ?? 0);
  }

  double _getMinY(List<FlSpot> spots) {
    if (spots.isEmpty) return 0;
    final minValue = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    return (minValue * 0.9).floorToDouble();
  }

  double _getMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 100;
    final maxValue = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    return (maxValue * 1.1).ceilToDouble();
  }

  double _getHorizontalInterval() {
    if (widget.chartType == ChartType.volume && widget.volumeHistory != null) {
      final maxVolume = widget.volumeHistory!
          .map((v) => v.volume)
          .reduce((a, b) => a > b ? a : b);
      return (maxVolume / 5).ceilToDouble();
    } else if (widget.weightHistory != null) {
      final maxWeight = widget.weightHistory!
          .map((w) => w.weight)
          .reduce((a, b) => a > b ? a : b);
      return (maxWeight / 5).ceilToDouble();
    }
    return 20;
  }

  Widget _buildLegend() {
    final trend = _calculateTrend();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.chartType == ChartType.volume
                  ? 'Total Volume'
                  : 'Max Weight',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        Row(
          children: [
            Icon(
              trend > 0 ? Icons.trending_up : Icons.trending_down,
              size: 16,
              color: trend > 0 ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 4),
            Text(
              '${trend > 0 ? '+' : ''}${trend.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: trend > 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _calculateTrend() {
    if (_getDataLength() < 2) return 0;

    final first = widget.chartType == ChartType.volume
        ? widget.volumeHistory!.first.volume
        : widget.weightHistory!.first.weight;

    final last = widget.chartType == ChartType.volume
        ? widget.volumeHistory!.last.volume
        : widget.weightHistory!.last.weight;

    if (first == 0) return 0;
    return ((last - first) / first * 100);
  }

  Widget _buildEmptyState() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Data Available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start logging workouts to see your progression',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
