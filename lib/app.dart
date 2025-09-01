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
      builder: (context, child) {
        // Clamp text scaling on small screens to reduce overflows.
        final mq = MediaQuery.of(context);
        final w = mq.size.width;
        // Scale down fonts slightly on narrow devices.
        final scale = w < 360 ? 0.80 : (w < 400 ? 0.90 : 1.0);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(scale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
