import 'package:flutter/material.dart';
import '../widgets/game_scaffold.dart';

class ChartsScreen extends StatelessWidget {
  const ChartsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const GameScaffold(
      title: 'Charts (Retro) ',
      body: Center(child: Text('Retro pixel charts TBD')),
    );
  }
}
