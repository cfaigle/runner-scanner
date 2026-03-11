import 'package:equatable/equatable.dart';
import '../../../domain/entities/race_entity.dart';

abstract class RaceState extends Equatable {
  const RaceState();

  @override
  List<Object?> get props => [];
}

class RaceInitial extends RaceState {}

class RaceLoading extends RaceState {}

class RaceLoaded extends RaceState {
  final List<RaceEntity> races;
  final String? selectedRaceId;

  const RaceLoaded({
    this.races = const [],
    this.selectedRaceId,
  });

  @override
  List<Object?> get props => [races, selectedRaceId];

  RaceLoaded copyWith({
    List<RaceEntity>? races,
    String? selectedRaceId,
  }) {
    return RaceLoaded(
      races: races ?? this.races,
      selectedRaceId: selectedRaceId ?? this.selectedRaceId,
    );
  }
}

class RaceError extends RaceState {
  final String error;

  const RaceError(this.error);

  @override
  List<Object?> get props => [error];
}
