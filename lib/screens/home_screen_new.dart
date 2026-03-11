import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../presentation/bloc/race/race_bloc.dart';
import '../presentation/bloc/race/race_event.dart';
import '../presentation/bloc/race/race_state.dart';
import '../core/theme/app_theme.dart';
import 'settings_screen.dart';
import 'create_race_screen_new.dart';

class HomeScreenNew extends StatelessWidget {
  const HomeScreenNew({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Races'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<RaceBloc, RaceState>(
        builder: (context, state) {
          if (state is RaceLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is RaceLoaded) {
            if (state.races.isEmpty) {
              return _buildEmptyState(context);
            }
            return _buildRaceList(state.races, context);
          } else if (state is RaceError) {
            return Center(child: Text('Error: ${state.error}'));
          }
          return _buildEmptyState(context);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateRaceScreenNew()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Race'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flag,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          const Text(
            'No Races Yet',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first race to get started',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateRaceScreenNew()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Race'),
          ),
        ],
      ),
    );
  }

  Widget _buildRaceList(List<dynamic> races, BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: races.length,
      itemBuilder: (context, index) {
        final race = races[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(race.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(DateFormat('MMM d, yyyy').format(race.raceDate)),
                const SizedBox(height: 4),
                _buildStatusChip(race.status),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to race detail
            },
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'active':
        color = AppTheme.statusLive;
        text = 'LIVE';
        break;
      case 'completed':
        color = AppTheme.statusCompleted;
        text = 'DONE';
        break;
      default:
        color = AppTheme.statusDraft;
        text = 'DRAFT';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
