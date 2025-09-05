import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/hive/boxes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  void _next() {
    if (_index < 4) {
      _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } else {
      playerMetaBox().put('onboardingComplete', true);
      context.go('/character');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _Page(title: 'Welcome to MindTamer', body: 'Track your journey with a gentle RPG layer. Fight monsters, summon sprites, and grow over time.'),
      const _Page(title: 'Monsters & Sprites', body: 'Monsters form from negative patterns. Sprites are friendly constructs born from journal seeds. You collect and equip sprites to gain small bonuses and unique attacks.'),
      const _Page(title: 'Journaling', body: 'Write short entries. Tags and sentiment inform seed generation. Unlocks codex entries and encounters.'),
      const _Page(title: 'Moods & Medicine', body: 'Record quick mood snapshots through the day. Track medication plans and adherence. Charts build helpful insights over time.'),
      const _Page(title: 'You are ready', body: 'That’s it for now! You can revisit tips anytime from Settings.'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Getting Started')),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i)=>setState(()=>_index=i),
              children: pages,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Step ${_index+1} of ${pages.length}'),
                FilledButton(
                  onPressed: _next,
                  child: Text(_index < pages.length-1 ? 'Next' : 'Finish'),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _Page extends StatelessWidget {
  final String title;
  final String body;
  const _Page({required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
