import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:heartbeat/app_theme.dart';
import 'package:heartbeat/app_state.dart';
import 'package:heartbeat/widgets/chart.dart'; // where GeneralPlot / bar chart live
import 'package:provider/provider.dart';

class TrackerPage extends StatefulWidget {
  const TrackerPage({super.key});

  @override
  State<TrackerPage> createState() => _TrackerPage();
}

class _TrackerPage extends State<TrackerPage> {
  bool _showDizziness = true;
  bool _showFatigue = true;
  bool _showHydration = true;
  String _selectedTimeframe = 'week';

  List<FlSpot> _getAggregatedSpots({
    required MyAppState appState,
    required String symptomType,
    required String timeframe,
  }) {
    final now = DateTime.now();
    final Map<int, List<double>> binData = {};

    for (final entry in appState.morningEntries) {
      final diff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(entry.dateTime.year, entry.dateTime.month, entry.dateTime.day))
          .inDays;
      int bin;
      if (timeframe == 'day' && diff == 0) {
        bin = entry.dateTime.hour;
      } else if (timeframe == 'week' && diff >= 0 && diff < 7) {
        bin = 6 - diff;
      } else if (timeframe == 'month' && diff >= 0 && diff < 30) {
        bin = 29 - diff;
      } else {
        continue;
      }

      if (symptomType == 'dizziness') {
        final val = (entry.dizziness.index / 3.0) * 10.0;
        binData.putIfAbsent(bin, () => []).add(val);
      } else if (symptomType == 'fatigue') {
        final val = (entry.abnormalTiredness.index / 3.0) * 10.0;
        binData.putIfAbsent(bin, () => []).add(val);
      }
    }

    for (final entry in appState.eveningEntries) {
      final diff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(entry.dateTime.year, entry.dateTime.month, entry.dateTime.day))
          .inDays;
      int bin;
      if (timeframe == 'day' && diff == 0) {
        bin = entry.dateTime.hour;
      } else if (timeframe == 'week' && diff >= 0 && diff < 7) {
        bin = 6 - diff;
      } else if (timeframe == 'month' && diff >= 0 && diff < 30) {
        bin = 29 - diff;
      } else {
        continue;
      }

