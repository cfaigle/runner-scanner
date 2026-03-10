import 'package:hive/hive.dart';

part 'sync_item.g.dart';

@HiveType(typeId: 2)
enum SyncOperation {
  @HiveField(0)
  createRace,
  @HiveField(1)
  updateRace,
  @HiveField(2)
  createRunner,
  @HiveField(3)
  createScan,
  @HiveField(4)
  startRace,
  @HiveField(5)
  stopRace,
}

@HiveType(typeId: 3)
class SyncItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  SyncOperation operation;

  @HiveField(2)
  Map<String, dynamic> data;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  bool isSynced;

  @HiveField(5)
  String? serverId;  // ID assigned by server after sync

  SyncItem({
    required this.id,
    required this.operation,
    required this.data,
    DateTime? createdAt,
    this.isSynced = false,
    this.serverId,
  }) : createdAt = createdAt ?? DateTime.now().toUtc();

  @override
  String toString() {
    return 'SyncItem(id: $id, op: $operation, synced: $isSynced)';
  }
}
