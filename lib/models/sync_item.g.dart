// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncItemAdapter extends TypeAdapter<SyncItem> {
  @override
  final int typeId = 3;

  @override
  SyncItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncItem(
      id: fields[0] as String,
      operation: fields[1] as SyncOperation,
      data: (fields[2] as Map).cast<String, dynamic>(),
      createdAt: fields[3] as DateTime?,
      isSynced: fields[4] as bool,
      serverId: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SyncItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.operation)
      ..writeByte(2)
      ..write(obj.data)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.isSynced)
      ..writeByte(5)
      ..write(obj.serverId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncOperationAdapter extends TypeAdapter<SyncOperation> {
  @override
  final int typeId = 2;

  @override
  SyncOperation read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncOperation.createRace;
      case 1:
        return SyncOperation.updateRace;
      case 2:
        return SyncOperation.createRunner;
      case 3:
        return SyncOperation.createScan;
      case 4:
        return SyncOperation.startRace;
      case 5:
        return SyncOperation.stopRace;
      default:
        return SyncOperation.createRace;
    }
  }

  @override
  void write(BinaryWriter writer, SyncOperation obj) {
    switch (obj) {
      case SyncOperation.createRace:
        writer.writeByte(0);
        break;
      case SyncOperation.updateRace:
        writer.writeByte(1);
        break;
      case SyncOperation.createRunner:
        writer.writeByte(2);
        break;
      case SyncOperation.createScan:
        writer.writeByte(3);
        break;
      case SyncOperation.startRace:
        writer.writeByte(4);
        break;
      case SyncOperation.stopRace:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncOperationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
