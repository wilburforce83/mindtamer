import 'package:flutter_riverpod/flutter_riverpod.dart';
class BattleState {
  final int playerHp; final int daemonHp; final List<String> log;
  const BattleState({this.playerHp=100,this.daemonHp=100,this.log=const []});
  BattleState copyWith({int? playerHp,int? daemonHp,List<String>? log}) => BattleState(playerHp:playerHp??this.playerHp, daemonHp:daemonHp??this.daemonHp, log:log??this.log);
}
final battleProvider = StateNotifierProvider<BattleNotifier, BattleState>((ref)=>BattleNotifier());
class BattleNotifier extends StateNotifier<BattleState> {
  BattleNotifier():super(const BattleState());
  void basicAttack(){ final newHp=(state.daemonHp-12).clamp(0,999); state=state.copyWith(daemonHp:newHp, log:[...state.log,'You attack for 12 damage!']); }
  void daemonTurn(){ final newHp=(state.playerHp-8).clamp(0,999); state=state.copyWith(playerHp:newHp, log:[...state.log,'Daemon hits you for 8!']); }
  void reset()=>state=const BattleState();
}
