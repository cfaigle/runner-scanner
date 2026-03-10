import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/podium.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.localEntries.isEmpty) {
          return _buildNoParticipantsView();
        }

        // Build results from local data
        final results = _buildLocalResults(appState);

        if (results.isEmpty) {
          return _buildNoResultsView();
        }

        return _buildResultsList(context, results);
      },
    );
  }

  List<RunnerResult> _buildLocalResults(AppState appState) {
    final entries = appState.localEntries;
    final results = <RunnerResult>[];

    for (final entry in entries) {
      // Get scans for this runner
      final scans = appState.getAllScans()
          .where((s) => s.runnerId == entry.runnerGuid)
          .toList();
      
      final lapCount = scans.length;
      double? totalTime;
      
      if (lapCount > 0) {
        final firstScan = scans.first.timestamp;
        final lastScan = scans.last.timestamp;
        totalTime = lastScan.difference(firstScan).inMilliseconds / 1000.0;
      }

      results.add(RunnerResult(
        runnerName: entry.runnerName,
        runnerId: entry.runnerGuid,
        totalTime: totalTime,
        lapCount: lapCount,
      ));
    }

    // Sort by lap count (desc), then by total time (asc)
    results.sort((a, b) {
      if (b.lapCount != a.lapCount) {
        return b.lapCount.compareTo(a.lapCount);
      }
      if (a.totalTime == null && b.totalTime == null) return 0;
      if (a.totalTime == null) return 1;
      if (b.totalTime == null) return -1;
      return a.totalTime!.compareTo(b.totalTime!);
    });

    return results;
  }

  Widget _buildNoParticipantsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.purple.shade600,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Participants',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add participants to see results',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.leaderboard_outlined,
              size: 80,
              color: Colors.orange.shade600,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Results Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start scanning runners to see results',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(BuildContext context, List<RunnerResult> results) {
    return RefreshIndicator(
      onRefresh: () async {
        // Trigger refresh
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Podium for top 3
          if (results.length >= 1)
            PodiumWidget(topThree: results.take(3).toList()),

          // Results table header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const SizedBox(width: 40, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                const Expanded(child: Text('Runner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                const SizedBox(width: 60, child: Text('Laps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center)),
                const SizedBox(width: 80, child: Text('Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.right)),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Results list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: results.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final result = results[index];
              return _buildResultRow(result, index + 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(RunnerResult result, int rank) {
    Color rankColor;
    IconData? medalIcon;

    switch (rank) {
      case 1:
        rankColor = Colors.amber.shade600;
        medalIcon = Icons.emoji_events;
        break;
      case 2:
        rankColor = Colors.grey.shade400;
        medalIcon = Icons.emoji_events;
        break;
      case 3:
        rankColor = Colors.orange.shade700;
        medalIcon = Icons.emoji_events;
        break;
      default:
        rankColor = Colors.grey.shade600;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 40,
            child: Center(
              child: medalIcon != null
                  ? Icon(medalIcon, color: rankColor, size: 24)
                  : Text(
                      '#$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: rankColor,
                      ),
                    ),
            ),
          ),

          // Runner info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.runnerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  result.runnerId.substring(0, 8),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          // Laps
          SizedBox(
            width: 60,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${result.lapCount}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Time
          SizedBox(
            width: 80,
            child: Text(
              _formatTime(result.totalTime),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: result.totalTime != null ? Colors.green.shade700 : Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(double? seconds) {
    if (seconds == null) return '--:--';
    final duration = Duration(milliseconds: (seconds * 1000).round());
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    final millis = (duration.inMilliseconds % 1000) ~/ 10;
    return '$minutes:${secs.toString().padLeft(2, '0')}.$millis';
  }
}
