import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class ExportDataButton extends StatelessWidget {
  const ExportDataButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final scanCount = appState.getAllScans().length;

        return IconButton(
          icon: Badge(
            isLabelVisible: scanCount > 0,
            label: Text(scanCount.toString()),
            child: const Icon(Icons.file_download),
          ),
          onPressed: scanCount > 0 ? () => _exportData(context, appState) : null,
          tooltip: scanCount > 0
              ? 'Export scan data ($scanCount scans)'
              : 'No scans to export',
        );
      },
    );
  }

  Future<void> _exportData(BuildContext context, AppState appState) async {
    try {
      await appState.exportScans();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
