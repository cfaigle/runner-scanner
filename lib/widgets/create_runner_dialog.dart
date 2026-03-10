import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class CreateRunnerDialog extends StatefulWidget {
  const CreateRunnerDialog({super.key});

  @override
  State<CreateRunnerDialog> createState() => _CreateRunnerDialogState();
}

class _CreateRunnerDialogState extends State<CreateRunnerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bibController = TextEditingController();
  String? _selectedSex;
  DateTime? _selectedDate;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _bibController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Participant'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorView()
                : _buildFormContent(),
      ),
      actions: _isLoading
          ? null
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _saveParticipant,
                child: const Text('Add'),
              ),
            ],
    );
  }

  Widget _buildErrorView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error, color: Colors.red, size: 48),
        const SizedBox(height: 16),
        Text(
          _error!,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name *',
              hintText: 'Enter runner name',
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedSex,
            decoration: const InputDecoration(
              labelText: 'Sex',
              prefixIcon: Icon(Icons.male),
            ),
            items: const [
              DropdownMenuItem(value: 'M', child: Text('Male')),
              DropdownMenuItem(value: 'F', child: Text('Female')),
              DropdownMenuItem(value: 'O', child: Text('Other')),
            ],
            onChanged: (value) => setState(() => _selectedSex = value),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date of Birth',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                _selectedDate != null
                    ? _formatDate(_selectedDate!)
                    : 'Select date',
                style: TextStyle(
                  color: _selectedDate != null
                      ? Theme.of(context).textTheme.bodyLarge?.color
                      : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bibController,
            decoration: const InputDecoration(
              labelText: 'Bib Number',
              hintText: 'Optional',
              prefixIcon: Icon(Icons.tag),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveParticipant() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final appState = context.read<AppState>();

      if (appState.currentRaceId == null) {
        throw Exception('No race selected');
      }

      // Create local entry (works offline)
      await appState.createLocalEntry(
        raceId: appState.currentRaceId!,
        runnerName: _nameController.text.trim(),
        sex: _selectedSex,
        dateOfBirth: _selectedDate,
        bibNumber: _bibController.text.isNotEmpty
            ? int.tryParse(_bibController.text)
            : null,
      );

      if (context.mounted) {
        Navigator.pop(context);
        // Refresh participants list
        await appState.loadLocalEntries();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('✅ "${_nameController.text.trim()}" added!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to add: ${e.toString()}';
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
