part of 'settings.dart';
class SettingsAdapter extends TypeAdapter<Settings>{
  @override final int typeId=8;
  @override Settings read(BinaryReader r){
    final n=r.readByte(); final f=<int,dynamic>{}; for(var i=0;i<n;i++){ f[r.readByte()]=r.read(); }
    return Settings(
      id: f[0] as String,
      pinHash: f[1] as String?,
      exportDir: f[2] as String?,
      allowOsBackup: f[3] as bool,
      theme: f[4] as String,
      pillOnTimeToleranceMinutes: (f[5] as int?) ?? 60,
      refillThresholdDays: (f[6] as int?) ?? 5,
    );
  }
  @override void write(BinaryWriter w, Settings o){
    w..writeByte(7)
     ..writeByte(0)..write(o.id)
     ..writeByte(1)..write(o.pinHash)
     ..writeByte(2)..write(o.exportDir)
     ..writeByte(3)..write(o.allowOsBackup)
     ..writeByte(4)..write(o.theme)
     ..writeByte(5)..write(o.pillOnTimeToleranceMinutes)
     ..writeByte(6)..write(o.refillThresholdDays);
  }
}
