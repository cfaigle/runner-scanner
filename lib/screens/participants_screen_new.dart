import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/local_entry.dart';

class ParticipantsScreenNew extends StatefulWidget {
  final dynamic race;

  const ParticipantsScreenNew({super.key, required this.race});

  @override
  State<ParticipantsScreenNew> createState() => _ParticipantsScreenNewState();
}

class _ParticipantsScreenNewState extends State<ParticipantsScreenNew> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final entries = appState.getEntriesForRace(widget.race.id);
          
          if (entries.isEmpty) {
            return _buildEmptyView(context, appState);
          }
          
          return _buildParticipantsList(entries, appState);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddParticipantDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context, AppState appState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade600),
          const SizedBox(height: 24),
          const Text(
            'No Participants',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add runners to this race',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddParticipantDialog(context),
            icon: const Icon(Icons.person_add),
            label: const Text('Add Participant'),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsList(List<LocalEntry> entries, AppState appState) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                entry.runnerGuidShort.toUpperCase(),
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text(
              entry.runnerName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('ID: ${entry.runnerGuidShort}'),
                if (entry.bibNumber != null) Text('Bib: ${entry.bibNumber}'),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) => _deleteParticipant(context, entry, appState),
            ),
          ),
        );
      },
    );
  }

  void _showAddParticipantDialog(BuildContext context) {
    final nameController = TextEditingController();
    final bibController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Participant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Runner Name',
                hintText: 'e.g., John Doe',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bibController,
              decoration: const InputDecoration(
                labelText: 'Bib Number (Optional)',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                context.read<AppState>().createLocalEntry(
                  raceId: widget.race.id,
                  runnerName: nameController.text.trim(),
                  bibNumber: bibController.text.trim().isEmpty
                      ? null
                      : int.tryParse(bibController.text.trim()),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deleteParticipant(BuildContext context, LocalEntry entry, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Participant?'),
        content: Text('Remove "${entry.runnerName}" from this race?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              appState.deleteLocalEntry(entry.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
