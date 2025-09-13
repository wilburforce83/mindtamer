import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/hive/boxes.dart';
import '../../../data/models/player_profile.dart';
import 'package:hive/hive.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../../../game/services/player_image_service.dart';

class CharacterSetupScreen extends StatefulWidget {
  const CharacterSetupScreen({super.key});

  @override
  State<CharacterSetupScreen> createState() => _CharacterSetupScreenState();
}

class _CharacterSetupScreenState extends State<CharacterSetupScreen> {
  final _name = TextEditingController();
  String? _diagnosis;
  String? _classKey;
  String _gender = 'm'; // m | f
  String _hairBase = '#6B3F2A'; // hex strings
  String _skinBase = '#E0B6A1';
  bool _classAuto = true; // whether class is following diagnosis suggestion
  int _step = 0; // 0: choose class, 1: customize
  ui.Image? _preview;

  final List<String> _diagnoses = const [
    'ADHD','Autism','Anxiety','Depression','Bipolar','PTSD','OCD','OCPD','BPD','Dyslexia','Dyscalculia','Dysgraphia','Dyspraxia','Tourette','SPD','ASD','GAD','Panic Disorder','Social Anxiety','PMDD','PME'
  ];

  final List<String> _classes = const [
    'Sage','Warden','Trickster','Seer','Artificer','Empath','Sentinel','Oracle','Shadow','Alchemist'
  ];

  final List<String> _hairOptions = const [
    '#1C1C1C', // black
    '#4B2E1E', // dark brown
    '#6B3F2A', // brown
    '#8C2A1C', // auburn
    '#C22F2F', // red
    '#D8B45B', // blonde
    '#EAE5D6', // platinum
    '#2C5EA8', // blue
    '#2C8A5E', // green
    '#6B2CA8', // purple
  ];

  final List<String> _skinOptions = const [
    '#F2D6C2', '#E0B6A1', '#C58C6A', '#A1664A', '#8D5524', '#5C3D2E'
  ];

  @override
  void initState() {
    super.initState();
    // Default class and randomized colors for an engaging first preview
    _classKey ??= 'Sage';
    final r = math.Random();
    _hairBase = _hairOptions[r.nextInt(_hairOptions.length)];
    _skinBase = _skinOptions[r.nextInt(_skinOptions.length)];
    _refreshPreview();
  }

  Future<void> _refreshPreview() async {
    final cls = _classKey ?? 'Sage';
    final asset = 'assets/images/players/${cls.toLowerCase()}_$_gender.png';
    ui.Image? img;
    try {
      final resolved = await PlayerImageService.resolveAssetPath(cls, _gender) ?? asset;
      img = await PlayerImageService().recolorAsset(
        assetPath: resolved,
        hairRamp6: PlayerImageService.makeRamp3(_hairBase),
        skinRamp6: PlayerImageService.makeRamp3(_skinBase),
        // Default to brown tones until weapon details exist
        weaponGlowRamp3: PlayerImageService.defaultWeaponGlowRamp3(),
      );
    } catch (_) {}
    if (!mounted) return;
    setState(() { _preview = img; });
  }

