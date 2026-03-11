import 'package:equatable/equatable.dart';

abstract class ScanState extends Equatable {
  const ScanState();

  @override
  List<Object?> get props => [];
}

class ScanInitial extends ScanState {}

class ScanSuccess extends ScanState {
  final String runnerName;
  final int lapNumber;
  final String message;

  const ScanSuccess({
    required this.runnerName,
    required this.lapNumber,
    required this.message,
  });

  @override
  List<Object?> get props => [runnerName, lapNumber, message];
}

class ScanCooldown extends ScanState {
  final int secondsRemaining;

  const ScanCooldown(this.secondsRemaining);

  @override
  List<Object?> get props => [secondsRemaining];
}

class ScanError extends ScanState {
  final String error;

  const ScanError(this.error);

  @override
  List<Object?> get props => [error];
}
