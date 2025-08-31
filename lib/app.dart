import 'package:flutter/material.dart';
import 'router.dart';
import 'theme/theme.dart';

class MindTamerApp extends StatelessWidget {
  const MindTamerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = buildRouter();
    return MaterialApp.router(
      title: 'MindTamer',
      theme: mindTamerTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
