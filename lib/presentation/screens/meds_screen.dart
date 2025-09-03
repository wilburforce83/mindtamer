import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/meds/med_notifier.dart';
import '../../data/models/med_plan.dart';
import '../../application/meds/med_service.dart';
import '../../data/models/med_log.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/pixel_button.dart';
import '../../core/pixel_assets.dart';
import '../widgets/busy_overlay.dart';
import '../../theme/colors.dart';
import 'package:intl/intl.dart';
final medEditModeProvider = StateProvider<bool>((ref)=> false);

class MedsScreen extends ConsumerWidget {
  const MedsScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref){
    final plans = ref.watch(medPlansProvider);
    final next = ref.watch(nextMedInfoProvider);
    final onTime = ref.watch(onTimeRateProvider);
    final daysLeft = ref.watch(daysLeftPerPlanProvider);
    final df = DateFormat('EEE HH:mm');

    final editing = ref.watch(medEditModeProvider);
    return GameScaffold(title: 'Medication', padding: const EdgeInsets.all(12), body: ListView(children:[
      const SizedBox(height:12),
      if (next.time != null) Text('Next: ${df.format(next.time!)} — ${next.meds.map((e)=>e.name).join(', ')}'),
      Text('On-time (30d): ${(onTime*100).toStringAsFixed(0)}%'),
      Text('Streak (days): ${ref.watch(streakProvider)}'),
      const SizedBox(height:12),
      const Text('Plans:'),
      for(final p in plans)
        _MedRow(plan: p, daysLeft: daysLeft[p.id] ?? 0, editing: editing),
      // Bottom full-width controls
      Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: SizedBox(
          width: double.infinity,
          child: PixelButton(
            onPressed: () async {
              ref.read(medEditModeProvider.notifier).state = !editing;
            },
            label: editing ? 'Done' : 'Add/Edit Meds',
          ),
        ),
      ),
      if (editing)
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: SizedBox(
            width: double.infinity,
            child: PixelButton(
              onPressed: () async {
                if (!context.mounted) return;
                final temp = MedPlan(id: 'temp', name: 'New Med', dose: '', scheduleTimes: ['08:00'], active: true)
                  ..unitsPerDose = 1
                  ..startingStock = 0
                  ..remainingStock = 0
                  ..iconPath = null;
                await _editMed(context, ref, temp, isNew: true);
              },
              label: 'Add Med',
            ),
          ),
        ),
    ]));
  }
}

class _PillIcon extends StatelessWidget {
  final String? assetPath;
  const _PillIcon({this.assetPath});
  @override
  Widget build(BuildContext context) {
    if (assetPath != null && PixelAssets.has(assetPath!)) {
      return ImageIcon(AssetImage(assetPath!), size: 28, color: Theme.of(context).colorScheme.onSurface);
    }
    // Code-only pixel pill: simple 12x12 squares
    return const SizedBox(
      width: 28,
      height: 28,
      child: CustomPaint(painter: _PillPainter(color: AppColors.accentWarm)),
    );
  }
}

class _PillPainter extends CustomPainter {
  final Color color;
  const _PillPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final unit = (size.shortestSide / 12).floorToDouble().clamp(1.0, size.shortestSide);
    final offX = (size.width - unit*12)/2;
    final offY = (size.height - unit*12)/2;
    final c1 = Paint()..color = color;
    final c2 = Paint()..color = AppColors.ivory;
    void px(int x,int y, Paint p){ canvas.drawRect(Rect.fromLTWH(offX + x*unit, offY + y*unit, unit, unit), p); }
    // Draw capsule-like 12x12
    // Left half
    for(int y=4;y<=7;y++){ for(int x=2;x<=5;x++){ px(x,y,c1);} }
    // Right half
    for(int y=4;y<=7;y++){ for(int x=6;x<=9;x++){ px(x,y,c2);} }
    // Edges
    for(int y=3;y<=8;y++){ px(1,y,c1); px(10,y,c2);} // vertical ends
  }
  @override
  bool shouldRepaint(covariant _PillPainter oldDelegate)=> oldDelegate.color!=color;
}

