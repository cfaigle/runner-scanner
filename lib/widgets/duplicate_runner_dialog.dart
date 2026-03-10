import 'package:flutter/material.dart';
import '../models/models.dart';

class DuplicateRunnerDialog extends StatelessWidget {
  final Runner existingRunner;
  final Runner newRunner;

  const DuplicateRunnerDialog({
    super.key,
    required this.existingRunner,
    required this.newRunner,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Runner Already Exists'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A runner with this ID already exists but with different information:',
          ),
          const SizedBox(height: 16),
          _buildComparisonRow('Name', existingRunner.name, newRunner.name),
          _buildComparisonRow(
            'Date of Birth',
            _formatDate(existingRunner.dateOfBirth),
            _formatDate(newRunner.dateOfBirth),
          ),
          const SizedBox(height: 16),
          const Text(
            'Do you want to overwrite the existing runner?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Overwrite'),
        ),
      ],
    );
  }

  Widget _buildComparisonRow(String label, String existing, String newValue) {
    final isDifferent = existing != newValue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Existing: $existing',
                  style: TextStyle(
                    color: isDifferent ? Colors.red : Colors.black,
                    decoration: isDifferent ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (isDifferent)
                  Text(
                    'New: $newValue',
                    style: const TextStyle(color: Colors.green),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
