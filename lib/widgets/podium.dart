import 'package:flutter/material.dart';

class PodiumWidget extends StatelessWidget {
  final List<RunnerResult> topThree;

  const PodiumWidget({
    super.key,
    required this.topThree,
  });

  @override
  Widget build(BuildContext context) {
    if (topThree.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          if (topThree.length > 1) ...[
            Expanded(
              child: _PodiumPlace(
                result: topThree[1],
                place: 2,
                height: 100,
                color: Colors.grey.shade400,
              ),
            ),
          ] else
            const Expanded(child: SizedBox()),

          // 1st Place
          Expanded(
            child: _PodiumPlace(
              result: topThree[0],
              place: 1,
              height: 140,
              color: Colors.amber.shade500,
            ),
          ),

          // 3rd Place
          if (topThree.length > 2) ...[
            Expanded(
              child: _PodiumPlace(
                result: topThree[2],
                place: 3,
                height: 80,
                color: Colors.orange.shade700,
              ),
            ),
          ] else
            const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  final RunnerResult result;
  final int place;
  final double height;
  final Color color;

  const _PodiumPlace({
    required this.result,
    required this.place,
    required this.height,
    required this.color,
  });

  String get _medal {
    switch (place) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Medal emoji floating above
        Transform.translate(
          offset: const Offset(0, -10),
          child: Text(
            _medal,
            style: const TextStyle(fontSize: 40),
          ),
        ),
        const SizedBox(height: 8),
        // Runner info
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                result.runnerName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(result.totalTime),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Podium block
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          width: double.infinity,
          child: Center(
            child: Text(
              '#$place',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(double? seconds) {
    if (seconds == null) return '--:--';
    final duration = Duration(milliseconds: (seconds * 1000).round());
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    final millis = (duration.inMilliseconds % 1000) ~/ 10;
    return '$minutes:${secs.toString().padLeft(2, '0')}.$millis';
  }
}

class RunnerResult {
  final String runnerName;
  final String runnerId;
  final double? totalTime;
  final int lapCount;

  RunnerResult({
    required this.runnerName,
    required this.runnerId,
    this.totalTime,
    required this.lapCount,
  });
}
