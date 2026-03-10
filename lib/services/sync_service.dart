import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../models/local_race.dart';

class SyncService {
  final DatabaseService _databaseService;
  final ApiClient _apiClient;

  SyncService({
    required DatabaseService databaseService,
    required ApiClient apiClient,
  })  : _databaseService = databaseService,
        _apiClient = apiClient;

  /// Sync local data with server
  /// Returns map with counts of synced items
  Future<SyncResult> sync() async {
    try {
      debugPrint('🔄 Starting sync...');

      // STEP 1: Upload local data to server
      final uploadResult = await _uploadPendingItems();

      // STEP 2: Download server data
      final downloadResult = await _downloadServerData();

      // STEP 3: Update last sync time
      await _databaseService.setLastSyncTime(DateTime.now().toUtc());

      debugPrint('✅ Sync complete: ${uploadResult.uploaded} uploaded, ${downloadResult.downloaded} downloaded');

      return SyncResult(
        success: true,
        uploaded: uploadResult.uploaded,
        downloaded: downloadResult.downloaded,
        errors: [...uploadResult.errors, ...downloadResult.errors],
      );
    } catch (e) {
      debugPrint('❌ Sync failed: $e');
      return SyncResult(
        success: false,
        uploaded: 0,
        downloaded: 0,
        errors: [e.toString()],
      );
    }
  }

  Future<SyncResult> _uploadPendingItems() async {
    final pendingItems = _databaseService.getPendingSyncItems();
    int uploaded = 0;
    final errors = <String>[];

    debugPrint('📤 Uploading ${pendingItems.length} pending items...');

    for (final item in pendingItems) {
      try {
        await _processSyncItem(item);
        await _databaseService.markSynced(item.id);
        uploaded++;
      } catch (e) {
        debugPrint('Failed to sync item ${item.id}: $e');
        errors.add('Failed to sync ${item.operation}: $e');
      }
    }

    return SyncResult(
      success: true,
      uploaded: uploaded,
      downloaded: 0,
      errors: errors,
    );
  }

  Future<void> _processSyncItem(SyncItem item) async {
    switch (item.operation) {
      case SyncOperation.createRace:
        // Race already created on server when made, just mark synced
        break;
      case SyncOperation.createRunner:
        // Runner already created on server when made
        break;
      case SyncOperation.createScan:
        // Scan already created on server when made
        break;
      case SyncOperation.startRace:
        await _apiClient.startRace(item.data['raceId'] as String);
        break;
      case SyncOperation.stopRace:
        await _apiClient.stopRace(item.data['raceId'] as String);
        break;
      case SyncOperation.updateRace:
        // TODO: Implement update race endpoint
        break;
    }
  }

  Future<SyncResult> _downloadServerData() async {
    int downloaded = 0;
    final errors = <String>[];

    try {
      // Download all races
      final races = await _apiClient.getRaces();
      for (final race in races) {
        final localRace = LocalRace(
          id: race.id,
          name: race.name,
          description: race.description,
          raceDate: race.raceDate,
          status: race.status,
          startTime: race.startTime,
          entryCount: race.entryCount,
          scanCount: race.scanCount,
        );
        await _databaseService.saveLocalRace(localRace);
        downloaded++;
      }

      debugPrint('📥 Downloaded $downloaded races from server');
    } catch (e) {
      errors.add('Failed to download races: $e');
    }

    return SyncResult(
      success: true,
      uploaded: 0,
      downloaded: downloaded,
      errors: errors,
    );
  }

  /// Queue an operation for later sync
  Future<void> queueOperation({
    required SyncOperation operation,
    required Map<String, dynamic> data,
  }) async {
    final item = SyncItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      operation: operation,
      data: data,
    );
    await _databaseService.addToSyncQueue(item);
    debugPrint('📝 Queued sync operation: $operation');
  }
}

class SyncResult {
  final bool success;
  final int uploaded;
  final int downloaded;
  final List<String> errors;

  SyncResult({
    required this.success,
    required this.uploaded,
    required this.downloaded,
    required this.errors,
  });

  @override
  String toString() {
    return 'SyncResult(success: $success, uploaded: $uploaded, downloaded: $downloaded, errors: ${errors.length})';
  }
}
