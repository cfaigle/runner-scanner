import 'package:flutter/material.dart';

class ParticipantsScreenNew extends StatelessWidget {
  final dynamic race;

  const ParticipantsScreenNew({super.key, required this.race});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey.shade600),
            const SizedBox(height: 24),
            const Text(
              'Participants',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${race.entryCount} runners registered',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add participant coming soon')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
