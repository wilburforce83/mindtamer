import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindtamer/seed/lexicon_loader.dart';
import 'package:mindtamer/seed/seed_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Set<String>> loadMonsterArtFamilies() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest
        .listAssets()
        .where((path) =>
            path.startsWith('assets/images/monsters/') && path.endsWith('.png'))
        .toList();
    final out = <String>{};
    for (final path in assets) {
      final file = path.split('/').last;
      final parts = file.replaceAll('.png', '').split('_');
      if (parts.length >= 3) {
        out.add(parts.first.toLowerCase());
      }
    }
    return out;
  }

  test('monster naming families align with available art families', () async {
    final bundle = await LexiconLoader.load();
    final assetFamilies = await loadMonsterArtFamilies();
    expect(bundle.naming.monsterFamilies, isNotEmpty);
    for (final family in bundle.naming.monsterFamilies) {
      expect(assetFamilies, contains(family.key));
    }
    for (final perElement in bundle.monsterTypes.values) {
      for (final familyName in perElement.values.expand((value) => value)) {
        expect(assetFamilies, contains(familyName.toLowerCase()));
      }
    }
  });

  test('lexicon naming vocabulary stays readable', () async {
    final bundle = await LexiconLoader.load();
    final word = RegExp(r'^[A-Z][A-Za-z]+$');
    for (final words in bundle.naming.monsterModifiers.values) {
      for (final entry in words) {
        expect(word.hasMatch(entry), isTrue, reason: entry);
      }
    }
    for (final words in bundle.naming.spriteDescriptors.values) {
      for (final entry in words) {
        expect(word.hasMatch(entry), isTrue, reason: entry);
      }
    }
    for (final family in bundle.naming.monsterFamilies) {
      expect(word.hasMatch(family.label), isTrue, reason: family.label);
      for (final entry in family.modifiers) {
        expect(word.hasMatch(entry), isTrue, reason: entry);
      }
    }
    for (final nouns in bundle.spriteTypes.values) {
      for (final noun in nouns) {
        expect(word.hasMatch(noun), isTrue, reason: noun);
      }
    }
  });

  test('seed generator emits clean two-word display names', () async {
    final bundle = await LexiconLoader.load();
    final gen = SeedGenerator();
    final cases = [
      SeedRequest(
        version: bundle.version,
        title: 'Panic before sleep',
        body: 'Fear kept circling and I could not settle.',
        tags: ['sleep', 'anxiety'],
        sentiment: 'negative',
      ),
      SeedRequest(
        version: bundle.version,
        title: 'A bright walk in the park',
        body: 'Fresh air, calm breath, and a better mood.',
        tags: ['wellbeing'],
        sentiment: 'positive',
      ),
      SeedRequest(
        version: bundle.version,
        title: 'Tidying the desk after work',
        body: 'A busy afternoon but the room feels calmer now.',
        tags: ['habits'],
        sentiment: 'neutral',
      ),
    ];
    final word = RegExp(r'^[A-Z][A-Za-z]+$');
    for (final req in cases) {
      final result = gen.generate(req, bundle);
      final parts = result.displayName
          .split(RegExp(r'\s+'))
          .where((e) => e.isNotEmpty)
          .toList();
      expect(parts, hasLength(2), reason: result.displayName);
      for (final part in parts) {
        expect(word.hasMatch(part), isTrue, reason: result.displayName);
      }
    }
  });
}
