import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/meds/med_notifier.dart';
import '../widgets/pixel_pillbox.dart';
class MedsScreen extends ConsumerWidget {
  const MedsScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref){
    final plans = ref.watch(medPlansProvider); final times = plans.expand((p)=>p.scheduleTimes).toList();
    return Scaffold(appBar: AppBar(title: const Text('Medication')), body: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      ElevatedButton(onPressed: ()=>ref.read(medPlansProvider.notifier).addPlan('Example Med','25mg',['08:00','20:00']), child: const Text('Add Example Plan')),
      const SizedBox(height:12),
      const Text('Plans:'),
      for(final p in plans) ListTile(title: Text('${p.name} ${p.dose}'), subtitle: Text(p.scheduleTimes.join(', '))),
      const SizedBox(height:12),
      const Text('Pillbox:'),
      PixelPillbox(slots: times),
    ])));
  }
}