Future<void> _editMed(BuildContext context, WidgetRef ref, MedPlan medPlan, {bool isNew = false}) async {
  final notifier = ref.read(medPlansProvider.notifier);
  final nameCtrl = TextEditingController(text: medPlan.name);
  final doseCtrl = TextEditingController(text: medPlan.dose);
  final timesCtrl = TextEditingController(text: medPlan.scheduleTimes.join(','));
  final startCtrl = TextEditingController(text: medPlan.startingStock.toString());
  final remainCtrl = TextEditingController(text: medPlan.remainingStock.toString());
  final updCtrl = TextEditingController(text: medPlan.unitsPerDose.toString());
  String? selectedIcon = medPlan.iconPath;
  final iconPaths = PixelAssets.listPillIcons();
  bool busy = false;
  await showDialog(context: context, barrierDismissible: false, builder: (context){
    return StatefulBuilder(builder: (context, setStateSB) {
      final dialog = AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        title: const Text('Edit Medication'),
        content: SingleChildScrollView(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height:12),
          TextField(controller: doseCtrl, decoration: const InputDecoration(labelText: 'Dose')),
          const SizedBox(height:12),
          TextField(controller: timesCtrl, decoration: const InputDecoration(labelText: 'Times (HH:mm, comma separated)')),
          const SizedBox(height:12),
          TextField(controller: updCtrl, decoration: const InputDecoration(labelText: 'Units per dose'), keyboardType: TextInputType.number),
          const SizedBox(height:12),
          TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Starting stock'), keyboardType: TextInputType.number),
          const SizedBox(height:12),
          TextField(controller: remainCtrl, decoration: const InputDecoration(labelText: 'Remaining stock'), keyboardType: TextInputType.number),
          const SizedBox(height:16),
          const Align(alignment: Alignment.centerLeft, child: Text('Icon:')),
          Wrap(spacing:8, runSpacing:8, children: [
            ChoiceChip(
              label: const Text('Code Default'),
              selected: selectedIcon == null,
              onSelected: (_){ selectedIcon = null; },
            ),
            for(final p in iconPaths) InkWell(onTap: (){ selectedIcon = p; }, child: Container(
              decoration: BoxDecoration(border: Border.all(color: selectedIcon==p? AppColors.accentWarm: AppColors.outline)),
              padding: const EdgeInsets.all(4), child: ImageIcon(AssetImage(p), size: 24)))
          ])
        ],
        )),
        actions: [
          TextButton(onPressed: busy ? null : ()=>Navigator.pop(context), child: const Text('Cancel')),
          if (!isNew)
            TextButton(onPressed: busy ? null : () async {
              setStateSB(()=>busy=true);
              await ref.read(medPlansProvider.notifier).delete(medPlan.id);
              if (context.mounted) Navigator.pop(context);
            }, child: const Text('Delete')),
          TextButton(onPressed: busy ? null : () async {
            setStateSB(()=>busy=true);
            final name = nameCtrl.text.trim();
            final dose = doseCtrl.text.trim();
            final times = timesCtrl.text.split(',').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList();
            final units = int.tryParse(updCtrl.text) ?? medPlan.unitsPerDose;
            final start = int.tryParse(startCtrl.text) ?? medPlan.startingStock;
            final remain = int.tryParse(remainCtrl.text) ?? medPlan.remainingStock;
            if (isNew) {
              final created = await notifier.addPlan(name.isEmpty? 'New Med': name, dose, times.isEmpty? ['08:00']: times, schedule: false);
              created
                ..unitsPerDose = units
                ..startingStock = start
                ..remainingStock = remain
                ..iconPath = selectedIcon;
              await notifier.editPlan(created); // this schedules + alerts after full data is set
            } else {
              final updated = medPlan
                ..name = name
                ..dose = dose
                ..scheduleTimes = times
                ..unitsPerDose = units
                ..startingStock = start
                ..remainingStock = remain
                ..iconPath = selectedIcon;
              await notifier.editPlan(updated);
            }
            if (context.mounted) Navigator.pop(context);
          }, child: const Text('Save')),
        ],
      );
      return Stack(children:[dialog, if (busy) const BusyOverlay(label: 'Saving...')]);
    });
  });
}

