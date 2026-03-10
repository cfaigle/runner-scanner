import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class RaceStandingsScreen extends StatelessWidget {
  const RaceStandingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Race Standings'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (!appState.isConnectedToServer) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Not connected to server',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Connect to a race server to view live standings',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (appState.currentRaceId == null) {
            return const Center(
              child: Text('No race selected'),
            );
          }

          if (appState.raceResults.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return RefreshIndicator(
            onRefresh: () => appState.loadRaceResults(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Race info card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.races
                                  .firstWhere(
                                    (r) => r.id == appState.currentRaceId,
                                    orElse: () => appState.races.first,
                                  )
                                  .name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              appState.races
                                      .firstWhere(
                                        (r) => r.id == appState.currentRaceId,
                                        orElse: () => appState.races.first,
                                      )
                                      .isActive
                                  ? Icons.circle
                                  : Icons.circle_outlined,
                              color: appState.races
                                      .firstWhere(
                                        (r) => r.id == appState.currentRaceId,
                                        orElse: () => appState.races.first,
                                      )
                                      .isActive
                                  ? Colors.red
                                  : Colors.grey,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              appState.races
                                      .firstWhere(
                                        (r) => r.id == appState.currentRaceId,
                                        orElse: () => appState.races.first,
                                      )
                                      .isActive
                                  ? 'LIVE'
                                  : 'Finished',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Standings table header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 1, child: _buildHeaderCell('Pos')),
                      Expanded(flex: 3, child: _buildHeaderCell('Runner')),
                      Expanded(flex: 2, child: _buildHeaderCell('Laps')),
                      Expanded(flex: 2, child: _buildHeaderCell('Total')),
                      Expanded(flex: 2, child: _buildHeaderCell('Best')),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Standings list
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: appState.raceResults.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final result = appState.raceResults[index];
                    return _buildResultRow(context, index + 1, result);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildResultRow(BuildContext context, int position, dynamic result) {
    final isLeader = position == 1;

    return Card(
      color: isLeader ? Colors.amber.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Position
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: position <= 3
                      ? _getMedalColor(position)
                      : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  position.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: position <= 3 ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Runner info
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.entry.runnerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${result.entry.runnerGuidShort}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Laps
            Expanded(
              flex: 2,
              child: Text(
                result.lapCount.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),

            // Total time
            Expanded(
              flex: 2,
              child: Text(
                _formatTime(result.totalTime),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isLeader ? Colors.green : null,
                ),
              ),
            ),

            // Best lap
            Expanded(
              flex: 2,
              child: Text(
                _formatTime(result.bestLapTime),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMedalColor(int position) {
    switch (position) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade400;
      default:
        return Colors.grey.shade200;
    }
  }

  String _formatTime(double? seconds) {
    if (seconds == null) return '--:--';
    final mins = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    final ms = ((seconds % 1) * 100).floor();
    return '$mins:${secs.toString().padLeft(2, '0')}.${ms.toString().padLeft(2, '0')}';
  }
}
