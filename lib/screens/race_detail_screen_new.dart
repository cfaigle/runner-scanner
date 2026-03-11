import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../presentation/bloc/race/race_bloc.dart';
import '../presentation/bloc/race/race_event.dart';
import '../presentation/bloc/scan/scan_bloc.dart';
import '../core/theme/app_theme.dart';
import 'scanner_screen_new.dart';
import 'participants_screen_new.dart';
import 'results_screen_new.dart';

class RaceDetailScreenNew extends StatefulWidget {
  final dynamic race;

  const RaceDetailScreenNew({super.key, required this.race});

  @override
  State<RaceDetailScreenNew> createState() => _RaceDetailScreenNewState();
}

class _RaceDetailScreenNewState extends State<RaceDetailScreenNew> {
  int _selectedIndex = 0; // Start with participants tab (0)

  @override
  Widget build(BuildContext context) {
    final race = widget.race;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 140, // Smaller height
              floating: true,
              pinned: true,
              backgroundColor: _getHeaderColor(race.status),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                if (race.status == 'draft')
                  IconButton(
                    icon: const Icon(Icons.play_circle, color: Colors.white, size: 28),
                    onPressed: () => _startRace(race.id),
                    tooltip: 'Start Race',
                  ),
                if (race.status == 'active')
                  IconButton(
                    icon: const Icon(Icons.stop_circle, color: Colors.white, size: 28),
                    onPressed: () => _stopRace(race.id),
                    tooltip: 'Stop Race',
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(race),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            Expanded(child: _buildTabContent(race)),
            NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: 'Runners',
                ),
                NavigationDestination(
                  icon: Icon(Icons.qr_code_scanner_outlined),
                  selectedIcon: Icon(Icons.qr_code),
                  label: 'Scan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.leaderboard_outlined),
                  selectedIcon: Icon(Icons.leaderboard),
                  label: 'Results',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic race) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getGradientColors(race.status),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              race.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.white.withOpacity(0.8)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    DateFormat('MMM d, yyyy').format(race.raceDate),
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.people, size: 12, color: Colors.white.withOpacity(0.8)),
                const SizedBox(width: 4),
                Text(
                  '${race.entryCount}',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                ),
                const SizedBox(width: 12),
                Icon(Icons.qr_code, size: 12, color: Colors.white.withOpacity(0.8)),
                const SizedBox(width: 4),
                Text(
                  '${race.scanCount}',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case 'active':
        color = Colors.white;
        icon = Icons.play_circle;
        text = 'LIVE - RACE IN PROGRESS';
        break;
      case 'completed':
        color = Colors.white70;
        icon = Icons.check_circle;
        text = 'COMPLETED';
        break;
      default:
        color = Colors.white70;
        icon = Icons.circle_outlined;
        text = 'DRAFT - NOT STARTED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(dynamic race) {
    switch (_selectedIndex) {
      case 0:
        return ParticipantsScreenNew(race: race);
      case 1:
        return BlocProvider.value(
          value: context.read<ScanBloc>(),
          child: ScannerScreenNew(race: race),
        );
      case 2:
        return ResultsScreenNew(race: race);
      default:
        return ParticipantsScreenNew(race: race);
    }
  }

  Color _getHeaderColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green.shade600;
      case 'completed':
        return Colors.grey.shade600;
      default:
        return Colors.blue.shade600;
    }
  }

  List<Color> _getGradientColors(String status) {
    switch (status) {
      case 'active':
        return [Colors.green.shade600, Colors.green.shade400, Colors.teal.shade400];
      case 'completed':
        return [Colors.grey.shade600, Colors.grey.shade400, Colors.blueGrey.shade400];
      default:
        return [Colors.blue.shade600, Colors.blue.shade400, Colors.cyan.shade400];
    }
  }

  void _startRace(String raceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Start Race?'),
        content: Text('Start "${widget.race.name}"? This will begin the race timer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<RaceBloc>().add(StartRace(raceId));
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Start Race'),
          ),
        ],
      ),
    );
  }

  void _stopRace(String raceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Stop Race?'),
        content: Text('Stop "${widget.race.name}"? No more scans can be recorded.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<RaceBloc>().add(StopRace(raceId));
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Stop Race'),
          ),
        ],
      ),
    );
  }
}
