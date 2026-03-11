import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/services.dart';
import '../../../models/models.dart';
import 'scan_event.dart';
import 'scan_state.dart';

class ScanBloc extends Bloc<ScanEvent, ScanState> {
  final DatabaseService _databaseService;
  final Map<String, DateTime> _lastScanTimes = {};
  final Map<String, int> _lapCounts = {};
  Timer? _cooldownTimer;

  ScanBloc(this._databaseService) : super(ScanInitial()) {
    on<RecordScan>(_onRecordScan);
    on<ClearScanMessage>(_onClearScanMessage);
  }

  Future<void> _onRecordScan(RecordScan event, Emitter<ScanState> emit) async {
    try {
      debugPrint('📱 SCAN: Recording scan for ${event.runnerName} (${event.runnerId})');

      // Check cooldown
      final lastScan = _lastScanTimes[event.runnerId];
      if (lastScan != null) {
        final now = DateTime.now();
        final difference = now.difference(lastScan);
        if (difference.inSeconds < 10) {
          final remaining = 10 - difference.inSeconds;
          debugPrint('⏱️ SCAN: Cooldown active - ${remaining}s remaining');
          emit(ScanCooldown(remaining));
          
          // Start countdown timer
          _cooldownTimer?.cancel();
          _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            final newLastScan = _lastScanTimes[event.runnerId];
            if (newLastScan == null) {
              timer.cancel();
              return;
            }
            final newNow = DateTime.now();
            final newDifference = newNow.difference(newLastScan);
            final newRemaining = 10 - newDifference.inSeconds;
            
            if (newRemaining <= 0) {
              timer.cancel();
              emit(ScanInitial());
            } else {
              emit(ScanCooldown(newRemaining));
            }
          });
          return;
        }
      }

      // Update lap count
      _lapCounts[event.runnerId] = (_lapCounts[event.runnerId] ?? 0) + 1;
      final lapNumber = _lapCounts[event.runnerId]!;

      // Record scan
      final scan = Scan(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        runnerId: event.runnerId,
        runnerName: event.runnerName,
        timestamp: DateTime.now(),
        sessionId: _databaseService.getCurrentSessionId(),
      );

      await _databaseService.saveScan(scan);
      _lastScanTimes[event.runnerId] = DateTime.now();

      // Haptic feedback
      HapticFeedback.mediumImpact();

      debugPrint('✅ SCAN: Recorded lap $lapNumber for ${event.runnerName}');

      emit(ScanSuccess(
        runnerName: event.runnerName,
        lapNumber: lapNumber,
        message: '✅ ${event.runnerName} - Lap $lapNumber',
      ));

      // Auto-clear message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (!isClosed) {
          add(ClearScanMessage());
        }
      });
    } catch (e) {
      debugPrint('❌ SCAN: Error - $e');
      emit(ScanError('Failed to record scan: $e'));
    }
  }

  Future<void> _onClearScanMessage(ClearScanMessage event, Emitter<ScanState> emit) async {
    emit(ScanInitial());
  }

  int getLapNumber(String runnerId) {
    return _lapCounts[runnerId] ?? 1;
  }

  @override
  Future<void> close() {
    _cooldownTimer?.cancel();
    return super.close();
  }
}