class _MedRow extends ConsumerWidget {
  final MedPlan plan;
  final int daysLeft;
  final bool editing;
  const _MedRow({required this.plan, required this.daysLeft, required this.editing});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.watch(medServiceProvider);
    final logs = ref.watch(medLogsProvider);
    // final settings = ref.watch(medSettingsProvider); // not used here yet
    final now = DateTime.now();

    // Determine per-slot status for today
    final timesSorted = [...plan.scheduleTimes]..sort();
    String? nextUpcoming; // next not-taken slot >= now
    String? lastMissed;   // most recent earlier not-taken slot < now
    bool allTaken = true;
    int minutesFromSched = 0; // relative to nextUpcoming when present
    for (final t in timesSorted) {
      final tod = svc.parseTime(t);
      final sched = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
      final taken = logs.any((l)=> l.planId==plan.id && l.date.year==sched.year && l.date.month==sched.month && l.date.day==sched.day && l.time==t && l.taken);
      if (!taken) {
        allTaken = false;
        if (sched.isBefore(now) || sched.isAtSameMomentAs(now)) {
          lastMissed = t; // keep updating to get most recent missed
        } else if (nextUpcoming == null) {
          nextUpcoming = t;
          minutesFromSched = now.difference(sched).inMinutes;
        }
      }
    }

    Color bg;
    String label;
    bool enabled;
    if (editing) {
      bg = Theme.of(context).colorScheme.surface;
      label = 'Edit';
      enabled = true;
    } else if (allTaken) {
      bg = Theme.of(context).colorScheme.surface;
      label = 'Taken';
      enabled = false;
    } else {
      if (lastMissed != null) {
        // There is a missed earlier dose; highlight red to resolve
        bg = Colors.red.shade700; label = 'Take'; enabled = true;
      } else if (nextUpcoming != null) {
        final abs = minutesFromSched.abs();
        if (abs <= 45) { bg = Colors.green; label = 'Take'; enabled = true; }
        else if (abs <= 90) { bg = Colors.yellow.shade700; label = 'Take'; enabled = true; }
        else { bg = Theme.of(context).colorScheme.surface; label = 'Not due'; enabled = false; }
      } else {
        bg = Theme.of(context).colorScheme.surface; label = 'Taken'; enabled = false;
      }
    }

