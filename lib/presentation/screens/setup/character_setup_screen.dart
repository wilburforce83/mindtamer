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
  static const String _noDiagnosisLabel = 'No Diagnosis';
  static const List<String> _diagnosisOptions = [
    _noDiagnosisLabel,
    'ADHD',
    'Agoraphobia',
    'Alcohol Use Disorder',
    'Anorexia Nervosa',
    'ARFID',
    'Auditory Processing Disorder',
    'Autism Spectrum Disorder (ASD)',
    'Avoidant Personality Disorder',
    'Binge Eating Disorder',
    'Bipolar I Disorder',
    'Bipolar II Disorder',
    'Body Dysmorphic Disorder',
    'Borderline Personality Disorder (BPD)',
    'Bulimia Nervosa',
    'Chronic Tic Disorder',
    'Complex PTSD (C-PTSD)',
    'Cyclothymia',
    'Dependent Personality Disorder',
    'Depersonalization/Derealization Disorder',
    'Depression',
    'Dissociative Identity Disorder (DID)',
    'Dyscalculia',
    'Dysgraphia',
    'Dyslexia',
    'Dyspraxia (DCD)',
    'Generalized Anxiety Disorder (GAD)',
    'Health Anxiety',
    'Hoarding Disorder',
    'Insomnia Disorder',
    'Narcolepsy',
    'Obsessive-Compulsive Disorder (OCD)',
    'Obsessive-Compulsive Personality Disorder (OCPD)',
    'Panic Disorder',
    'Persistent Depressive Disorder',
    'Post-Traumatic Stress Disorder (PTSD)',
    'PMDD',
    'Premenstrual Exacerbation (PME)',
    'Psychotic Disorder',
    'Schizoaffective Disorder',
    'Schizophrenia',
    'Seasonal Affective Disorder',
    'Selective Mutism',
    'Sensory Processing Disorder',
    'Social Anxiety Disorder',
    'Substance Use Disorder',
    'Tourette Syndrome',
  ];
  static const Map<String, String> _classSuggestions = {
    'ADHD': 'Trickster',
    'Agoraphobia': 'Sentinel',
    'Alcohol Use Disorder': 'Alchemist',
    'Anorexia Nervosa': 'Empath',
    'ARFID': 'Empath',
    'Auditory Processing Disorder': 'Artificer',
    'Autism': 'Sage',
    'Autism Spectrum Disorder (ASD)': 'Sage',
    'Avoidant Personality Disorder': 'Sentinel',
    'Binge Eating Disorder': 'Empath',
    'Bipolar': 'Alchemist',
    'Bipolar I Disorder': 'Alchemist',
    'Bipolar II Disorder': 'Alchemist',
    'Body Dysmorphic Disorder': 'Oracle',
    'Borderline Personality Disorder (BPD)': 'Empath',
    'BPD': 'Empath',
    'Bulimia Nervosa': 'Empath',
    'Chronic Tic Disorder': 'Seer',
    'Complex PTSD (C-PTSD)': 'Shadow',
    'Cyclothymia': 'Alchemist',
    'Dependent Personality Disorder': 'Warden',
    'Depersonalization/Derealization Disorder': 'Shadow',
    'Depression': 'Warden',
    'Dissociative Identity Disorder (DID)': 'Shadow',
    'Dyscalculia': 'Artificer',
    'Dysgraphia': 'Artificer',
    'Dyslexia': 'Artificer',
    'Dyspraxia': 'Empath',
    'Dyspraxia (DCD)': 'Empath',
    'Generalized Anxiety Disorder (GAD)': 'Sentinel',
    'GAD': 'Sentinel',
    'Health Anxiety': 'Sentinel',
    'Hoarding Disorder': 'Oracle',
    'Insomnia Disorder': 'Seer',
    'Narcolepsy': 'Seer',
    'Obsessive-Compulsive Disorder (OCD)': 'Oracle',
    'OCD': 'Oracle',
    'Obsessive-Compulsive Personality Disorder (OCPD)': 'Oracle',
    'OCPD': 'Oracle',
    'Panic Disorder': 'Sentinel',
    'Persistent Depressive Disorder': 'Warden',
    'Post-Traumatic Stress Disorder (PTSD)': 'Shadow',
    'PTSD': 'Shadow',
    'PMDD': 'Empath',
    'Premenstrual Exacerbation (PME)': 'Empath',
    'PME': 'Empath',
    'Psychotic Disorder': 'Seer',
    'Schizoaffective Disorder': 'Seer',
    'Schizophrenia': 'Seer',
    'Seasonal Affective Disorder': 'Warden',
    'Selective Mutism': 'Sentinel',
    'Sensory Processing Disorder': 'Empath',
    'SPD': 'Empath',
    'Social Anxiety': 'Sentinel',
    'Social Anxiety Disorder': 'Sentinel',
    'Substance Use Disorder': 'Alchemist',
    'Tourette': 'Seer',
    'Tourette Syndrome': 'Seer',
    'Anxiety': 'Sentinel',
  };
  String _diagnosis = _noDiagnosisLabel;
  final Set<String> _additionalDiagnoses = <String>{};
  String? _classKey;
  String _gender = 'm'; // m | f
  String _hairBase = '#6B3F2A'; // hex strings
  String _skinBase = '#E0B6A1';
  bool _classAuto = true; // whether class is following diagnosis suggestion
  int _step = 0; // 0: choose class, 1: customize
  ui.Image? _preview;

  final List<String> _classes = const [
    'Sage',
    'Warden',
    'Trickster',
    'Seer',
    'Artificer',
    'Empath',
    'Sentinel',
    'Oracle',
    'Shadow',
    'Alchemist'
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
    '#F2D6C2',
    '#E0B6A1',
    '#C58C6A',
    '#A1664A',
    '#8D5524',
    '#5C3D2E'
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

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _hasPrimaryDiagnosis => _diagnosis != _noDiagnosisLabel;

  String? get _primaryDiagnosisOrNull =>
      _hasPrimaryDiagnosis ? _diagnosis : null;

  List<String> get _allSelectedDiagnoses {
    final additional = _additionalDiagnoses.toList()..sort();
    return <String>[
      if (_hasPrimaryDiagnosis) _diagnosis,
      ...additional,
    ];
  }

  List<String> get _availableAdditionalDiagnoses => _diagnosisOptions
      .where((d) => d != _noDiagnosisLabel && d != _diagnosis)
      .toList(growable: false);

  Future<void> _refreshPreview() async {
    final cls = _classKey ?? 'Sage';
    final asset = 'assets/images/players/${cls.toLowerCase()}_$_gender.png';
    ui.Image? img;
    try {
      final resolved =
          await PlayerImageService.resolveAssetPath(cls, _gender) ?? asset;
      img = await PlayerImageService().recolorAsset(
        assetPath: resolved,
        hairRamp6: PlayerImageService.makeRamp3(_hairBase),
        skinRamp6: PlayerImageService.makeRamp3(_skinBase),
        // Default to brown tones until weapon details exist
        weaponGlowRamp3: PlayerImageService.defaultWeaponGlowRamp3(),
      );
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _preview = img;
    });
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
    return _classSuggestions[dx] ?? 'Sage';
  }
  // Class blurb and start effect text removed from the UI for now; keep perks for later use.

  Future<void> _pickAdditionalDiagnoses() async {
    if (!_hasPrimaryDiagnosis) return;
    var query = '';
    final working = Set<String>.from(_additionalDiagnoses);
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Additional Diagnoses'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              final options = _availableAdditionalDiagnoses
                  .where((d) => d.toLowerCase().contains(query))
                  .toList(growable: false);
              return SizedBox(
                width: 420,
                height: 420,
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) {
                        setDialogState(() {
                          query = value.trim().toLowerCase();
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Search diagnoses',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Scrollbar(
                        child: ListView(
                          children: [
                            for (final diagnosis in options)
                              CheckboxListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                value: working.contains(diagnosis),
                                title: Text(diagnosis),
                                onChanged: (selected) {
                                  setDialogState(() {
                                    if (selected ?? false) {
                                      working.add(diagnosis);
                                    } else {
                                      working.remove(diagnosis);
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(<String>{}),
              child: const Text('Clear All'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(working),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
    if (result == null || !mounted) return;
    setState(() {
      _additionalDiagnoses
        ..clear()
        ..addAll(result);
    });
  }

  Future<void> _create() async {
    try {
      final name = _name.text.trim().isEmpty ? 'Adventurer' : _name.text.trim();
      final classKey = _classKey ?? 'Sage';
      final primaryDiagnosis = _primaryDiagnosisOrNull;
      final additionalDiagnoses = _additionalDiagnoses.toList()..sort();
      final allDiagnoses = _allSelectedDiagnoses;
      // Determine source
      String classSource;
      if (primaryDiagnosis == null) {
        classSource = 'manual';
      } else {
        final suggested = _suggestClass(primaryDiagnosis);
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
      final asset =
          'assets/images/players/${classKey.toLowerCase()}_$_gender.png';
      await playerMetaBox().putAll({
        'name': name,
        'classSource': classSource,
        'diagnosis': primaryDiagnosis,
        'primaryDiagnosis': primaryDiagnosis,
        'additionalDiagnoses': additionalDiagnoses,
        'diagnoses': allDiagnoses,
        'class': classKey,
        'gender': _gender,
        'hairBase': _hairBase,
        'skinBase': _skinBase,
        'playerImageAsset': asset,
        'hp': 60,
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
        Text('Create Your Character',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (_step == 0) ...[
          TextField(
            controller: _name,
            decoration: const InputDecoration(
                labelText: 'Name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          Text('Class', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
              'Mind Tamer may suggest a class based on your primary diagnosis; you can override it.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          const Text('Primary diagnosis'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _diagnosis,
            isExpanded: true,
            menuMaxHeight: 420,
            items: _diagnosisOptions
                .map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(
                        d,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _diagnosis = v;
                _additionalDiagnoses.remove(v);
                if (!_hasPrimaryDiagnosis) {
                  _additionalDiagnoses.clear();
                }
                if (_classAuto && _hasPrimaryDiagnosis) {
                  _classKey = _suggestClass(v);
                  _refreshPreview();
                }
              });
            },
            decoration: const InputDecoration(
                border: OutlineInputBorder(), labelText: 'Diagnosis'),
          ),
          if (_hasPrimaryDiagnosis) ...[
            const SizedBox(height: 8),
            Text(
              'Suggested class: ${_suggestClass(_diagnosis)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          const Text('Additional diagnoses (optional)'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _hasPrimaryDiagnosis ? _pickAdditionalDiagnoses : null,
            icon: const Icon(Icons.add),
            label: Text(
              _additionalDiagnoses.isEmpty
                  ? 'Add additional diagnoses'
                  : 'Edit additional diagnoses',
            ),
          ),
          if (!_hasPrimaryDiagnosis)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Choose a primary diagnosis first, or leave it as No Diagnosis.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (_additionalDiagnoses.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final diagnosis in _additionalDiagnoses.toList()..sort())
                  InputChip(
                    label: Text(diagnosis),
                    onDeleted: () {
                      setState(() {
                        _additionalDiagnoses.remove(diagnosis);
                      });
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _classKey,
            isExpanded: true,
            items: _classes
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) {
              setState(() {
                _classKey = v;
                _classAuto = false;
              });
              _refreshPreview();
            },
            decoration: const InputDecoration(
                border: OutlineInputBorder(), labelText: 'Class'),
          ),
          const SizedBox(height: 12),
          Text('What gender do you identify with?',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Row(children: [
            ChoiceChip(
                label: const Text('Female'),
                selected: _gender == 'f',
                onSelected: (_) {
                  setState(() => _gender = 'f');
                  _refreshPreview();
                }),
            const SizedBox(width: 8),
            ChoiceChip(
                label: const Text('Male'),
                selected: _gender == 'm',
                onSelected: (_) {
                  setState(() => _gender = 'm');
                  _refreshPreview();
                }),
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
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant)),
                  child: _preview != null
                      ? RawImage(
                          image: _preview,
                          filterQuality: FilterQuality.none,
                          fit: BoxFit.cover,
                          width: imgSize,
                          height: imgSize,
                        )
                      : Builder(builder: (ctx) {
                          final cls = (_classKey ?? 'Sage');
                          final path =
                              PlayerImageService.assetPathFor(cls, _gender);
                          return Image.asset(
                            path,
                            filterQuality: FilterQuality.none,
                            fit: BoxFit.cover,
                            width: imgSize,
                            height: imgSize,
                            errorBuilder: (_, __, ___) =>
                                const Text('No preview'),
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
          FilledButton(
              onPressed: () => setState(() => _step = 1),
              child: const Text('Customize')),
        ] else ...[
          Center(
            child: Container(
              width: 256,
              height: 256,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant)),
              child: _preview != null
                  ? RawImage(
                      image: _preview,
                      filterQuality: FilterQuality.none,
                      fit: BoxFit.cover,
                      width: 256,
                      height: 256,
                    )
                  : Builder(builder: (ctx) {
                      final cls = (_classKey ?? 'Sage');
                      final path =
                          PlayerImageService.assetPathFor(cls, _gender);
                      return Image.asset(
                        path,
                        filterQuality: FilterQuality.none,
                        fit: BoxFit.cover,
                        width: 256,
                        height: 256,
                        errorBuilder: (_, __, ___) => const Text('No preview'),
                      );
                    }),
            ),
          ),
          const SizedBox(height: 16),
          Text('Hair Color', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final hex in _hairOptions)
              _ColorChip(
                  hex: hex,
                  selected: _hairBase == hex,
                  onTap: () {
                    setState(() => _hairBase = hex);
                    _refreshPreview();
                  }),
          ]),
          const SizedBox(height: 16),
          Text('Skin Tone', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final hex in _skinOptions)
              _ColorChip(
                  hex: hex,
                  selected: _skinBase == hex,
                  onTap: () {
                    setState(() => _skinBase = hex);
                    _refreshPreview();
                  }),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            OutlinedButton(
                onPressed: () => setState(() => _step = 0),
                child: const Text('Back')),
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
  const _ColorChip(
      {required this.hex, required this.selected, required this.onTap});
  Color _hex(String s) {
    var h = s.startsWith('#') ? s.substring(1) : s;
    if (h.length == 3) h = h.split('').map((c) => '$c$c').join();
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
          border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline),
        ),
      ),
    );
  }
}
