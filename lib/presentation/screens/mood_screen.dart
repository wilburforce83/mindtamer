import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/mood/mood_notifier.dart';
import '../../data/models/mood_log.dart';
import '../widgets/pixel_slider.dart';
import 'package:uuid/uuid.dart';
class MoodScreen extends ConsumerStatefulWidget { const MoodScreen({super.key}); @override ConsumerState<MoodScreen> createState()=>_MoodScreenState(); }
class _MoodScreenState extends ConsumerState<MoodScreen> {
  int battery=50, stress=50, focus=50, mood=50, sleep=50, social=50;
  @override Widget build(BuildContext context){
    final m = ref.watch(moodProvider); final locked = m?.locked ?? false;
    return Scaffold(appBar: AppBar(title: const Text('Mood')), body: Padding(padding: const EdgeInsets.all(12), child: Column(children:[
      PixelSlider(value:battery, onChanged: locked?(_){ }: (v)=>setState(()=>battery=v)),
      PixelSlider(value:stress,  onChanged: locked?(_){ }: (v)=>setState(()=>stress=v)),
      PixelSlider(value:focus,   onChanged: locked?(_){ }: (v)=>setState(()=>focus=v)),
      PixelSlider(value:mood,    onChanged: locked?(_){ }: (v)=>setState(()=>mood=v)),
      PixelSlider(value:sleep,   onChanged: locked?(_){ }: (v)=>setState(()=>sleep=v)),
      PixelSlider(value:social,  onChanged: locked?(_){ }: (v)=>setState(()=>social=v)),
      const SizedBox(height:8),
      Row(children:[
        ElevatedButton(onPressed: locked? null : (){
          final log=MoodLog(id:const Uuid().v4(), date:DateTime.now(), battery:battery, stress:stress, focus:focus, mood:mood, sleep:sleep, social:social);
          ref.read(moodProvider.notifier).save(log);
        }, child: const Text('Save Today')),
        const SizedBox(width:12),
        ElevatedButton(onPressed: ()=>ref.read(moodProvider.notifier).lockToday(), child: const Text('Lock Day')),
      ])
    ])));
  }
}
