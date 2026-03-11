import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class DatabaseService {
  static const String _runnersBoxName = 'runners';
  static const String _scansBoxName = 'scans';
  static const String _settingsBoxName = 'settings';
  static const String _syncQueueBoxName = 'sync_queue';
  static const String _localRacesBoxName = 'local_races';
  static const String _localEntriesBoxName = 'local_entries';

  late Box<Runner> _runnersBox;
  late Box<Scan> _scansBox;
  late Box<dynamic> _settingsBox;
  late Box<SyncItem> _syncQueueBox;
  late Box<LocalRace> _localRacesBox;
  late Box<LocalEntry> _localEntriesBox;

  final Uuid _uuid = const Uuid();

  Future<void> init() async {
    // Open boxes
    _runnersBox = await Hive.openBox<Runner>(_runnersBoxName);
    _scansBox = await Hive.openBox<Scan>(_scansBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _syncQueueBox = await Hive.openBox<SyncItem>(_syncQueueBoxName);
    _localRacesBox = await Hive.openBox(_localRacesBoxName);
    _localEntriesBox = await Hive.openBox<LocalEntry>(_localEntriesBoxName);
  }

  // Runner operations
  Future<void> saveRunner(Runner runner) async {
    await _runnersBox.put(runner.id, runner);
  }

  Runner? getRunner(String id) {
    return _runnersBox.get(id);
  }

  bool runnerExists(String id) {
    return _runnersBox.containsKey(id);
  }

  List<Runner> getAllRunners() {
    return _runnersBox.values.toList();
  }

  Future<void> deleteRunner(String id) async {
    await _runnersBox.delete(id);
  }

  // Scan operations
  Future<void> saveScan(Scan scan) async {
    await _scansBox.put(scan.id, scan);
  }

  List<Scan> getAllScans() {
    return _scansBox.values.toList();
  }

  List<Scan> getScansBySession(String sessionId) {
    return _scansBox.values.where((scan) => scan.sessionId == sessionId).toList();
  }

  List<Scan> getScansByRunner(String runnerId) {
    return _scansBox.values.where((scan) => scan.runnerId == runnerId).toList();
  }

  DateTime? getLastScanTimeForRunner(String runnerId) {
    final scans = getScansByRunner(runnerId);
    if (scans.isEmpty) return null;
    return scans.map((s) => s.timestamp).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  Future<void> deleteScan(String id) async {
    await _scansBox.delete(id);
  }

  Future<void> clearAllScans() async {
    await _scansBox.clear();
  }

  // Session operations
  String? getCurrentSessionId() {
    return _settingsBox.get('current_session_id');
  }

  Future<void> startSession() async {
    final sessionId = _uuid.v4();
    await _settingsBox.put('current_session_id', sessionId);
    await _settingsBox.put('session_start_time', DateTime.now());
  }

  Future<void> endSession() async {
    await _settingsBox.put('current_session_id', null);
    await _settingsBox.put('session_end_time', DateTime.now());
  }

  bool isSessionActive() {
    return getCurrentSessionId() != null;
  }

  // Export data
  String exportScansToCsv() {
    final scans = getAllScans();
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Runner Name,Runner ID,Timestamp,Session ID');
    
    // Data rows
    for (final scan in scans) {
      buffer.writeln(
        '${scan.runnerName},${scan.runnerId},${scan.timestamp.toIso8601String()},${scan.sessionId ?? ''}',
      );
    }
    
    return buffer.toString();
  }

  Future<void> close() async {
    await _runnersBox.close();
    await _scansBox.close();
    await _settingsBox.close();
    await _syncQueueBox.close();
    await _localRacesBox.close();
    await _localEntriesBox.close();
  }

  // Local race operations
  List<LocalRace> getLocalRaces() {
    final races = _localRacesBox.values.cast<LocalRace>().toList();
    debugPrint('💾 DB: getLocalRaces() - Hive box has ${_localRacesBox.length} items, returning ${races.length} races');
    for (var race in races) {
      debugPrint('   - ${race.id}: ${race.name} (${race.status})');
    }
    return races;
  }

  Future<void> saveLocalRace(LocalRace race) async {
    debugPrint('💾 DB: saveLocalRace(${race.name}) - id: ${race.id}');
    await _localRacesBox.put(race.id, race);
    debugPrint('💾 DB: ✅ Saved to Hive. Box now has ${_localRacesBox.length} items');
  }

  LocalRace? getLocalRace(String id) {
    return _localRacesBox.get(id);
  }

  Future<void> updateLocalRace(String id, Map<String, dynamic> updates) async {
    final race = getLocalRace(id);
    if (race != null) {
      final updatedRace = LocalRace(
        id: race.id,
        name: updates['name'] ?? race.name,
        description: updates['description'] ?? race.description,
        raceDate: updates['race_date'] ?? race.raceDate,
        status: updates['status'] ?? race.status,
        startTime: updates['start_time'] ?? race.startTime,
        endTime: updates['end_time'] ?? race.endTime,
        entryCount: updates['entry_count'] ?? race.entryCount,
        scanCount: updates['scan_count'] ?? race.scanCount,
        createdAt: race.createdAt,
        updatedAt: DateTime.now(),
      );
      await _localRacesBox.put(id, updatedRace);
    }
  }

  Future<void> deleteLocalRace(String id) async {
    await _localRacesBox.delete(id);
  }

  // Local entry operations
  List<LocalEntry> getLocalEntries() {
    return _localEntriesBox.values.toList();
  }

  Future<void> saveLocalEntry(LocalEntry entry) async {
    await _localEntriesBox.put(entry.id, entry);
  }

  LocalEntry? getLocalEntry(String id) {
    return _localEntriesBox.get(id);
  }

  Future<void> deleteLocalEntry(String id) async {
    await _localEntriesBox.delete(id);
  }

  List<LocalEntry> getEntriesForRace(String raceId) {
    return _localEntriesBox.values
        .where((entry) => entry.raceId == raceId)
        .toList();
  }
  
  // Sync queue operations
  Future<void> addToSyncQueue(SyncItem item) async {
    await _syncQueueBox.put(item.id, item);
  }
  
  List<SyncItem> getPendingSyncItems() {
    return _syncQueueBox.values.where((item) => !item.isSynced).toList();
  }
  
  Future<void> markSynced(String itemId) async {
    final item = _syncQueueBox.get(itemId);
    if (item != null) {
      item.isSynced = true;
      await item.save();
    }
  }
  
  Future<void> removeSyncItem(String itemId) async {
    await _syncQueueBox.delete(itemId);
  }
  
  Future<void> clearSyncQueue() async {
    await _syncQueueBox.clear();
  }

  // Settings helpers
  String? getDeviceId() {
    return _settingsBox.get('device_id');
  }
  
  String generateDeviceId() {
    return _uuid.v4();
  }
  
  Future<void> setDeviceId(String id) async {
    await _settingsBox.put('device_id', id);
  }
  
  DateTime? getLastSyncTime() {
    final value = _settingsBox.get('last_sync_time');
    return value is DateTime ? value : null;
  }
  
  Future<void> setLastSyncTime(DateTime time) async {
    await _settingsBox.put('last_sync_time', time);
  }
}
