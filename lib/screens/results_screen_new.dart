import 'package:flutter/material.dart';
import '../widgets/podium.dart';

class ResultsScreenNew extends StatelessWidget {
  final dynamic race;

  const ResultsScreenNew({super.key, required this.race});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard_outlined, size: 80, color: Colors.grey.shade600),
            const SizedBox(height: 24),
            const Text(
              'Results',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${race.scanCount} scans recorded',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
