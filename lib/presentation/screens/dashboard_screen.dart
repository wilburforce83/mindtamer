import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/game_scaffold.dart';
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override Widget build(BuildContext context){
    return const GameScaffold(
      title: 'MindTamer',
      body: Center(child: Wrap(spacing:12, runSpacing:12, children: [
        _NavCard(label:'Journal', route:'/journal'),
        _NavCard(label:'Mood', route:'/mood'),
        _NavCard(label:'Meds', route:'/meds'),
        _NavCard(label:'Charts', route:'/charts'),
        _NavCard(label:'Battle', route:'/battle'),
        _NavCard(label:'Settings', route:'/settings'),
      ])),
    );
  }
}
class _NavCard extends StatelessWidget {
  final String label; final String route;
  const _NavCard({required this.label, required this.route});
  @override Widget build(BuildContext context){
    return Card(child: InkWell(onTap: ()=>context.push(route), child: SizedBox(width:140, height:90, child: Center(child: Text(label, style: const TextStyle(fontSize:18))))));
  }
}