    // Build per-slot quick actions
    final slotBar = _SlotBar(plan: plan);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border.fromBorderSide(BorderSide(color: AppColors.muted, width: 2)),
      ),
      child: ListTile(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: _PillIcon(assetPath: plan.iconPath),
        title: Text('${plan.name} ${plan.dose}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${plan.scheduleTimes.join(', ')}\nStock: ${plan.remainingStock}/${plan.startingStock}  •  ~$daysLeft days left'),
            const SizedBox(height: 6),
            slotBar,
          ],
        ),
        isThreeLine: true,
        trailing: SizedBox(
          width: 104,
          height: 36,
          child: PixelButton(
            label: label,
            bgColor: bg,
            fgColor: Colors.black,
            onPressed: !enabled ? null : () async {
              if (editing) {
                await _editMed(context, ref, plan);
                return;
              }
            final notifier = ref.read(medPlansProvider.notifier);
            final day = DateTime(now.year, now.month, now.day);
            if (lastMissed != null) {
              // Offer to resolve the missed dose, or proceed to take next
              final result = await showDialog<String>(context: context, builder: (context){
                return AlertDialog(
                  title: const Text('Missed Dose'),
                  content: Text('You missed the previous dose at $lastMissed for ${plan.name} ${plan.dose}.\nWhat would you like to do?'),
                  actions: [
                    TextButton(onPressed: ()=>Navigator.pop(context, 'log_earlier'), child: Text('I took $lastMissed')),
                    TextButton(onPressed: ()=>Navigator.pop(context, 'take_now_missed'), child: const Text('Take now')),
                    TextButton(onPressed: ()=>Navigator.pop(context, 'skip'), child: const Text('Skip (mark missed)')),
                    TextButton(onPressed: ()=>Navigator.pop(context, 'cancel'), child: const Text('Cancel')),
                  ],
                );
              });
              if (result == 'log_earlier') {
                // Backfill as on-time: use scheduled timestamp as loggedAt
                final todParsed = svc.parseTime(lastMissed);
                final schedTs = DateTime(now.year, now.month, now.day, todParsed.hour, todParsed.minute);
                await notifier.log(plan.id, day, lastMissed, true, loggedAt: schedTs);
              } else if (result == 'take_now_missed') {
                // Mark the missed slot as taken now (counts late in stats if > 120min)
                final todParsed = svc.parseTime(lastMissed);
                final sched = DateTime(now.year, now.month, now.day, todParsed.hour, todParsed.minute);
                final mins = now.difference(sched).inMinutes;
                final late = mins >= 0 ? mins : -mins;
                final note = late > 120 ? '\n\nNote: This is more than 2 hours late; it will not count towards your streak.' : '';
                if (!context.mounted) return;
                final ok = await showDialog<bool>(context: context, builder: (context){
                  return AlertDialog(
                    title: const Text('Confirm'),
                    content: Text('Take ${plan.name} ${plan.dose}\nScheduled: $lastMissed\nYou are $late min late.$note\n\nTake medicine now?'),
                    actions: [
                      TextButton(onPressed: ()=>Navigator.pop(context,false), child: const Text('No')),
                      TextButton(onPressed: ()=>Navigator.pop(context,true), child: const Text('Yes')),
                    ],
                  );
                });
                if (ok == true) {
                  await notifier.log(plan.id, day, lastMissed, true);
                }
              } else if (result == 'skip') {
                await notifier.log(plan.id, day, lastMissed, false);
              }
            } else if (nextUpcoming != null) {
              final tod = nextUpcoming;
              final todParsed = svc.parseTime(tod);
              final sched = DateTime(now.year, now.month, now.day, todParsed.hour, todParsed.minute);
              final mins = now.difference(sched).inMinutes;
              final late = mins >= 0 ? mins : -mins;
              final rel = mins >= 0 ? 'late' : 'early';
              final note = (mins.abs() > 120 && mins > 0)
                  ? '\n\nNote: This is more than 2 hours late; it will not count towards your streak.'
                  : '';
              final ok = await showDialog<bool>(context: context, builder: (context){
                return AlertDialog(
                  title: const Text('Confirm'),
                  content: Text('Take ${plan.name} ${plan.dose}\nScheduled: $tod\nYou are $late min $rel.$note\n\nTake medicine now?'),
                  actions: [
                    TextButton(onPressed: ()=>Navigator.pop(context,false), child: const Text('No')),
                    TextButton(onPressed: ()=>Navigator.pop(context,true), child: const Text('Yes')),
                  ],
                );
              });
              if (ok == true) {
                await notifier.log(plan.id, day, tod, true);
              }
            }
            },
          ),
        ),
        onTap: editing ? (){ _editMed(context, ref, plan); } : null,
      ),
    );
  }
}

class _SlotBar extends ConsumerWidget {
  final MedPlan plan;
  const _SlotBar({required this.plan});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.watch(medServiceProvider);
    final logs = ref.watch(medLogsProvider);
    final now = DateTime.now();
    final times = [...plan.scheduleTimes]..sort();
    return Wrap(spacing: 6, runSpacing: 6, children: [
      for (final t in times)
        _SlotButton(plan: plan, time: t, svc: svc, logs: logs, now: now),
    ]);
  }
}

