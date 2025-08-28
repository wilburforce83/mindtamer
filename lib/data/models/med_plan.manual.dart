import 'package:hive/hive.dart';
import 'med_plan.dart';

class MedPlanAdapter extends TypeAdapter<MedPlan> {
  @override final int typeId = 4;
  @override MedPlan read(BinaryReader r){
    final n=r.readByte(); final f=<int,dynamic>{}; for(var i=0;i<n;i++){ f[r.readByte()]=r.read(); }
    return MedPlan(id:f[0] as String, name:f[1] as String, dose:f[2] as String, scheduleTimes:(f[3] as List).cast<String>(), active:f[4] as bool);
  }
  @override void write(BinaryWriter w, MedPlan o){
    w..writeByte(5)
     ..writeByte(0)..write(o.id)
     ..writeByte(1)..write(o.name)
     ..writeByte(2)..write(o.dose)
     ..writeByte(3)..write(o.scheduleTimes)
     ..writeByte(4)..write(o.active);
  }
}
