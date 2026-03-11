import 'package:equatable/equatable.dart';
import '../../../domain/entities/race_entity.dart';

abstract class RaceEvent extends Equatable {
  const RaceEvent();

  @override
  List<Object?> get props => [];
}

class LoadRaces extends RaceEvent {}

class LoadRacesSuccess extends RaceEvent {
  final List<RaceEntity> races;

  const LoadRacesSuccess(this.races);

  @override
  List<Object?> get props => [races];
}

class LoadRacesFailure extends RaceEvent {
  final String error;

  const LoadRacesFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class CreateRace extends RaceEvent {
  final String name;
  final String? description;
  final DateTime raceDate;

  const CreateRace({
    required this.name,
    this.description,
    required this.raceDate,
  });

  @override
  List<Object?> get props => [name, description, raceDate];
}

class StartRace extends RaceEvent {
  final String raceId;

  const StartRace(this.raceId);

  @override
  List<Object?> get props => [raceId];
}

class StopRace extends RaceEvent {
  final String raceId;

  const StopRace(this.raceId);

  @override
  List<Object?> get props => [raceId];
}

class SelectRace extends RaceEvent {
  final String raceId;

  const SelectRace(this.raceId);

  @override
  List<Object?> get props => [raceId];
}