  String _classInfo(String cls) {
    switch (cls) {
      case 'Sage':
        return 'A thoughtful caster who channels insight into protective wards and clever buffs. Primarily magic; excels at team support and control.';
      case 'Warden':
        return 'Armored bulwark on the front line. Primarily melee; sturdy defenses and rallying buffs that keep allies standing.';
      case 'Trickster':
        return 'Fast and evasive striker who exploits openings. Primarily melee; thrives on debuffs and momentum.';
      case 'Seer':
        return 'Long-range oracle who reads the flow of battle. Primarily magic; crit-prone volleys and soft control.';
      case 'Artificer':
        return 'Inventor wielding runic tools and gadgets. Hybrid damage; mixes buffs with clever tricks and mid-range strikes.';
      case 'Empath':
        return 'Heart-led healer who radiates resilience. Primarily magic; reliable heals and uplifting buffs.';
      case 'Sentinel':
        return 'Disciplined defender with measured strikes. Primarily melee; counters, guards, and formation buffs.';
      case 'Oracle':
        return 'Order-bound caster who imposes structure. Primarily magic; debuffs, cleanses, and tempo control.';
      case 'Shadow':
        return 'Silent blade from the dark. Primarily melee; burst windows, bleeds, and weakening debuffs.';
      case 'Alchemist':
        return 'Tinkerer of volatile brews. Hybrid ranged; status effects, quick buffs, and opportunistic damage.';
      default:
        return 'Adaptable adventurer ready for anything.';
    }
  }

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
  // Class blurb and start effect text removed from the UI for now; keep perks for later use.

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
      final asset = 'assets/images/players/${classKey.toLowerCase()}_$_gender.png';
      await playerMetaBox().putAll({
        'name': name,
        'classSource': classSource,
        'diagnosis': _diagnosis,
        'class': classKey,
        'gender': _gender,
        'hairBase': _hairBase,
        'skinBase': _skinBase,
        'playerImageAsset': asset,
        'appearance': {
          'preset': 'custom',
          'hairBase': _hairBase,
          'skinBase': _skinBase,
          'gender': _gender,
        },
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
        Text('Create Your Character', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (_step == 0) ...[
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          Text('Class', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Mind Tamer may suggest a class based on your diagnosis; you can override it.', style: Theme.of(context).textTheme.bodySmall),
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
                  _refreshPreview();
                }
              });
            },
            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Diagnosis'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _classKey,
            items: _classes.map((c)=>DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v){ setState((){ _classKey=v; _classAuto=false; }); _refreshPreview(); },
            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Class'),
          ),
          const SizedBox(height: 12),
          Text('What gender do you identify with?', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Row(children: [
            ChoiceChip(label: const Text('Female'), selected: _gender=='f', onSelected: (_){ setState(()=> _gender='f'); _refreshPreview(); }),
            const SizedBox(width: 8),
            ChoiceChip(label: const Text('Male'), selected: _gender=='m', onSelected: (_){ setState(()=> _gender='m'); _refreshPreview(); }),
          ]),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (ctx, cts) {
            final w = cts.maxWidth;
            final imgSize = (w * 0.42).clamp(200.0, 280.0);
            final info = _classInfo(_classKey ?? 'Sage');
            final infoStyle = Theme.of(context).textTheme.bodySmall;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: imgSize,
                  height: imgSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
                  child: _preview != null
                      ? RawImage(
                          image: _preview,
                          filterQuality: FilterQuality.none,
                          fit: BoxFit.cover,
                          width: imgSize,
                          height: imgSize,
                        )
                      : Builder(builder: (ctx){
                          final cls = (_classKey ?? 'Sage');
                          final path = PlayerImageService.assetPathFor(cls, _gender);
                          return Image.asset(
                            path,
                            filterQuality: FilterQuality.none,
                            fit: BoxFit.cover,
                            width: imgSize,
                            height: imgSize,
                            errorBuilder: (_, __, ___)=> const Text('No preview'),
                          );
                        }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(info, style: infoStyle),
                ),
              ],
            );
          }),
          const SizedBox(height: 20),
          FilledButton(onPressed: ()=> setState(()=> _step=1), child: const Text('Customize')),
        ] else ...[
          Center(
            child: Container(
              width: 256,
              height: 256,
              alignment: Alignment.center,
              decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
              child: _preview != null
                  ? RawImage(
                      image: _preview,
                      filterQuality: FilterQuality.none,
                      fit: BoxFit.cover,
                      width: 256,
                      height: 256,
                    )
                  : Builder(builder: (ctx){
                      final cls = (_classKey ?? 'Sage');
                      final path = PlayerImageService.assetPathFor(cls, _gender);
                      return Image.asset(
                        path,
                        filterQuality: FilterQuality.none,
                        fit: BoxFit.cover,
                        width: 256,
                        height: 256,
                        errorBuilder: (_, __, ___)=> const Text('No preview'),
                      );
                    }),
            ),
          ),
          const SizedBox(height: 16),
          Text('Hair Color', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final hex in _hairOptions)
              _ColorChip(hex: hex, selected: _hairBase==hex, onTap: (){ setState(()=> _hairBase=hex); _refreshPreview(); }),
          ]),
          const SizedBox(height: 16),
          Text('Skin Tone', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final hex in _skinOptions)
              _ColorChip(hex: hex, selected: _skinBase==hex, onTap: (){ setState(()=> _skinBase=hex); _refreshPreview(); }),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            OutlinedButton(onPressed: ()=> setState(()=> _step=0), child: const Text('Back')),
            const Spacer(),
            FilledButton(onPressed: _create, child: const Text('Finish')),
          ]),
        ],
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Setup')),
      body: body,
    );
  }
}

class _ColorChip extends StatelessWidget {
  final String hex;
  final bool selected;
  final VoidCallback onTap;
  const _ColorChip({required this.hex, required this.selected, required this.onTap});
  Color _hex(String s){
    var h = s.startsWith('#') ? s.substring(1) : s;
    if (h.length==3) h = h.split('').map((c)=>'$c$c').join();
    return Color(int.parse('FF$h', radix: 16));
  }
  @override
  Widget build(BuildContext context) {
    final c = _hex(hex);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: c,
          border: Border.all(color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline),
        ),
      ),
    );
  }
}
