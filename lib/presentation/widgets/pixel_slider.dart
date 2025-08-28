import 'package:flutter/material.dart';
class PixelSlider extends StatelessWidget {
  final int value; final ValueChanged<int> onChanged;
  const PixelSlider({super.key, required this.value, required this.onChanged});
  @override Widget build(BuildContext context){
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Slider(value:value.toDouble(), min:0, max:100, onChanged:(v)=>onChanged(v.round())),
      Text('$value'),
    ]);
  }
}
