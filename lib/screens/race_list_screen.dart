import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import 'home_screen.dart';

class RaceListScreen extends StatelessWidget {
  final Function(dynamic race) onRaceSelected;

  const RaceListScreen({super.key, required this.onRaceSelected});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.races.isEmpty) {
          return _buildEmptyView(appState, context);
        }

        return _buildRaceList(context, appState);
      },
    );
  }

  Widget _buildEmptyView(AppState appState, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            appState.isConnectedToServer ? Icons.event_busy : Icons.cloud_off,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            appState.isConnectedToServer ? 'No races yet' : 'Offline Mode',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              appState.isConnectedToServer
                  ? 'Create a race on the web server'
                  : 'Connect to server to load races',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          if (!appState.isConnectedToServer) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Trigger login from parent HomeScreen
                HomeScreen.of(context)?.showLoginModal();
              },
              icon: const Icon(Icons.cloud),
              label: const Text('Connect to Server'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRaceList(BuildContext context, AppState appState) {
    return RefreshIndicator(
      onRefresh: () => appState.loadRaces(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appState.races.length,
        itemBuilder: (context, index) {
          final race = appState.races[index];
          return _buildRaceCard(context, race, appState);
        },
      ),
    );
  }

  Widget _buildRaceCard(BuildContext context, dynamic race, AppState appState) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => onRaceSelected(race),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      race.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  _buildStatusChip(race.status),
                ],
              ),
              if (race.description != null && race.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  race.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, yyyy').format(race.raceDate),
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.flag, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    race.raceTime ?? 'N/A',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  const Spacer(),
                  _buildCountBadge(Icons.people, race.entryCount),
                  const SizedBox(width: 8),
                  _buildCountBadge(Icons.timer, race.scanCount),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    String displayStatus;

    switch (status) {
      case 'active':
        color = Colors.green;
        icon = Icons.play_circle;
        displayStatus = 'IN PROGRESS';
        break;
      case 'completed':
        color = Colors.grey;
        icon = Icons.check_circle;
        displayStatus = 'COMPLETED';
        break;
      default:
        color = Colors.orange;
        icon = Icons.circle_outlined;
        displayStatus = 'UPCOMING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            displayStatus,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge(IconData icon, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
