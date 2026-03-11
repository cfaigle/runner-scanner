import 'package:equatable/equatable.dart';

class RaceEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final DateTime raceDate;
  final String status; // draft, active, completed
  final DateTime? startTime;
  final DateTime? endTime;
  final int entryCount;
  final int scanCount;

  const RaceEntity({
    required this.id,
    required this.name,
    this.description,
    required this.raceDate,
    required this.status,
    this.startTime,
    this.endTime,
    this.entryCount = 0,
    this.scanCount = 0,
  });

  bool get isDraft => status == 'draft';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        raceDate,
        status,
        startTime,
        endTime,
        entryCount,
        scanCount,
      ];
}
