import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/services.dart';
import '../../../models/models.dart';
import '../../../domain/entities/race_entity.dart';
import 'race_event.dart';
import 'race_state.dart';

class RaceBloc extends Bloc<RaceEvent, RaceState> {
  final DatabaseService _databaseService;
  ApiClient? _apiClient;

  RaceBloc(this._databaseService) : super(RaceInitial()) {
    on<LoadRaces>(_onLoadRaces);
    on<CreateRace>(_onCreateRace);
    on<StartRace>(_onStartRace);
    on<StopRace>(_onStopRace);
    on<SelectRace>(_onSelectRace);
  }

  void setApiClient(ApiClient? client) {
    _apiClient = client;
  }

  Future<void> _onLoadRaces(LoadRaces event, Emitter<RaceState> emit) async {
    debugPrint('🔄 RACE BLOC: LoadRaces event received');
    emit(RaceLoading());
    
    try {
      List<LocalRace> localRaces = [];
      
      // Load from local storage first (cached)
      debugPrint('💾 RACE BLOC: Loading from Hive...');
      localRaces = _databaseService.getLocalRaces();
      debugPrint('💾 RACE BLOC: Loaded ${localRaces.length} races from Hive');
      for (var race in localRaces) {
        debugPrint('   - ${race.id}: ${race.name} (${race.status})');
      }
      
      // If connected to server, also sync
      if (_apiClient != null) {
        debugPrint('🌐 RACE BLOC: Connected to server, syncing...');
        try {
          debugPrint('🌐 RACE BLOC: Fetching races from server...');
          final serverRaces = await _apiClient!.getRaces();
          debugPrint('🌐 RACE BLOC: Received ${serverRaces.length} races from server');
          
          // Merge or update local races with server data
          for (final race in serverRaces) {
            debugPrint('   📥 Saving server race: ${race.name}');
            await _databaseService.saveLocalRace(LocalRace(
              id: race.id,
              name: race.name,
              description: race.description,
              raceDate: race.raceDate,
              status: race.status,
              startTime: race.startTime,
              entryCount: race.entryCount,
              scanCount: race.scanCount,
            ));
          }
          
          // Reload from local
          debugPrint('💾 RACE BLOC: Reloading from Hive after sync...');
          localRaces = _databaseService.getLocalRaces();
          debugPrint('💾 RACE BLOC: Now have ${localRaces.length} races in Hive');
        } catch (e) {
          debugPrint('❌ RACE BLOC: Failed to sync with server: $e');
        }
      } else {
        debugPrint('⚠️ RACE BLOC: Not connected to server, using cached data only');
      }
      
      final raceEntities = localRaces.map((r) => RaceEntity(
        id: r.id,
        name: r.name,
        description: r.description,
        raceDate: r.raceDate,
        status: r.status,
        startTime: r.startTime,
        endTime: r.endTime,
        entryCount: r.entryCount,
        scanCount: r.scanCount,
      )).toList();
      
      debugPrint('📤 RACE BLOC: Emitting RaceLoaded with ${raceEntities.length} races');
      emit(RaceLoaded(races: raceEntities));
    } catch (e) {
      debugPrint('❌ RACE BLOC: Error loading races: $e');
      emit(RaceError('Failed to load races: $e'));
    }
  }

  Future<void> _onCreateRace(CreateRace event, Emitter<RaceState> emit) async {
    try {
      final race = LocalRace(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: event.name,
        description: event.description,
        raceDate: event.raceDate,
        status: 'draft',
      );
      
      await _databaseService.saveLocalRace(race);
      add(LoadRaces());
    } catch (e) {
      emit(RaceError('Failed to create race: $e'));
    }
  }

  Future<void> _onStartRace(StartRace event, Emitter<RaceState> emit) async {
    try {
      await _databaseService.updateLocalRace(event.raceId, {
        'status': 'active',
        'start_time': DateTime.now(),
      });
      add(LoadRaces());
    } catch (e) {
      emit(RaceError('Failed to start race: $e'));
    }
  }

  Future<void> _onStopRace(StopRace event, Emitter<RaceState> emit) async {
    try {
      await _databaseService.updateLocalRace(event.raceId, {
        'status': 'completed',
        'end_time': DateTime.now(),
      });
      add(LoadRaces());
    } catch (e) {
      emit(RaceError('Failed to stop race: $e'));
    }
  }

  Future<void> _onSelectRace(SelectRace event, Emitter<RaceState> emit) async {
    final currentState = state;
    if (currentState is RaceLoaded) {
      emit(RaceLoaded(
        races: currentState.races,
        selectedRaceId: event.raceId,
      ));
    }
  }
}
