import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/local_entry.dart';
import '../widgets/create_runner_dialog.dart';

class ParticipantsScreen extends StatelessWidget {
  ParticipantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.localEntries.isEmpty) {
            return _buildEmptyView(context, appState);
          }
          return _buildParticipantsList(context, appState);
        },
      ),
      floatingActionButton: Consumer<AppState>(
        builder: (context, appState, child) {
          return FloatingActionButton(
            onPressed: () => _showAddParticipantDialog(context),
            backgroundColor: Colors.blue.shade600,
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context, AppState appState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.blue.shade600,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Participants Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add participants to this race',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddParticipantDialog(context),
            icon: const Icon(Icons.person_add),
            label: const Text('Add Participant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsList(BuildContext context, AppState appState) {
    return RefreshIndicator(
      onRefresh: () => appState.loadLocalEntries(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appState.localEntries.length,
        itemBuilder: (context, index) {
          final entry = appState.localEntries[index];
          return _buildParticipantCard(context, entry, appState);
        },
      ),
    );
  }

  Widget _buildParticipantCard(BuildContext context, LocalEntry entry, AppState appState) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('ID: ${entry.runnerGuidShort}'),
            if (entry.bibNumber != null) Text('Bib: ${entry.bibNumber}'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'qr',
              child: Row(
                children: [
                  Icon(Icons.qr_code),
                  SizedBox(width: 8),
                  Text('Show QR Code'),
                ],
              ),
            ),
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
          onSelected: (value) => _handleMenuAction(context, value, entry, appState),
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action, LocalEntry entry, AppState appState) {
    switch (action) {
      case 'qr':
        _showQRCode(context, entry);
        break;
      case 'delete':
        _deleteParticipant(context, entry, appState);
        break;
    }
  }

  void _showQRCode(BuildContext context, LocalEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(entry.runnerName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.qr_code, size: 150),
            ),
            const SizedBox(height: 16),
            Text('ID: ${entry.runnerGuidShort}'),
            const SizedBox(height: 8),
            Text(
              'QR code generation coming soon',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddParticipantDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateRunnerDialog(),
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
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Participant removed'),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
