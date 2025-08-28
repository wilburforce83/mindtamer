import 'package:hive/hive.dart';
import 'player_profile.dart';
class PlayerProfileAdapter extends TypeAdapter<PlayerProfile>{
  @override final int typeId=7;
  @override PlayerProfile read(BinaryReader r){
    final n=r.readByte(); final f=<int,dynamic>{}; for(var i=0;i<n;i++){ f[r.readByte()]=r.read(); }
    return PlayerProfile(id:f[0] as String, classKey:f[1] as String, level:f[2] as int, xp:f[3] as int,
      unlockedSkills:(f[4] as List).cast<String>(), cosmetics:(f[5] as List).cast<String>(), titles:(f[6] as List).cast<String>());
  }
  @override void write(BinaryWriter w, PlayerProfile o){
    w..writeByte(7)
     ..writeByte(0)..write(o.id)
     ..writeByte(1)..write(o.classKey)
     ..writeByte(2)..write(o.level)
     ..writeByte(3)..write(o.xp)
     ..writeByte(4)..write(o.unlockedSkills)
     ..writeByte(5)..write(o.cosmetics)
     ..writeByte(6)..write(o.titles);
  }
}
