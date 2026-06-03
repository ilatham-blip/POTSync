import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GeneralPlot extends StatelessWidget {
  final double height;
  final double width;
  final int timeint;
  final String ylabel;
  final String xlabel;
  final List<num> vals;

  const GeneralPlot({
    super.key,
    required this.width,
    required this.height,
    required this.vals,
    required this.ylabel,
    required this.xlabel,
    required this.timeint,
  });
 
  @override
  Widget build(BuildContext context) {
    if (vals.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: const Center(child: Text('No data')),
      );
    } else {
      return SizedBox(
        width: width,
        height: height,
        child: LineChart(LineChartData(
          titlesData: FlTitlesData(
            show: true,
            topTitles: AxisTitles(axisNameWidget: Text("")),
            rightTitles: AxisTitles(axisNameWidget: Text("")),
            bottomTitles: AxisTitles(axisNameWidget: Text(xlabel), sideTitles: SideTitles(showTitles: true, reservedSize: 30.0), axisNameSize: 30.0),
            leftTitles: AxisTitles(axisNameWidget: Text(ylabel), sideTitles: SideTitles(showTitles: true, reservedSize: 30.0), axisNameSize: 30.0)
          ),
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for(var (index, val) in vals.indexed)
                  FlSpot(index.toDouble()*timeint, val.toDouble()),
              ],
              isCurved: true,
              preventCurveOverShooting: true,
              barWidth: 4,
              color: Colors.blue,
            ),
          ],
        )
      ),
    );
  }}
}
class GeneralBarChart extends StatelessWidget {
  final List<double> vals;
  final List<String> labels;
  final double width;
  final double height;

  const GeneralBarChart({
    super.key,
    required this.vals,
    required this.labels,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (vals.isEmpty || labels.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: const Center(child: Text('No data')),
      );
    }

    // create bars from vals and labels
    final List<BarChartGroupData> barGroups = [];
    final colors = [Colors.orange, Colors.purple, Colors.blue];
    for (int i = 0; i < vals.length && i < labels.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: vals[i],
              color: i < colors.length ? colors[i] : Colors.grey,
              width: 30,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: BarChart(
        BarChartData(
          maxY: 10,
          minY: 0,
          barGroups: barGroups,
          titlesData: FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < labels.length) {
                    return Text(labels[idx], style: const TextStyle(fontSize: 12));
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 2,
                reservedSize: 40,
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 2,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.3),
                strokeWidth: 0.8,
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.black, width: 1),
          ),
        ),
      ),
    );
  }
}

class MultiSymptomPlot extends StatelessWidget {
  final List<FlSpot> dizziness;
  final List<FlSpot> fatigue;
  final List<FlSpot> hydration;
  final double width;
  final double height;
  final String timeframe;

  const MultiSymptomPlot({
    super.key,
    required this.dizziness,
    required this.fatigue,
    required this.hydration,
    required this.width,
    required this.height,
    required this.timeframe,
  });

  @override
  Widget build(BuildContext context) {
    final List<LineChartBarData> lines = [];

    LineChartBarData makeLine(List<FlSpot> spots, Color color) {
      return LineChartBarData(
        spots: spots,
        isCurved: true,
        preventCurveOverShooting: true,
        color: color,
        barWidth: 3,
        dotData: FlDotData(show: true),
      );
    }

    if (dizziness.isNotEmpty) {
      lines.add(makeLine(dizziness, Colors.purple));
    }
    if (fatigue.isNotEmpty) {
      lines.add(makeLine(fatigue, Colors.orange));
    }
    if (hydration.isNotEmpty) {
      lines.add(makeLine(hydration, Colors.blue));
    }

    if (lines.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: const Center(child: Text('No data')),
      );
    }

    // Configure bounds and labels based on the timeframe
    double minX = 0;
    double maxX = 6;
    double interval = 1;
    String bottomAxisTitle = 'Time (Days)';

    if (timeframe == 'day') {
      minX = 0;
      maxX = 24;
      interval = 6;
      bottomAxisTitle = 'Time of Day';
    } else if (timeframe == 'week') {
      minX = 0;
      maxX = 6;
      interval = 1;
      bottomAxisTitle = 'Day of Week';
    } else if (timeframe == 'month') {
      minX = 0;
      maxX = 29;
      interval = 5;
      bottomAxisTitle = 'Date';
    }

    // Generate dynamic weekday labels for the last 7 days
    final now = DateTime.now();
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final List<String> weekLabels = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      return dayNames[date.weekday - 1];
    });

    // Generate dynamic date labels for the last 30 days
    final List<String> monthLabels = List.generate(30, (i) {
      final date = now.subtract(Duration(days: 29 - i));
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${monthNames[date.month - 1]} ${date.day}';
    });

    return SizedBox(
      width: width,
      height: height,
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: 0,
          maxY: 10,
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: true),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              axisNameWidget: Text(
                bottomAxisTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
              axisNameSize: 22,
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  final idx = value.round();
                  if (timeframe == 'day') {
                    if (idx % 6 != 0) return const Text('');
                    switch (idx) {
                      case 0: return const Text('12 AM', style: TextStyle(fontSize: 9));
                      case 6: return const Text('6 AM', style: TextStyle(fontSize: 9));
                      case 12: return const Text('12 PM', style: TextStyle(fontSize: 9));
                      case 18: return const Text('6 PM', style: TextStyle(fontSize: 9));
                      case 24: return const Text('12 AM', style: TextStyle(fontSize: 9));
                      default: return const Text('');
                    }
                  } else if (timeframe == 'week') {
                    if (idx >= 0 && idx < 7) {
                      return Text(weekLabels[idx], style: const TextStyle(fontSize: 9));
                    }
                  } else if (timeframe == 'month') {
                    if (idx >= 0 && idx < 30) {
                      if (idx % 5 == 0 || idx == 29) {
                        return Text(monthLabels[idx], style: const TextStyle(fontSize: 9));
                      }
                    }
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: const AxisTitles(
              axisNameWidget: Text(
                'Severity Level',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
              axisNameSize: 22,
              sideTitles: SideTitles(
                showTitles: true,
                interval: 2,
                reservedSize: 30,
              ),
            ),
          ),
          lineBarsData: lines,
        ),
      ),
    );
  }
}
