# MindTamer Theme (Flutter + Flame)

Files included:
- `lib/theme/colors.dart` — central color tokens
- `lib/theme/theme.dart` — `mindTamerTheme()` returning a configured `ThemeData`
- `palette.tokens.json` — design tokens (colors + roles) for cross‑tool sharing
- `PALETTE.md` — human‑readable palette with contrast info
- `mindtamer-palette-swatches.png` — visual swatch sheet

## Quick start
```dart
import 'package:flutter/material.dart';
import 'theme/theme.dart';

void main() => runApp(const MindTamer());

class MindTamer extends StatelessWidget {
  const MindTamer({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: mindTamerTheme(),
      home: const Placeholder(),
    );
  }
}
```
