import 'package:hive/hive.dart';

part 'runner.g.dart';

@HiveType(typeId: 0)
class Runner extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime dateOfBirth;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  Runner({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String toJson() {
    return '{"id":"$id","name":"$name","dob":"${dateOfBirth.toIso8601String().split('T')[0]}"}';
  }

  static Runner fromJson(String json) {
    // Simple JSON parsing for QR code data
    // Expected format: {"id":"...","name":"...","dob":"..."}
    final idMatch = RegExp(r'"id":"([^"]+)"').firstMatch(json);
    final nameMatch = RegExp(r'"name":"([^"]+)"').firstMatch(json);
    final dobMatch = RegExp(r'"dob":"([^"]+)"').firstMatch(json);

    return Runner(
      id: idMatch?.group(1) ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameMatch?.group(1) ?? 'Unknown',
      dateOfBirth: DateTime.tryParse(dobMatch?.group(1) ?? '') ?? DateTime(2000),
    );
  }

  @override
  String toString() {
    return 'Runner(id: $id, name: $name, dob: $dateOfBirth)';
  }
}
