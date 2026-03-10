// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalEntryAdapter extends TypeAdapter<LocalEntry> {
  @override
  final int typeId = 5;

  @override
  LocalEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalEntry(
      id: fields[0] as String,
      raceId: fields[1] as String,
      runnerName: fields[2] as String,
      runnerGuid: fields[3] as String,
      sex: fields[4] as String?,
      dateOfBirth: fields[5] as DateTime?,
      bibNumber: fields[6] as int?,
      createdAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LocalEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.raceId)
      ..writeByte(2)
      ..write(obj.runnerName)
      ..writeByte(3)
      ..write(obj.runnerGuid)
      ..writeByte(4)
      ..write(obj.sex)
      ..writeByte(5)
      ..write(obj.dateOfBirth)
      ..writeByte(6)
      ..write(obj.bibNumber)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