class _SlotButton extends ConsumerWidget {
  final MedPlan plan; final String time; final MedService svc; final List<MedLog> logs; final DateTime now;
  const _SlotButton({required this.plan, required this.time, required this.svc, required this.logs, required this.now});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tod = svc.parseTime(time);
    final sched = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    final isTaken = logs.any((l)=> l.planId==plan.id && l.date.year==sched.year && l.date.month==sched.month && l.date.day==sched.day && l.time==time && l.taken);
    Color bg; bool enabled; String label;
    if (isTaken) { bg = Theme.of(context).colorScheme.surface; enabled=false; label='Taken $time'; }
    else if (sched.isBefore(now)) {
      final diff = now.difference(sched).inMinutes;
      if (diff > 90) { bg = Colors.red.shade700; } else { bg = Colors.yellow.shade700; }
      enabled = true; label = time;
    } else {
      final diff = sched.difference(now).inMinutes;
      if (diff <= 45) { bg = Colors.green; enabled=true; }
      else if (diff <= 90) { bg = Colors.yellow.shade700; enabled=true; }
      else { bg = Theme.of(context).colorScheme.surface; enabled=false; }
      label = time;
    }
    return PixelButton(
      label: label,
      bgColor: bg,
      fgColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      onPressed: !enabled ? null : () async {
        // Past slot -> missed dialog
        final notifier = ref.read(medPlansProvider.notifier);
        final day = DateTime(now.year, now.month, now.day);
        if (sched.isBefore(now)) {
          final result = await showDialog<String>(context: context, builder: (context){
            return AlertDialog(
              title: const Text('Missed Dose'),
              content: Text('You missed $time for ${plan.name} ${plan.dose}.\nWhat would you like to do?'),
              actions: [
                TextButton(onPressed: ()=>Navigator.pop(context, 'log_earlier'), child: Text('I took $time')),
                TextButton(onPressed: ()=>Navigator.pop(context, 'take_now_missed'), child: const Text('Take now')),
                TextButton(onPressed: ()=>Navigator.pop(context, 'skip'), child: const Text('Skip (mark missed)')),
                TextButton(onPressed: ()=>Navigator.pop(context, 'cancel'), child: const Text('Cancel')),
              ],
            );
          });
          if (result == 'log_earlier') {
            final schedTs = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
            await notifier.log(plan.id, day, time, true, loggedAt: schedTs);
          } else if (result == 'take_now_missed') {
            final mins = now.difference(sched).inMinutes;
            final note = mins > 120 ? '\n\nNote: This is more than 2 hours late; it will not count towards your streak.' : '';
            if (!context.mounted) return;
            final ok = await showDialog<bool>(context: context, builder: (context){
              return AlertDialog(
                title: const Text('Confirm'),
                content: Text('Take ${plan.name} ${plan.dose}\nScheduled: $time\nYou are $mins min late.$note\n\nTake medicine now?'),
                actions: [
                  TextButton(onPressed: ()=>Navigator.pop(context,false), child: const Text('No')),
                  TextButton(onPressed: ()=>Navigator.pop(context,true), child: const Text('Yes')),
                ],
              );
            });
            if (ok == true) {
              await notifier.log(plan.id, day, time, true);
            }
          } else if (result == 'skip') {
            await notifier.log(plan.id, day, time, false);
          }
        } else {
          final mins = now.difference(sched).inMinutes; // negative (early)
          final late = mins >= 0 ? mins : -mins;
          final rel = mins >= 0 ? 'late' : 'early';
          if (!context.mounted) return;
          final ok = await showDialog<bool>(context: context, builder: (context){
            return AlertDialog(
              title: const Text('Confirm'),
              content: Text('Take ${plan.name} ${plan.dose}\nScheduled: $time\nYou are $late min $rel.\n\nTake medicine now?'),
              actions: [
                TextButton(onPressed: ()=>Navigator.pop(context,false), child: const Text('No')),
                TextButton(onPressed: ()=>Navigator.pop(context,true), child: const Text('Yes')),
              ],
            );
          });
          if (ok == true) {
            await notifier.log(plan.id, day, time, true);
          }
        }
      },
    );
  }
}
