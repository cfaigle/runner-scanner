import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'package:uuid/uuid.dart';

class AppState extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final QRCodeService _qrCodeService = QRCodeService();
  final ShareService _shareService = ShareService();
  final FlutterTts _flutterTts = FlutterTts();
  final Uuid _uuid = const Uuid();

  SyncService? _syncService;
  Timer? _autoSyncTimer;
  SyncResult? _lastSyncResult;

  bool _isSessionActive = false;
  String? _currentSessionId;
  DateTime? _sessionStartTime;

  // Server sync (optional)
  ApiClient? _apiClient;
  bool _isConnectedToServer = false;
  String? _serverUrl;
  String? _authToken;
  String? _currentUserId;
  String? _currentRaceId;
  List<Race> _serverRaces = [];
  List<RaceEntry> _raceEntries = [];
  List<ResultEntry> _raceResults = [];

  // Local races (PRIMARY DATA SOURCE)
  List<LocalRace> _localRaces = [];
  List<LocalEntry> _localEntries = [];

  // Track last scan times per runner for 10-second cooldown
  final Map<String, DateTime> _lastScanTimes = {};
  final Map<String, int> _lapCounts = {};

  // Getters - Local races are primary
  bool get isSessionActive => _isSessionActive;
  String? get currentSessionId => _currentSessionId;
  DateTime? get sessionStartTime => _sessionStartTime;

  // Server getters
  bool get isConnectedToServer => _isConnectedToServer;
  String? get serverUrl => _serverUrl;
  String? get currentRaceId => _currentRaceId;
  List<Race> get serverRaces => _serverRaces;
  List<RaceEntry> get raceEntries => _raceEntries;
  List<ResultEntry> get raceResults => _raceResults;
  ApiClient? get apiClient => _apiClient;
  SyncResult? get lastSyncResult => _lastSyncResult;
  bool get isSyncing => _autoSyncTimer != null && _autoSyncTimer!.isActive;

  // Local race getters (PRIMARY)
  List<LocalRace> get localRaces => _localRaces;
  List<LocalEntry> get localEntries => _localEntries;
  
  LocalRace? get currentLocalRace {
    if (_currentRaceId == null) return null;
    try {
      return _localRaces.firstWhere((r) => r.id == _currentRaceId);
    } catch (e) {
      return null;
    }
  }

  List<LocalEntry> getEntriesForRace(String raceId) {
    return _localEntries.where((e) => e.raceId == raceId).toList();
  }

  int getEntryCountForRace(String raceId) {
    return getEntriesForRace(raceId).length;
  }

  int getScanCountForRace(String raceId) {
    final scans = getAllScans();
    return scans.where((s) => s.sessionId == _currentSessionId).length;
  }

  // Combined races list (local + server)
  List<dynamic> get allRaces {
    // Return local races primarily, could merge with server races later
    return _localRaces;
  }

  Future<void> init() async {
    await _databaseService.init();
    _isSessionActive = _databaseService.isSessionActive();
    _currentSessionId = _databaseService.getCurrentSessionId();
    
    // Load local races
    await _loadLocalRaces();
    
    notifyListeners();

    // Initialize TTS
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);

    // Generate device ID if not exists
    if (_databaseService.getDeviceId() == null) {
      await _databaseService.setDeviceId(_databaseService.generateDeviceId());
    }
  }

  // ========== LOCAL RACE MANAGEMENT ==========

  Future<void> _loadLocalRaces() async {
    _localRaces = _databaseService.getLocalRaces().cast<LocalRace>().toList();
    notifyListeners();
  }

  Future<LocalRace> createLocalRace({
    required String name,
    String? description,
    required DateTime raceDate,
  }) async {
    final race = LocalRace(
      id: _uuid.v4(),
      name: name,
      description: description,
      raceDate: raceDate,
      status: 'draft',
      entryCount: 0,
      scanCount: 0,
    );

    await _databaseService.saveLocalRace(race);
    await _loadLocalRaces();

    // Haptic feedback
    HapticFeedback.lightImpact();

    return race;
  }

  Future<void> updateLocalRace(String raceId, Map<String, dynamic> updates) async {
    await _databaseService.updateLocalRace(raceId, updates);
    await _loadLocalRaces();
    notifyListeners();
  }

  Future<void> deleteLocalRace(String raceId) async {
    await _databaseService.deleteLocalRace(raceId);
    final entries = getEntriesForRace(raceId);
    for (final entry in entries) {
      await _databaseService.deleteLocalEntry(entry.id);
    }
    _localEntries.removeWhere((e) => e.raceId == raceId);
    await _loadLocalRaces();
    if (_currentRaceId == raceId) _currentRaceId = null;
    notifyListeners();
  }

  Future<void> startLocalRace(String raceId) async {
    await _databaseService.updateLocalRace(raceId, {'status': 'active', 'start_time': DateTime.now()});
    await _loadLocalRaces();
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  Future<void> stopLocalRace(String raceId) async {
    await _databaseService.updateLocalRace(raceId, {'status': 'completed', 'end_time': DateTime.now()});
    await _loadLocalRaces();
    HapticFeedback.heavyImpact();
    notifyListeners();
  }

  Future<void> selectLocalRace(String raceId) async {
    _currentRaceId = raceId;
    await loadLocalEntries();
    notifyListeners();
  }

  // ========== LOCAL ENTRY MANAGEMENT ==========

  Future<LocalEntry> createLocalEntry({
    required String raceId,
    required String runnerName,
    String? sex,
    DateTime? dateOfBirth,
    int? bibNumber,
  }) async {
    final entry = LocalEntry(
      id: _uuid.v4(),
      raceId: raceId,
      runnerName: runnerName,
      runnerGuid: _uuid.v4(),
      sex: sex,
      dateOfBirth: dateOfBirth,
      bibNumber: bibNumber,
    );
    
    await _databaseService.saveLocalEntry(entry);
    _localEntries.add(entry);
    
    // Update race entry count
    await _databaseService.updateLocalRace(raceId, {
      'entry_count': getEntryCountForRace(raceId),
    });
    await _loadLocalRaces();
    
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    notifyListeners();
    
    return entry;
  }

  Future<void> deleteLocalEntry(String entryId) async {
    final entry = _localEntries.firstWhere((e) => e.id == entryId);
    await _databaseService.deleteLocalEntry(entryId);
    _localEntries.removeWhere((e) => e.id == entryId);
    
    // Update race entry count
    await _databaseService.updateLocalRace(entry.raceId, {
      'entry_count': getEntryCountForRace(entry.raceId),
    });
    await _loadLocalRaces();
    
    notifyListeners();
  }

  Future<void> loadLocalEntries() async {
    if (_currentRaceId == null) {
      _localEntries = [];
    } else {
      _localEntries = getEntriesForRace(_currentRaceId!);
    }
    notifyListeners();
  }

  // ========== SERVER CONNECTION (OPTIONAL) ==========

  Future<void> connectToServer(String url) async {
    _apiClient = ApiClient(
      baseUrl: url,
      onScanAnnouncement: _handleScanAnnouncement,
    );
    _serverUrl = url;
    _isConnectedToServer = true;

    // Create sync service
    _syncService = SyncService(
      databaseService: _databaseService,
      apiClient: _apiClient!,
    );

    // Start auto-sync
    _startAutoSync();
    
    // Haptic feedback
    HapticFeedback.lightImpact();

    notifyListeners();
  }

  void _startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 5), (_) => _autoSync());
    debugPrint('🔄 Auto-sync started (every 5 seconds)');
  }

  Future<void> _autoSync() async {
    if (_syncService == null || !isConnectedToServer) return;

    try {
      _lastSyncResult = await _syncService!.sync();
      notifyListeners();
    } catch (e) {
      debugPrint('Auto-sync failed: $e');
    }
  }

  Future<void> login(String username, String password) async {
    if (_apiClient == null) {
      throw Exception('Not connected to server');
    }

    final data = await _apiClient!.login(username, password);
    _authToken = data['access_token'];
    _currentUserId = data['user']['id'];

    // Now load races after login
    await loadServerRaces();
    
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    notifyListeners();
  }

  Future<void> loadServerRaces() async {
    if (_apiClient == null) return;
    _serverRaces = await _apiClient!.getRaces();
    notifyListeners();
  }

  void disconnectFromServer() {
    stopAutoSync();
    _apiClient?.dispose();
    _apiClient = null;
    _syncService = null;
    _isConnectedToServer = false;
    _serverUrl = null;
    _serverRaces = [];
    _authToken = null;
    _currentUserId = null;
    notifyListeners();
  }

  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    debugPrint('⏹️ Auto-sync stopped');
  }

  // ========== RUNNER MANAGEMENT (LOCAL) ==========

  Future<void> saveRunner(Runner runner) async {
    await _databaseService.saveRunner(runner);
    notifyListeners();
  }

  Runner? getRunner(String id) {
    return _databaseService.getRunner(id);
  }

  bool runnerExists(String id) {
    return _databaseService.runnerExists(id);
  }

  List<Runner> getAllRunners() {
    return _databaseService.getAllRunners();
  }

  // ========== SCAN MANAGEMENT ==========

  List<Scan> getAllScans() {
    return _databaseService.getAllScans();
  }

  Future<void> recordScan(Runner runner, {String? entryId}) async {
    final scan = Scan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      runnerId: runner.id,
      runnerName: runner.name,
      timestamp: DateTime.now(),
      sessionId: _currentSessionId,
    );

    // Save locally FIRST (always works)
    await _databaseService.saveScan(scan);

    // Track lap count
    _lapCounts[runner.id] = (_lapCounts[runner.id] ?? 0) + 1;

    // Sync to server if connected (background, non-blocking)
    if (_apiClient != null && entryId != null && _currentRaceId != null) {
      try {
        await _apiClient!.createScan(
          raceId: _currentRaceId!,
          entryId: entryId,
          runnerGuid: runner.id,
          lapNumber: _lapCounts[runner.id],
        );
      } catch (e) {
        // Store for later sync - scan is already saved locally
        debugPrint('Failed to sync scan (saved locally): $e');
      }
    }

    _lastScanTimes[runner.id] = DateTime.now();
    
    // Haptic feedback for scan
    HapticFeedback.lightImpact();
    
    notifyListeners();
  }

  bool canScanRunner(String runnerId) {
    final lastScan = _lastScanTimes[runnerId];
    if (lastScan == null) return true;

    final now = DateTime.now();
    final difference = now.difference(lastScan);
    return difference.inSeconds >= 10;
  }

  int getCooldownSeconds(String runnerId) {
    final lastScan = _lastScanTimes[runnerId];
    if (lastScan == null) return 0;

    final now = DateTime.now();
    final difference = now.difference(lastScan);
    final remaining = 10 - difference.inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  // ========== SESSION MANAGEMENT ==========

  Future<void> startSession() async {
    await _databaseService.startSession();
    _isSessionActive = true;
    _currentSessionId = _databaseService.getCurrentSessionId();
    _sessionStartTime = DateTime.now();
    notifyListeners();
  }

  Future<void> stopSession() async {
    await _databaseService.endSession();
    _isSessionActive = false;
    _currentSessionId = null;
    _sessionStartTime = null;
    notifyListeners();
  }

  // ========== VOICE ANNOUNCEMENTS ==========

  void _handleScanAnnouncement(dynamic announcement) {
    if (announcement != null) {
      _flutterTts.speak('Runner ${announcement.runnerName ?? "scanned"}');
    }
    notifyListeners();
  }

  Future<void> _speakAnnouncement(String runnerName, String runnerId) async {
    final text = 'Runner $runnerName';
    await _flutterTts.speak(text);
  }

  void speakAnnouncement(String runnerName, String runnerId) {
    _speakAnnouncement(runnerName, runnerId);
  }

  int getLapNumber(String runnerId) {
    return _lapCounts[runnerId] ?? 1;
  }

  // ========== QR CODE ==========

  String generateRunnerQRCode(Runner runner) {
    return _qrCodeService.generateRunnerQRCode(runner);
  }

  Runner parseRunnerQRCode(String qrData) {
    return _qrCodeService.parseRunnerQRCode(qrData);
  }

  String generateRunnerId() {
    return _qrCodeService.generateRunnerId();
  }

  // ========== EXPORT ==========

  Future<void> exportScans() async {
    final csvData = _databaseService.exportScansToCsv();
    await _shareService.exportScans(csvData);
  }

  @override
  void dispose() {
    _databaseService.close();
    super.dispose();
  }
}
