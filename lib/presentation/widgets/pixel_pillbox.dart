import 'package:flutter/material.dart';
class PixelPillbox extends StatelessWidget {
  final List<String> slots;
  const PixelPillbox({super.key, required this.slots});
  @override Widget build(BuildContext context){
    return Wrap(spacing:8, runSpacing:8, children:[
      for(final s in slots) Container(padding:const EdgeInsets.all(8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Theme.of(context).cardColor),
        child: Text(s, style: const TextStyle(fontWeight: FontWeight.bold)),
      )
    ]);
  }
}
