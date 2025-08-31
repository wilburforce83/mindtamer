part of 'med_log.dart';
class MedLogAdapter extends TypeAdapter<MedLog> {
  @override final int typeId=5;
  @override MedLog read(BinaryReader r){ final n=r.readByte(); final f=<int,dynamic>{}; for(var i=0;i<n;i++){ f[r.readByte()]=r.read(); }
    return MedLog(
      id: f[0] as String,
      date: f[1] as DateTime,
      planId: f[2] as String,
      taken: f[3] as bool,
      time: f[4] as String,
      loggedAt: (f[5] as DateTime?),
    );
  }
  @override void write(BinaryWriter w, MedLog o){
    w..writeByte(6)
     ..writeByte(0)..write(o.id)
     ..writeByte(1)..write(o.date)
     ..writeByte(2)..write(o.planId)
     ..writeByte(3)..write(o.taken)
     ..writeByte(4)..write(o.time)
     ..writeByte(5)..write(o.loggedAt);
  }
}
