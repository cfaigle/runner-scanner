// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScanAdapter extends TypeAdapter<Scan> {
  @override
  final int typeId = 1;

  @override
  Scan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Scan(
      id: fields[0] as String,
      runnerId: fields[1] as String,
      runnerName: fields[2] as String,
      timestamp: fields[3] as DateTime,
      sessionId: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Scan obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.runnerId)
      ..writeByte(2)
      ..write(obj.runnerName)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.sessionId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
