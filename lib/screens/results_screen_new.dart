import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/local_entry.dart';

class ResultsScreenNew extends StatelessWidget {
  final dynamic race;

  const ResultsScreenNew({super.key, required this.race});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final entries = appState.getEntriesForRace(race.id);
        final allScans = appState.getAllScans();
        
        // Build results
        final results = <_RunnerResult>[];
        
        for (final entry in entries) {
          // Get scans for this runner
          final runnerScans = allScans
              .where((s) => s.runnerId == entry.runnerGuid)
              .toList();
          
          final lapCount = runnerScans.length;
          DateTime? firstScan;
          DateTime? lastScan;
          
          if (lapCount > 0) {
            firstScan = runnerScans.map((s) => s.timestamp).reduce((a, b) => a.isBefore(b) ? a : b);
            lastScan = runnerScans.map((s) => s.timestamp).reduce((a, b) => a.isAfter(b) ? a : b);
          }
          
          results.add(_RunnerResult(
            entry: entry,
            lapCount: lapCount,
            firstScan: firstScan,
            lastScan: lastScan,
          ));
        }
        
        // Sort by lap count (desc), then by total time (asc)
        results.sort((a, b) {
          if (b.lapCount != a.lapCount) {
            return b.lapCount.compareTo(a.lapCount);
          }
          if (a.firstScan == null || b.firstScan == null) return 0;
          final aTime = a.lastScan!.difference(a.firstScan!);
          final bTime = b.lastScan!.difference(b.firstScan!);
          return aTime.compareTo(bTime);
        });

        if (results.isEmpty) {
          return _buildEmptyView();
        }

        return _buildResultsList(results);
      },
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.leaderboard_outlined, size: 80, color: Colors.grey.shade600),
          const SizedBox(height: 24),
          const Text(
            'No Results Yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start scanning runners to see results',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(List<_RunnerResult> results) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        final rank = index + 1;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: _buildRankBadge(rank),
            title: Text(
              result.entry.runnerName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('ID: ${result.entry.runnerGuidShort}'),
                if (result.lapCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(_formatTime(result)),
                ],
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${result.lapCount} ${result.lapCount == 1 ? 'Lap' : 'Laps'}',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankBadge(int rank) {
    Color color;
    IconData? icon;

    switch (rank) {
      case 1:
        color = Colors.amber.shade600;
        icon = Icons.emoji_events;
        break;
      case 2:
        color = Colors.grey.shade400;
        icon = Icons.emoji_events;
        break;
      case 3:
        color = Colors.orange.shade700;
        icon = Icons.emoji_events;
        break;
      default:
        color = Colors.grey.shade600;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon ?? null,
        color: color,
        size: 20,
      ),
    );
  }

  String _formatTime(_RunnerResult result) {
    if (result.firstScan == null || result.lastScan == null) {
      return '--:--';
    }
    
    final duration = result.lastScan!.difference(result.firstScan!);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final milliseconds = (duration.inMilliseconds % 1000) ~/ 10;
    
    return '$minutes:${seconds.toString().padLeft(2, '0')}.$milliseconds';
  }
}

class _RunnerResult {
  final LocalEntry entry;
  final int lapCount;
  final DateTime? firstScan;
  final DateTime? lastScan;

  _RunnerResult({
    required this.entry,
    required this.lapCount,
    this.firstScan,
    this.lastScan,
  });
}
