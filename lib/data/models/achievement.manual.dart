part of 'achievement.dart';
class AchievementAdapter extends TypeAdapter<Achievement>{
  @override final int typeId=6;
  @override Achievement read(BinaryReader r){
    final n=r.readByte(); final f=<int,dynamic>{}; for(var i=0;i<n;i++){ f[r.readByte()]=r.read(); }
    return Achievement(id:f[0] as String, key:f[1] as String, earnedAt:f[2] as DateTime);
  }
  @override void write(BinaryWriter w, Achievement o){
    w..writeByte(3)
     ..writeByte(0)..write(o.id)
     ..writeByte(1)..write(o.key)
     ..writeByte(2)..write(o.earnedAt);
  }
}
