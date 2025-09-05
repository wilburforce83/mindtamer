import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/hive/boxes.dart';
import '../../../data/models/player_profile.dart';
import 'package:hive/hive.dart';

class CharacterSetupScreen extends StatefulWidget {
  const CharacterSetupScreen({super.key});

  @override
  State<CharacterSetupScreen> createState() => _CharacterSetupScreenState();
}

class _CharacterSetupScreenState extends State<CharacterSetupScreen> {
  final _name = TextEditingController();
  String? _diagnosis;
  String? _classKey;
  bool _classAuto = true; // whether class is following diagnosis suggestion

  final List<String> _diagnoses = const [
    'ADHD','Autism','Anxiety','Depression','Bipolar','PTSD','OCD','OCPD','BPD','Dyslexia','Dyscalculia','Dysgraphia','Dyspraxia','Tourette','SPD','ASD','GAD','Panic Disorder','Social Anxiety','PMDD','PME'
  ];

  final List<String> _classes = const [
    'Sage','Warden','Trickster','Seer','Artificer','Empath','Sentinel','Oracle','Shadow','Alchemist'
  ];

  String _suggestClass(String dx) {
    switch (dx) {
      case 'ADHD': return 'Trickster';
      case 'Autism': return 'Sage';
      case 'Anxiety': return 'Sentinel';
      case 'Depression': return 'Warden';
      case 'Bipolar': return 'Alchemist';
      case 'PTSD': return 'Shadow';
      case 'OCD': return 'Oracle';
      case 'Dyslexia': return 'Artificer';
      case 'Dyspraxia': return 'Empath';
      case 'Tourette': return 'Seer';
      default: return 'Sage';
    }
  }

  Map<String, int> _classPerk(String cls) {
    switch (cls) {
      case 'Warden':
        return const {'hp': 20, 'atk': 2, 'spd': 0, 'spirit': 2};
      case 'Trickster':
        return const {'hp': 10, 'atk': 4, 'spd': 6, 'spirit': 0};
      case 'Sage':
        return const {'hp': 12, 'atk': 0, 'spd': 2, 'spirit': 6};
      case 'Sentinel':
        return const {'hp': 16, 'atk': 3, 'spd': 1, 'spirit': 2};
      case 'Seer':
        return const {'hp': 12, 'atk': 1, 'spd': 3, 'spirit': 6};
      case 'Artificer':
        return const {'hp': 14, 'atk': 5, 'spd': 1, 'spirit': 2};
      case 'Empath':
        return const {'hp': 14, 'atk': 0, 'spd': 2, 'spirit': 6};
      case 'Oracle':
        return const {'hp': 12, 'atk': 2, 'spd': 2, 'spirit': 6};
      case 'Shadow':
        return const {'hp': 13, 'atk': 5, 'spd': 4, 'spirit': 0};
      case 'Alchemist':
        return const {'hp': 15, 'atk': 3, 'spd': 2, 'spirit': 3};
      default:
        return const {'hp': 12, 'atk': 2, 'spd': 2, 'spirit': 4};
    }
  }

  String _classBlurb(String cls) {
    switch (cls) {
      case 'Warden': return 'Stalwart guardian who endures and protects.';
      case 'Trickster': return 'Quick-witted rogue who thrives on agility.';
      case 'Sage': return 'Thoughtful seeker who turns insight into power.';
      case 'Sentinel': return 'Calm watchkeeper trained to hold the line.';
      case 'Seer': return 'Farsighted mystic who reads the flow of moments.';
      case 'Artificer': return 'Inventive mind channeling strength into craft.';
      case 'Empath': return 'Heart-led healer who amplifies spirit.';
      case 'Oracle': return 'Disciplined mind weaving order from chaos.';
      case 'Shadow': return 'Silent striker who moves where light fails.';
      case 'Alchemist': return 'Tireless tinkerer balancing change and control.';
      default: return 'Adventurer charting a path through the unknown.';
    }
  }

  String _startEffectText(String cls) {
    final p = _classPerk(cls);
    final parts = <String>[];
    if ((p['hp'] ?? 0) != 0) parts.add('+${p['hp']} hp');
    if ((p['atk'] ?? 0) != 0) parts.add('+${p['atk']} atk');
    if ((p['spd'] ?? 0) != 0) parts.add('+${p['spd']} spd');
    if ((p['spirit'] ?? 0) != 0) parts.add('+${p['spirit']} spirit');
    return parts.isEmpty ? 'No starting bonus' : 'Starts with ${parts.join(', ')}';
  }

  Future<void> _create() async {
    try {
      final name = _name.text.trim().isEmpty ? 'Adventurer' : _name.text.trim();
      final classKey = _classKey ?? 'Sage';
      // Determine source
      String classSource;
      if (_diagnosis == null || _diagnosis!.isEmpty) {
        classSource = 'manual';
      } else {
        final suggested = _suggestClass(_diagnosis!);
        classSource = classKey == suggested ? 'auto' : 'override';
      }
      // Ensure boxes are open (defensive in case of hot-reload)
      if (!Hive.isBoxOpen(BoxNames.profiles)) {
        await Hive.openBox<PlayerProfile>(BoxNames.profiles);
      }
      if (!Hive.isBoxOpen(BoxNames.playerMeta)) {
        await Hive.openBox(BoxNames.playerMeta);
      }
      // Save to profile box
      final id = 'p-${DateTime.now().millisecondsSinceEpoch}';
      final profile = PlayerProfile(id: id, classKey: classKey);
      await profileBox().put(id, profile);
      // Save meta: name, diagnosis, class source
      await playerMetaBox().putAll({
        'name': name,
        'classSource': classSource,
        'diagnosis': _diagnosis,
        'appearance': {'preset':'default'},
        'onboardingComplete': false,
      });
      if (!mounted) return;
      context.go('/onboarding');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Setup failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Create Your Character', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        Text('Class', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Mind Tamer will select your class based on primary diagnosis; you can override it by choosing a different class.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        const Text('Primary diagnosis (optional)'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _diagnosis,
          items: _diagnoses.map((d)=>DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: (v){
            setState((){
              _diagnosis = v;
              if (_classAuto && v != null) {
                _classKey = _suggestClass(v);
              }
            });
          },
          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Diagnosis'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _classKey,
          items: _classes.map((c)=>DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v)=>setState((){ _classKey=v; _classAuto=false; }),
          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Class'),
        ),
        if ((_classKey ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          Builder(builder: (context){
            final cls = _classKey ?? 'Sage';
            final blurb = _classBlurb(cls);
            final se = _startEffectText(cls);
            return Text('$blurb $se.', style: Theme.of(context).textTheme.bodySmall);
          }),
        ],
        const SizedBox(height: 16),
        Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          height: 80,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
          child: const Text('Appearance customization coming soon'),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _create,
          child: const Text('Create Character'),
        )
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Setup')),
      body: body,
    );
  }
}
