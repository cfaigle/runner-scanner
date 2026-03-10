import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/models.dart';

class ApiClient {
  String baseUrl;
  String? _authToken;
  WebSocketChannel? _webSocket;
  Timer? _syncTimer;

  final Function(ScanAnnouncement)? onScanAnnouncement;

  ApiClient({required this.baseUrl, this.onScanAnnouncement}) {
    // Remove trailing slash from baseUrl to prevent double slashes
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
  }
  
  void setAuthToken(String token) {
    _authToken = token;
  }
  
  String? get authToken => _authToken;
  
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };
  
  // Authentication
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: _headers,
      body: jsonEncode({'username': username, 'password': password}),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _authToken = data['access_token'];
      return data;
    } else {
      throw ApiException('Login failed: ${response.statusCode}');
    }
  }
  
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'full_name': fullName,
      }),
    );
    
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw ApiException('Registration failed: ${response.statusCode}');
    }
  }
  
  // Races
  Future<List<Race>> getRaces({bool activeOnly = false}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/races?active_only=$activeOnly'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Race.fromJson(json)).toList();
    } else {
      throw ApiException('Failed to get races: ${response.statusCode}');
    }
  }
  
  Future<Race> createRace({
    required String name,
    String? description,
    required DateTime raceDate,
    String? raceTime,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/races'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'description': description,
        'race_date': raceDate.toIso8601String(),
        'race_time': raceTime,
      }),
    );
    
    if (response.statusCode == 201) {
      return Race.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException('Failed to create race: ${response.statusCode}');
    }
  }
  
  Future<void> startRace(String raceId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/races/$raceId/start'),
      headers: _headers,
    );
    
    if (response.statusCode != 200) {
      throw ApiException('Failed to start race: ${response.statusCode}');
    }
  }
  
  Future<void> stopRace(String raceId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/races/$raceId/stop?confirm=true'),
      headers: _headers,
    );
    
    if (response.statusCode != 200) {
      throw ApiException('Failed to stop race: ${response.statusCode}');
    }
  }
  
  Future<Map<String, dynamic>> stopRaceWithConfirmation(String raceId) async {
    // First call without confirm to get race info
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/races/$raceId/stop'),
        headers: _headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      // Expected to fail with 400 containing confirmation info
      rethrow;
    }
  }
  
  Future<Race> selectRace(String raceId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/races/$raceId/select'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return Race.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException('Failed to select race: ${response.statusCode}');
    }
  }
  
  Future<Race?> getActiveRace() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/races/active'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['active_race'] == null) return null;
      return Race.fromJson(data['active_race']);
    } else {
      throw ApiException('Failed to get active race: ${response.statusCode}');
    }
  }
  
  Future<List<Race>> getRacesByStatus(String status) async {
    return getRaces(activeOnly: status == 'active');
  }
  
  Future<RaceResults> getRaceResults(String raceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/races/$raceId/results'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return RaceResults.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException('Failed to get results: ${response.statusCode}');
    }
  }
  
  // Entries
  Future<List<RaceEntry>> getEntries({String? raceId, String? userId}) async {
    String url = '$baseUrl/api/entries?';
    if (raceId != null) url += 'race_id=$raceId&';
    if (userId != null) url += 'user_id=$userId';
    
    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => RaceEntry.fromJson(json)).toList();
    } else {
      throw ApiException('Failed to get entries: ${response.statusCode}');
    }
  }
  
  Future<RaceEntry> createEntry({
    required String raceId,
    required String userId,
    required String runnerName,
    String? sex,
    DateTime? dateOfBirth,
    int? bibNumber,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/entries'),
      headers: _headers,
      body: jsonEncode({
        'race_id': raceId,
        'user_id': userId,
        'runner_name': runnerName,
        'sex': sex,
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'bib_number': bibNumber,
      }),
    );
    
    if (response.statusCode == 201) {
      return RaceEntry.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException('Failed to create entry: ${response.statusCode}');
    }
  }
  
  // Scans
  Future<Scan> createScan({
    required String raceId,
    required String entryId,
    required String runnerGuid,
    int? lapNumber,
    String? deviceId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/scans'),
      headers: _headers,
      body: jsonEncode({
        'race_id': raceId,
        'entry_id': entryId,
        'runner_guid': runnerGuid,
        'lap_number': lapNumber,
        'device_id': deviceId,
      }),
    );
    
    if (response.statusCode == 200) {
      return Scan.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException('Failed to create scan: ${response.statusCode}');
    }
  }
  
  // WebSocket
  void connectWebSocket(String raceId) {
    final protocol = baseUrl.startsWith('https') ? 'wss' : 'ws';
    final url = baseUrl.replaceFirst(RegExp(r'^https?://'), '$protocol://');
    final wsUrl = '$url/api/scans/ws/$raceId';
    
    _webSocket = WebSocketChannel.connect(Uri.parse(wsUrl));
    
    _webSocket?.stream.listen(
      (message) {
        final data = jsonDecode(message);
        if (data['type'] == 'scan') {
          final announcement = ScanAnnouncement.fromJson(data['data']);
          onScanAnnouncement?.call(announcement);
        }
      },
      onError: (error) => debugPrint('WebSocket error: $error'),
      onDone: () => debugPrint('WebSocket closed'),
    );
  }
  
  void disconnectWebSocket() {
    _webSocket?.sink.close();
    _webSocket = null;
  }
  
  // Sync
  void startAutoSync(Duration interval, Future<void> Function() syncFunction) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) => syncFunction());
  }
  
  void stopAutoSync() {
    _syncTimer?.cancel();
  }
  
  void dispose() {
    disconnectWebSocket();
    stopAutoSync();
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  
  @override
  String toString() => message;
}

