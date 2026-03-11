import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../presentation/bloc/race/race_bloc.dart';
import '../presentation/bloc/race/race_event.dart';
import '../presentation/bloc/race/race_state.dart';
import '../core/theme/app_theme.dart';
import 'settings_screen.dart';
import 'create_race_screen_new.dart';
import 'race_detail_screen_new.dart';

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
          debugPrint('🏠 HOME: Build with state: ${state.runtimeType}');
          
          if (state is RaceLoading) {
            debugPrint('🏠 HOME: Showing loading indicator');
            return const Center(child: CircularProgressIndicator());
          } else if (state is RaceLoaded) {
            debugPrint('🏠 HOME: RaceLoaded with ${state.races.length} races');
            for (var race in state.races) {
              debugPrint('   - ${race.id}: ${race.name} (${race.status})');
            }
            
            if (state.races.isEmpty) {
              debugPrint('🏠 HOME: No races, showing empty state');
              return _buildEmptyState(context);
            }
            debugPrint('🏠 HOME: Showing race list');
            return _buildRaceList(state.races, context);
          } else if (state is RaceError) {
            debugPrint('🏠 HOME: Showing error: ${state.error}');
            return Center(child: Text('Error: ${state.error}'));
          }
          debugPrint('🏠 HOME: Unknown state, showing empty state');
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
          child: InkWell(
            onTap: () {
              // Navigate to race detail
              context.read<RaceBloc>().add(SelectRace(race.id));
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RaceDetailScreenNew(race: race),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
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
                          style: const TextStyle(
                            fontSize: 20,
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
                      style: const TextStyle(color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, yyyy').format(race.raceDate),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const Spacer(),
                      Icon(Icons.people, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${race.entryCount}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.qr_code, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${race.scanCount}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
