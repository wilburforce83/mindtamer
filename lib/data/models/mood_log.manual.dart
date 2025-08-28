import 'package:hive/hive.dart';
import 'mood_log.dart';

class MoodLogAdapter extends TypeAdapter<MoodLog> {
  @override final int typeId = 3;
  @override MoodLog read(BinaryReader r) {
    final n=r.readByte(); final f=<int,dynamic>{}; for(var i=0;i<n;i++){ f[r.readByte()]=r.read(); }
    return MoodLog(
      id:f[0] as String, date:f[1] as DateTime, battery:f[2] as int, stress:f[3] as int,
      focus:f[4] as int, mood:f[5] as int, sleep:f[6] as int, social:f[7] as int,
      custom1:f[8] as int?, custom2:f[9] as int?, locked:f[10] as bool,
    );
  }
  @override void write(BinaryWriter w, MoodLog o){
    w..writeByte(11)
     ..writeByte(0)..write(o.id)
     ..writeByte(1)..write(o.date)
     ..writeByte(2)..write(o.battery)
     ..writeByte(3)..write(o.stress)
     ..writeByte(4)..write(o.focus)
     ..writeByte(5)..write(o.mood)
     ..writeByte(6)..write(o.sleep)
     ..writeByte(7)..write(o.social)
     ..writeByte(8)..write(o.custom1)
     ..writeByte(9)..write(o.custom2)
     ..writeByte(10)..write(o.locked);
  }
}
