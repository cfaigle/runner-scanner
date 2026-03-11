import 'package:equatable/equatable.dart';

class ScanEntity extends Equatable {
  final String id;
  final String runnerId;
  final String runnerName;
  final DateTime timestamp;
  final int lapNumber;
  final String? sessionId;

  const ScanEntity({
    required this.id,
    required this.runnerId,
    required this.runnerName,
    required this.timestamp,
    required this.lapNumber,
    this.sessionId,
  });

  @override
  List<Object?> get props => [id, runnerId, runnerName, timestamp, lapNumber, sessionId];
}
