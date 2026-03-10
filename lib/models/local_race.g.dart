// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_race.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalRaceAdapter extends TypeAdapter<LocalRace> {
  @override
  final int typeId = 4;

  @override
  LocalRace read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalRace(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      raceDate: fields[3] as DateTime,
      status: fields[4] as String,
      startTime: fields[5] as DateTime?,
      endTime: fields[6] as DateTime?,
      entryCount: fields[7] as int,
      scanCount: fields[8] as int,
      createdAt: fields[9] as DateTime?,
      updatedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LocalRace obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.raceDate)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.startTime)
      ..writeByte(6)
      ..write(obj.endTime)
      ..writeByte(7)
      ..write(obj.entryCount)
      ..writeByte(8)
      ..write(obj.scanCount)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalRaceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
