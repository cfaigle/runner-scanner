import 'package:equatable/equatable.dart';

abstract class ScanEvent extends Equatable {
  const ScanEvent();

  @override
  List<Object?> get props => [];
}

class RecordScan extends ScanEvent {
  final String runnerId;
  final String runnerName;
  final String raceId;

  const RecordScan({
    required this.runnerId,
    required this.runnerName,
    required this.raceId,
  });

  @override
  List<Object?> get props => [runnerId, runnerName, raceId];
}

class ClearScanMessage extends ScanEvent {}
