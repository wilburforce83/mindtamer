import 'package:flutter/material.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/pixel_button.dart';
import '../widgets/pixel_slider.dart';
import 'package:intl/intl.dart';
import 'package:mindtamer/features/mood/data/mood_repository.dart';
import 'package:mindtamer/features/mood/models/mood_entry.dart';
import 'package:mindtamer/features/mood/ui/mood_analytics_screen.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});
  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  final labels = const {
    MoodMetric.energy: 'Energy',
    MoodMetric.stress: 'Stress',
    MoodMetric.focus: 'Focus',
    MoodMetric.mood: 'Mood',
    MoodMetric.sleepQuality: 'Sleep Quality',
    MoodMetric.socialConnection: 'Social Connection',
  };

  final values = <MoodMetric, int>{
    for (final m in MoodMetric.values) m: 50,
  };
  bool _cooldown = false;

  Widget _sliderRow(MoodMetric m) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              labels[m]!,
              style: () {
                final base = Theme.of(context).textTheme.titleMedium;
                final baseSize = base?.fontSize ?? 14;
                return base?.copyWith(fontSize: baseSize * 0.6);
              }(),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: PixelSlider(
                    value: values[m]!,
                    onChanged: (v) => setState(() => values[m] = v),
                    showValue: false,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(width: 40, child: Text(values[m]!.toString())),
              ],
            ),
          ],
        ),
      );

  Future<void> _record() async {
    if (_cooldown) return;
    await MoodRepository.addSnapshot({for (final e in values.entries) e.key: e.value});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mood recorded')));
    setState(() {
      _cooldown = true;
    });
    await Future.delayed(const Duration(seconds: 10));
    if (!mounted) return;
    setState(() {
      _cooldown = false;
    });
  }

  Map<String, double> _today() => MoodRepository.dailyAverage(DateTime.now());
  Map<String, double> _avg7() => MoodRepository.trailingAvg(7);
  Map<String, double> _avg30() => MoodRepository.trailingAvg(30);
  int _todayCount() {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    final to = from.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));
    return MoodRepository.inRange(from, to).length;
  }

  DateTime? _lastTime() => MoodRepository.all().isEmpty ? null : MoodRepository.all().last.timestamp;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('HH:mm');
    final today = _today();
    final a7 = _avg7();
    final a30 = _avg30();
    final count = _todayCount();
    final last = _lastTime();
    // Small text style to match slider labels
    final TextStyle labelSmall = () {
      final base = Theme.of(context).textTheme.titleMedium;
      final baseSize = base?.fontSize ?? 14;
      return (base?.copyWith(fontSize: baseSize * 0.6)) ?? const TextStyle(fontSize: 10);
    }();

    Widget tile(String key, String label) {
      double valOf(Map<String, double> m) => (m[key] ?? double.nan);
      String fmt(double v) => v.isNaN ? '-' : v.toStringAsFixed(0);
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: labelSmall),
              const SizedBox(height: 4),
              Text('Today: ${fmt(valOf(today))}', style: labelSmall),
              Text('7d: ${fmt(valOf(a7))}', style: labelSmall),
              Text('30d: ${fmt(valOf(a30))}', style: labelSmall),
            ],
          ),
        ),
      );
    }

    return GameScaffold(
      title: 'Mood',
      padding: const EdgeInsets.all(12),
      body: ListView(
        children: [
          for (final m in MoodMetric.values) _sliderRow(m),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: PixelButton(
                  onPressed: _cooldown ? null : _record,
                  label: _cooldown ? 'Mood recorded' : 'Record Mood',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stats grid: Row1 (Energy/Stress), Row2 (Focus/Mood), Row3 (Sleep full), Row4 (Social full)
          Column(
            children: [
              Row(children: [
                Expanded(child: tile('energy', 'Energy')),
                const SizedBox(width: 8),
                Expanded(child: tile('stress', 'Stress')),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: tile('focus', 'Focus')),
                const SizedBox(width: 8),
                Expanded(child: tile('mood', 'Mood')),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: tile('sleepQuality', 'Sleep Quality')),
                const SizedBox(width: 8),
                Expanded(child: tile('socialConnection', 'Social')),
              ]),
            ],
          ),
          const SizedBox(height: 8),
          Text('Today: $count snapshots${last != null ? ' • last at ${df.format(last.toLocal())}' : ''}', style: labelSmall),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: PixelButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MoodAnalyticsScreen())),
              label: 'View analytics →',
            ),
          ),
          const SizedBox(height: 8),
          const Text('Tip: you can record multiple snapshots per day. Charts use a 7-day moving average and show time-of-day patterns.'),
        ],
      ),
    );
  }
}
