import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../../mood/data/mood_repository.dart';

class MoodAnalyticsScreen extends StatefulWidget {
  const MoodAnalyticsScreen({super.key});

  @override
  State<MoodAnalyticsScreen> createState() => _MoodAnalyticsScreenState();
}

class _MoodAnalyticsScreenState extends State<MoodAnalyticsScreen> {
  String metric = 'mood';

  // Morning: 5–11, Day: 12–17, Night: 18–23 and 0–4
  List<double> _mdnAverages(String metric, {int days = 30}) {
    final now = DateTime.now();
    final from = now.subtract(Duration(days: days));
    final entries = MoodRepository.inRange(from, now);
    final sums = List<int>.filled(3, 0);
    final counts = List<int>.filled(3, 0);
    for (final e in entries) {
      final h = e.timestamp.hour;
      int slot;
      if (h >= 5 && h <= 11) {
        slot = 0; // morning
      } else if (h >= 12 && h <= 17) {
        slot = 1; // day
      } else {
        slot = 2; // night
      }
      final v = (e.values[metric] ?? 0).clamp(0, 100);
      sums[slot] += v;
      counts[slot]++;
    }
    return List<double>.generate(3, (i) => counts[i] == 0 ? 0 : sums[i] / counts[i]);
  }

  Widget _mdnChart(BuildContext context, List<double> avgs, {String? heading}) {
    final color = Theme.of(context).colorScheme.primary;
    final bars = <BarChartGroupData>[];
    for (int i = 0; i < 3; i++) {
      bars.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: avgs[i],
            width: 18,
            color: color,
            borderRadius: BorderRadius.zero, // squared ends
          ),
        ],
      ));
    }
    Widget bottomTitle(double value, TitleMeta meta) {
      final labels = ['morn', 'day', 'night'];
      final i = value.toInt();
      final txt = (i >= 0 && i < labels.length) ? labels[i] : '';
      final style = (Theme.of(context).textTheme.bodySmall ?? const TextStyle())
          .copyWith(fontSize: 10);
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 4,
        child: Text(txt, style: style, maxLines: 1, softWrap: false),
      );
    }
    Widget leftTitle(double value, TitleMeta meta) {
      final v = value.toInt();
      if (v == 0 || v == 50 || v == 100) {
        final style = (Theme.of(context).textTheme.bodySmall ?? const TextStyle())
            .copyWith(fontSize: 7);
        return SideTitleWidget(
          axisSide: meta.axisSide,
          space: 2,
          child: Text(v == 100 ? '99' : '$v', style: style, maxLines: 1, softWrap: false),
        );
      }
      return const SizedBox.shrink();
    }
    final chart = SizedBox(
      height: 140,
      child: BarChart(BarChartData(
        minY: 0,
        maxY: 100,
        barGroups: bars,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: true),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: bottomTitle)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22, interval: 50, getTitlesWidget: leftTitle)),
        ),
      )),
    );
    if (heading == null) return chart;
    final small = (Theme.of(context).textTheme.bodySmall ?? const TextStyle()).copyWith(fontSize: 11);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(heading, style: small), const SizedBox(height: 6), chart],
    );
  }

  List<FlSpot> _dailyAvgSeries(String metric, {int days = 30}) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    final spots = <FlSpot>[];
    for (int i = 0; i < days; i++) {
      final day = start.add(Duration(days: i));
      final from = DateTime(day.year, day.month, day.day);
      final to = from.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));
      final entries = MoodRepository.inRange(from, to);
      if (entries.isEmpty) {
        spots.add(FlSpot(i.toDouble(), double.nan));
        continue;
      }
      var sum = 0; var count = 0;
      for (final e in entries) { sum += (e.values[metric] ?? 0); count++; }
      final avg = count == 0 ? double.nan : sum / count;
      spots.add(FlSpot(i.toDouble(), avg));
    }
    return spots;
  }

  List<FlSpot> _movingAverage(List<FlSpot> input, int window) {
    final out = <FlSpot>[];
    for (int i = 0; i < input.length; i++) {
      double sum = 0;
      int cnt = 0;
      for (int j = math.max(0, i - window + 1); j <= i; j++) {
        final v = input[j].y;
        if (!v.isNaN) {
          sum += v;
          cnt++;
        }
      }
      final avg = cnt == 0 ? double.nan : sum / cnt;
      out.add(FlSpot(input[i].x, avg));
    }
    return out;
  }

  // Removed unused _avgRow

  @override
  Widget build(BuildContext context) {
    const labels = {
      'energy': 'Energy',
      'stress': 'Stress',
      'focus': 'Focus',
      'mood': 'Mood',
      'sleepQuality': 'Sleep Quality',
      'socialConnection': 'Social Connection',
    };

    final small = Theme.of(context).textTheme.bodySmall;

    // Precompute averages for current metric for 7, 30, 90 days
    final mdn7 = _mdnAverages(metric, days: 7);
    final mdn30 = _mdnAverages(metric, days: 30);
    final mdn90 = _mdnAverages(metric, days: 90);
    final daily30 = _dailyAvgSeries(metric, days: 30);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Metric picker only (no days dropdown)
            DropdownButton<String>(
              value: metric,
              items: labels.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: small)))
                  .toList(),
              onChanged: (v) => setState(() => metric = v!),
            ),
            const SizedBox(height: 16),
            _mdnChart(context, mdn7, heading: '7-day (morn/day/night)'),
            const SizedBox(height: 18),
            _mdnChart(context, mdn30, heading: '30-day (morn/day/night)'),
            const SizedBox(height: 18),
            _mdnChart(context, mdn90, heading: '90-day (morn/day/night)'),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text('Daily average (last 30 days)', style: small),
            const SizedBox(height: 6),
            SizedBox(
              height: 140,
              child: LineChart(LineChartData(
                minY: 0, maxY: 100,
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: daily30.where((s) => !s.y.isNaN).toList(),
                    isCurved: true,
                    dotData: const FlDotData(show: false),
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 2,
                  ),
                  LineChartBarData(
                    spots: _movingAverage(daily30, 7)
                        .where((s) => !s.y.isNaN)
                        .toList(),
                    isCurved: true,
                    dotData: const FlDotData(show: false),
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                    barWidth: 2,
                  ),
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }
}