      if (symptomType == 'dizziness') {
        final val = (entry.dizziness.index / 3.0) * 10.0;
        binData.putIfAbsent(bin, () => []).add(val);
      } else if (symptomType == 'fatigue') {
        final val = (entry.abnormalTiredness.index / 3.0) * 10.0;
        binData.putIfAbsent(bin, () => []).add(val);
      }
    }

    for (final entry in appState.episodeEntries) {
      final diff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(entry.dateTime.year, entry.dateTime.month, entry.dateTime.day))
          .inDays;
      int bin;
      if (timeframe == 'day' && diff == 0) {
        bin = entry.dateTime.hour;
      } else if (timeframe == 'week' && diff >= 0 && diff < 7) {
        bin = 6 - diff;
      } else if (timeframe == 'month' && diff >= 0 && diff < 30) {
        bin = 29 - diff;
      } else {
        continue;
      }

      if (symptomType == 'dizziness') {
        final dizzinessVal = entry.scores['Dizziness when standing'] ??
            entry.scores['Dizziness in upright position or while standing up'] ??
            entry.scores['Dizziness, feeling that you are going to faint'];
        if (dizzinessVal != null) {
          binData.putIfAbsent(bin, () => []).add(dizzinessVal);
        }
      } else if (symptomType == 'fatigue') {
        final fatigueVal = entry.scores['Difficulty concentrating'] ?? entry.scores['Fatigue'];
        if (fatigueVal != null) {
          binData.putIfAbsent(bin, () => []).add(fatigueVal);
        }
      } else if (symptomType == 'hydration') {
        final hydrationVal = entry.scores['Difficulty breathing'] ?? entry.scores['Hydration'];
        if (hydrationVal != null) {
          binData.putIfAbsent(bin, () => []).add(hydrationVal);
        }
      }
    }

    for (final entry in appState.lifestyleEntries) {
      final diff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(entry.date.year, entry.date.month, entry.date.day))
          .inDays;
      int bin;
      if (timeframe == 'day' && diff == 0) {
        bin = 12;
      } else if (timeframe == 'week' && diff >= 0 && diff < 7) {
        bin = 6 - diff;
      } else if (timeframe == 'month' && diff >= 0 && diff < 30) {
        bin = 29 - diff;
      } else {
        continue;
      }

      if (symptomType == 'hydration') {
        final val = (entry.waterLitres / 5.0) * 10.0;
        binData.putIfAbsent(bin, () => []).add(val);
      }
    }

    final List<FlSpot> spots = [];
    final sortedBins = binData.keys.toList()..sort();
    for (final bin in sortedBins) {
      final vals = binData[bin]!;
      if (vals.isNotEmpty) {
        final avg = vals.reduce((a, b) => a + b) / vals.length;
        spots.add(FlSpot(bin.toDouble(), avg));
      }
    }

    if (spots.isEmpty) {
      double fallbackVal = 0;
      if (symptomType == 'dizziness') {
        fallbackVal = appState.combinedDizzinessAvg;
      } else if (symptomType == 'fatigue') {
        fallbackVal = appState.combinedFatigueAvg;
      } else if (symptomType == 'hydration') {
        fallbackVal = appState.combinedHydrationAvg;
      }

      if (fallbackVal > 0) {
        spots.add(FlSpot(
          timeframe == 'day' ? 12.0 : (timeframe == 'week' ? 6.0 : 29.0),
          fallbackVal,
        ));
      }
    }

    return spots;
  }

  // Helper to compute trend direction from a numeric series
  Map<String, dynamic> computeTrend(List<double> series) {
    if (series.isEmpty) {
      return {
        'text': 'No data',
        'icon': Icons.remove,
        'color': Colors.grey,
      };
    }

    // use last 3 vs previous 3 where possible
    int n = series.length;
    double recentAvg;
    double prevAvg;
    if (n < 2) {
      recentAvg = series.last;
      prevAvg = series.first;
    } else if (n < 4) {
      recentAvg = series.sublist(n - 1).reduce((a, b) => a + b) / (n - (n - 1));
      prevAvg = series.sublist(0, n - 1).reduce((a, b) => a + b) / (n - 1);
    } else {
      final recentSlice = series.sublist(n - 3, n);
      final prevSlice = series.sublist(n - 6, n - 3);
      recentAvg = recentSlice.reduce((a, b) => a + b) / recentSlice.length;
      prevAvg = prevSlice.reduce((a, b) => a + b) / prevSlice.length;
    }

    final diff = recentAvg - prevAvg;
    if (diff.abs() < 0.5) {
      return {'text': 'Stable', 'icon': Icons.trending_flat, 'color': Colors.blue};
    } else if (diff > 0) {
      return {'text': 'Increasing trend', 'icon': Icons.trending_up, 'color': Colors.red};
    } else {
      return {'text': 'Decreasing trend', 'icon': Icons.trending_down, 'color': Colors.green};
    }
  }

  // Generate health insights based on abnormal parameters
  List<Map<String, dynamic>> generateHealthInsights(MyAppState appState) {
    final insights = <Map<String, dynamic>>[];
    
    // Define normal/abnormal thresholds (on 0-10 scale)
    const double dizzinessThreshold = 5.0;
    const double fatigueThreshold = 5.0;
    const double hydrationThreshold = 4.0; // Low hydration is concerning
    
    // Check Dizziness
    if (appState.combinedDizzinessAvg > dizzinessThreshold) {
      insights.add({
        'title': 'Elevated Dizziness',
        'message': 'You\'re experiencing elevated dizziness levels (${appState.combinedDizzinessAvg.toStringAsFixed(1)}/10). Please discuss this with your doctor.',
        'icon': Icons.error_outline,
        'backgroundColor': const Color(0xFFFFF3E0),
        'iconColor': Colors.orange,
        'severity': 'warning',
      });
    }
    
    // Check Fatigue
    if (appState.combinedFatigueAvg > fatigueThreshold) {
      insights.add({
        'title': 'High Fatigue Levels',
        'message': 'You\'ve reported high fatigue levels (${appState.combinedFatigueAvg.toStringAsFixed(1)}/10). Consider increasing rest and hydration.',
        'icon': Icons.local_fire_department,
        'backgroundColor': const Color(0xFFFFEBEE),
        'iconColor': Colors.red,
        'severity': 'warning',
      });
    }
    
    // Check Hydration
    if (appState.combinedHydrationAvg < hydrationThreshold) {
      insights.add({
        'title': 'Low Hydration Status',
        'message': 'Your hydration intake appears low (${appState.combinedHydrationAvg.toStringAsFixed(1)}/10). Try to drink more water throughout the day.',
        'icon': Icons.water_drop,
        'backgroundColor': const Color(0xFFE3F2FD),
        'iconColor': Colors.blue,
        'severity': 'info',
      });
    }
    
    // Check for combined concerns
    final abnormalCount = (appState.combinedDizzinessAvg > dizzinessThreshold ? 1 : 0) +
                          (appState.combinedFatigueAvg > fatigueThreshold ? 1 : 0) +
                          (appState.combinedHydrationAvg < hydrationThreshold ? 1 : 0);
    
    if (abnormalCount >= 2) {
      insights.add({
        'title': 'Multiple Symptom Concerns',
        'message': 'Multiple health metrics are outside normal ranges. Consider scheduling a consultation with your healthcare provider.',
        'icon': Icons.health_and_safety,
        'backgroundColor': const Color(0xFFF3E5F5),
        'iconColor': Colors.purple,
        'severity': 'critical',
      });
    }
    
    return insights;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<MyAppState>(context, listen: true);
    final insights = generateHealthInsights(appState);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBrandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Health Insights',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth * 0.9;
          final height = constraints.maxHeight;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  

                  // Vital Measurements
                  _SectionCard(
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Vital Measurements',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No vital measurements recorded yet.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Health Insights alert - Dynamic
                  if (insights.isEmpty)
                    _SectionCard(
                      width: width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Health Insights',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'All Systems Normal',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Your health metrics are within normal ranges.',
                                        style: TextStyle(
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _SectionCard(
                      width: width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Health Insights',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...insights.map((insight) => 
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: insight['backgroundColor'] as Color,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      insight['icon'] as IconData,
                                      color: insight['iconColor'] as Color,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            insight['title'] as String,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            insight['message'] as String,
                                            style: const TextStyle(
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).toList(),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Symptom trends cards (Fatigue, Dizziness, Hydration)
                  _SectionCard(
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Symptom Trends',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Builder(builder: (ctx) {
                          final t = computeTrend(appState.fatigueSeries);
                          return _SymptomTrendTile(
                            title: 'Fatigue',
                            averageText: 'Avg: ${appState.combinedFatigueAvg.toStringAsFixed(1)}/10',
                            trendText: t['text'] as String,
                            icon: t['icon'] as IconData,
                            iconColor: t['color'] as Color,
                          );
                        }),
                        const SizedBox(height: 8),
                        Builder(builder: (ctx) {
                          final t = computeTrend(appState.dizziness);
                          return _SymptomTrendTile(
                            title: 'Dizziness',
                            averageText: 'Avg: ${appState.combinedDizzinessAvg.toStringAsFixed(1)}/10',
                            trendText: t['text'] as String,
                            icon: t['icon'] as IconData,
                            iconColor: t['color'] as Color,
                          );
                        }),
                        const SizedBox(height: 8),
                        Builder(builder: (ctx) {
                          final t = computeTrend(appState.hydrationSeries);
                          return _SymptomTrendTile(
                            title: 'Hydration',
                            averageText: 'Avg: ${appState.combinedHydrationAvg.toStringAsFixed(1)}/10',
                            trendText: t['text'] as String,
                            icon: t['icon'] as IconData,
                            iconColor: t['color'] as Color,
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Average Symptom Comparison bar chart
                  _SectionCard(
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Average Symptom Comparison',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: width,
                          height: height / 3,
                          child: GeneralBarChart(
                             width: width,
                      height: height / 3,    
                            // implement this in chart.dart similar to GeneralPlot
                            vals: [
                              appState.fatigueAvg,
                              appState.dizzinessAvg,
                              appState.hydrationAvg,
                            ],
                            labels: const ['Fatigue', 'Dizziness', 'Hydration'],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Symptom levels over time (multi-line chart)
                  _SectionCard(
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Symptom Levels Over Time',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ChoiceChip(
                              label: const Text('Day'),
                              selected: _selectedTimeframe == 'day',
                              showCheckmark: false,
                              onSelected: (v) {
                                if (v) setState(() => _selectedTimeframe = 'day');
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Week'),
                              selected: _selectedTimeframe == 'week',
                              showCheckmark: false,
                              onSelected: (v) {
                                if (v) setState(() => _selectedTimeframe = 'week');
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Month'),
                              selected: _selectedTimeframe == 'month',
                              showCheckmark: false,
                              onSelected: (v) {
                                if (v) setState(() => _selectedTimeframe = 'month');
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Dizziness'),
                              selected: _showDizziness,
                              showCheckmark: false,
                              avatar: const CircleAvatar(backgroundColor: Colors.purple, radius: 6),
                              onSelected: (v) => setState(() => _showDizziness = v),
                            ),
                            ChoiceChip(
                              label: const Text('Fatigue'),
                              selected: _showFatigue,
                              showCheckmark: false,
                              avatar: const CircleAvatar(backgroundColor: Colors.orange, radius: 6),
                              onSelected: (v) => setState(() => _showFatigue = v),
                            ),
                            ChoiceChip(
                              label: const Text('Hydration'),
                              selected: _showHydration,
                              showCheckmark: false,
                              avatar: const CircleAvatar(backgroundColor: Colors.blue, radius: 6),
                              onSelected: (v) => setState(() => _showHydration = v),
                            ),
                            TextButton(
                              onPressed: () => setState(() { _showDizziness = true; _showFatigue = true; _showHydration = true; }),
                              child: const Text('All'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: width,
                          height: height / 3,
                          child: MultiSymptomPlot(
                                width: constraints.maxWidth * 0.9,
                                height: constraints.maxHeight / 3,
                                dizziness: _showDizziness ? _getAggregatedSpots(appState: appState, symptomType: 'dizziness', timeframe: _selectedTimeframe) : const [],
                                fatigue: _showFatigue ? _getAggregatedSpots(appState: appState, symptomType: 'fatigue', timeframe: _selectedTimeframe) : const [],
                                hydration: _showHydration ? _getAggregatedSpots(appState: appState, symptomType: 'hydration', timeframe: _selectedTimeframe) : const [],
                                timeframe: _selectedTimeframe,
                              ),
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
      ),
    );
  }
}

/// Generic card container used throughout the page
class _SectionCard extends StatelessWidget {
  final double width;
  final Widget child;

  const _SectionCard({
    required this.width,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _SymptomTrendTile extends StatelessWidget {
  final String title;
  final String averageText;
  final String trendText;
  final IconData icon;
  final Color iconColor;

  const _SymptomTrendTile({
    required this.title,
    required this.averageText,
    required this.trendText,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  averageText,
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  trendText,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          Icon(
            icon,
            color: iconColor,
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
