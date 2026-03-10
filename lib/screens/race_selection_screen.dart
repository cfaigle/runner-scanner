import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/api_client.dart';

class RaceSelectionScreen extends StatefulWidget {
  final bool showOnlyDraft;
  
  const RaceSelectionScreen({super.key, this.showOnlyDraft = false});

  @override
  State<RaceSelectionScreen> createState() => _RaceSelectionScreenState();
}

class _RaceSelectionScreenState extends State<RaceSelectionScreen> {
  bool _isLoading = true;
  List<Race> _races = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRaces();
  }

  Future<void> _loadRaces() async {
    setState(() => _isLoading = true);
    
    try {
      final appState = context.read<AppState>();
      if (widget.showOnlyDraft) {
        _races = appState.races.where((r) => r.isDraft).toList();
      } else {
        _races = appState.races;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.showOnlyDraft ? 'Select Race to Start' : 'Select Race'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _races.isEmpty
                  ? _buildEmptyView()
                  : _buildRaceList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Failed to load races',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadRaces,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.showOnlyDraft ? Icons.playlist_add : Icons.event_busy,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            widget.showOnlyDraft ? 'No Draft Races' : 'No Races',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.showOnlyDraft
                  ? 'Create a new race to get started'
                  : 'Create a race or connect to a server with existing races',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          if (!widget.showOnlyDraft)
            ElevatedButton.icon(
              onPressed: () => _createNewRace(),
              icon: const Icon(Icons.add),
              label: const Text('Create Race'),
            ),
        ],
      ),
    );
  }

  Widget _buildRaceList() {
    return RefreshIndicator(
      onRefresh: _loadRaces,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _races.length,
        itemBuilder: (context, index) {
          final race = _races[index];
          return _buildRaceCard(race);
        },
      ),
    );
  }

  Widget _buildRaceCard(Race race) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _selectRace(race),
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
                  _buildStatusBadge(race),
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
                  _buildInfoChip(
                    Icons.calendar_today,
                    _formatDate(race.raceDate),
                  ),
                  const SizedBox(width: 8),
                  if (race.raceTime != null)
                    _buildInfoChip(
                      Icons.flag,
                      race.raceTime!,
                    ),
                  const Spacer(),
                  _buildCountChip(Icons.people, race.entryCount),
                  const SizedBox(width: 8),
                  _buildCountChip(Icons.timer, race.scanCount),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (race.isDraft)
                    TextButton.icon(
                      onPressed: () => _selectRace(race),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Race'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green,
                      ),
                    ),
                  if (race.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Active',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (race.isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Completed',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Race race) {
    Color color;
    String text;

    switch (race.status) {
      case 'active':
        color = Colors.green;
        text = 'ACTIVE';
        break;
      case 'completed':
        color = Colors.grey;
        text = 'DONE';
        break;
      default:
        color = Colors.orange;
        text = 'DRAFT';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountChip(IconData icon, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectRace(Race race) async {
    try {
      final appState = context.read<AppState>();
      
      // Select the race
      await appState.selectRace(race.id);
      
      if (!context.mounted) return;
      
      // If race is draft, ask to start it
      if (race.isDraft) {
        final start = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Start Race?'),
            content: Text(
              'Would you like to start "${race.name}" now?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Not Yet'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Start Now'),
              ),
            ],
          ),
        );
        
        if (start == true && context.mounted) {
          await appState.startRace(race.id);
        }
      }
      
      if (context.mounted) {
        Navigator.pop(context, race);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select race: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createNewRace() async {
    // Navigate to create race screen or show dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create race feature coming soon')),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
