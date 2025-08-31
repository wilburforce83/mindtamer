part of 'med_plan.dart';

class MedPlanAdapter extends TypeAdapter<MedPlan> {
  @override final int typeId = 4;
  @override MedPlan read(BinaryReader r){
    final n=r.readByte(); final f=<int,dynamic>{}; for(var i=0;i<n;i++){ f[r.readByte()]=r.read(); }
    final p = MedPlan(
      id: f[0] as String,
      name: f[1] as String,
      dose: f[2] as String,
      scheduleTimes: (f[3] as List).cast<String>(),
      active: f[4] as bool,
    );
    // Backward compatible defaults for newer fields
    p.iconPath = (f[5] as String?);
    p.unitsPerDose = (f[6] as int?) ?? 1;
    p.startingStock = (f[7] as int?) ?? 0;
    p.remainingStock = (f[8] as int?) ?? 0;
    return p;
  }
  @override void write(BinaryWriter w, MedPlan o){
    w..writeByte(9)
     ..writeByte(0)..write(o.id)
     ..writeByte(1)..write(o.name)
     ..writeByte(2)..write(o.dose)
     ..writeByte(3)..write(o.scheduleTimes)
     ..writeByte(4)..write(o.active)
     ..writeByte(5)..write(o.iconPath)
     ..writeByte(6)..write(o.unitsPerDose)
     ..writeByte(7)..write(o.startingStock)
     ..writeByte(8)..write(o.remainingStock);
  }
}
