// FILE: test/seed_generator_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:mindtamer/seed/lexicon_loader.dart';
import 'package:mindtamer/seed/seed_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('deterministic generation for identical inputs', () async {
    final bundle = await LexiconLoader.load();
    final gen = SeedGenerator();
    final req = SeedRequest(
      version: bundle.version,
      title: 'A Calm Morning Routine',
      body: 'I woke early, did some breathing and wrote plans.',
      tags: ['sleep', 'habits'],
      sentiment: 'positive',
    );
    final a = gen.generate(req, bundle);
    final b = gen.generate(req, bundle);

    expect(a.hash, equals(b.hash));
    expect(a.kind, equals(b.kind));
    expect(a.element, equals(b.element));
    expect(a.displayName, equals(b.displayName));
    expect(a.colorHex, equals(b.colorHex));
  });

  test('version change mutates hash', () async {
    final bundle = await LexiconLoader.load();
    final gen = SeedGenerator();
    final baseReq = SeedRequest(
      version: bundle.version,
      title: 'An anxious thought before bed',
      body: 'Some worry lingered but I noted it and moved on.',
      tags: ['anxiety', 'sleep'],
      sentiment: 'mixed',
    );
    final r1 = gen.generate(baseReq, bundle);
    final r2 = gen.generate(
      SeedRequest(
        version: '${baseReq.version}+1',
        title: baseReq.title,
        body: baseReq.body,
        tags: baseReq.tags,
        sentiment: baseReq.sentiment,
      ),
      bundle,
    );
    expect(r1.hash, isNot(equals(r2.hash)));
  });

  test('basic validations', () async {
    final bundle = await LexiconLoader.load();
    final gen = SeedGenerator();
    final req = SeedRequest(
      version: bundle.version,
      title: 'Walked by the river and felt better',
      body: 'Breathing steady, light breeze, felt calm.',
      tags: ['wellbeing'],
      sentiment: 'neutral',
    );
    final res = gen.generate(req, bundle);
    expect(['fire','water','metal','shadow','nature','light','air'], contains(res.element));
    expect(RegExp('^#' r'[0-9A-F]{6}').hasMatch(res.colorHex), isTrue);
    expect(['common','uncommon','rare','epic'], contains(res.rarity));
  });
}