// Models for API responses
class Race {
  final String id;
  final String name;
  final String? description;
  final DateTime raceDate;
  final String? raceTime;
  final DateTime? startTime;
  final String status;  // draft, active, completed
  final DateTime? selectedAt;
  final int entryCount;
  final int scanCount;
  
  Race({
    required this.id,
    required this.name,
    this.description,
    required this.raceDate,
    this.raceTime,
    this.startTime,
    required this.status,
    this.selectedAt,
    required this.entryCount,
    required this.scanCount,
  });
  
  factory Race.fromJson(Map<String, dynamic> json) {
    return Race(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      raceDate: DateTime.parse(json['race_date']),
      raceTime: json['race_time'],
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time']) : null,
      status: json['status'] ?? 'draft',
      selectedAt: json['selected_at'] != null ? DateTime.parse(json['selected_at']) : null,
      entryCount: json['entry_count'] ?? 0,
      scanCount: json['scan_count'] ?? 0,
    );
  }
  
  bool get isActive => status == 'active';
  bool get isDraft => status == 'draft';
  bool get isCompleted => status == 'completed';
}

class RaceEntry {
  final String id;
  final String raceId;
  final String userId;
  final String runnerName;
  final String? sex;
  final DateTime? dateOfBirth;
  final int? bibNumber;
  final String runnerGuidShort;
  
  RaceEntry({
    required this.id,
    required this.raceId,
    required this.userId,
    required this.runnerName,
    this.sex,
    this.dateOfBirth,
    this.bibNumber,
    required this.runnerGuidShort,
  });
  
  factory RaceEntry.fromJson(Map<String, dynamic> json) {
    return RaceEntry(
      id: json['id'],
      raceId: json['race_id'],
      userId: json['user_id'],
      runnerName: json['runner_name'],
      sex: json['sex'],
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth']) 
          : null,
      bibNumber: json['bib_number'],
      runnerGuidShort: json['runner_guid_short'],
    );
  }
}

class RaceResults {
  final Race race;
  final List<ResultEntry> results;
  
  RaceResults({required this.race, required this.results});
  
  factory RaceResults.fromJson(Map<String, dynamic> json) {
    return RaceResults(
      race: Race.fromJson(json['race']),
      results: (json['results'] as List)
          .map((r) => ResultEntry.fromJson(r))
          .toList(),
    );
  }
}

class ResultEntry {
  final RaceEntry entry;
  final double? totalTime;
  final int lapCount;
  final double? bestLapTime;
  
  ResultEntry({
    required this.entry,
    this.totalTime,
    required this.lapCount,
    this.bestLapTime,
  });
  
  factory ResultEntry.fromJson(Map<String, dynamic> json) {
    return ResultEntry(
      entry: RaceEntry.fromJson(json['entry']),
      totalTime: json['total_time']?.toDouble(),
      lapCount: json['lap_count'] ?? 0,
      bestLapTime: json['best_lap_time']?.toDouble(),
    );
  }
}

class ScanAnnouncement {
  final String runnerName;
  final String runnerId;
  final int lapNumber;
  final String raceTime;
  final String lapTime;
  
  ScanAnnouncement({
    required this.runnerName,
    required this.runnerId,
    required this.lapNumber,
    required this.raceTime,
    required this.lapTime,
  });
  
  factory ScanAnnouncement.fromJson(Map<String, dynamic> json) {
    return ScanAnnouncement(
      runnerName: json['runner_name'],
      runnerId: json['runner_id'],
      lapNumber: json['lap_number'],
      raceTime: json['race_time'],
      lapTime: json['lap_time'],
    );
  }
}
