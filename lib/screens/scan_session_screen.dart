import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/duplicate_runner_dialog.dart';
import 'race_standings_screen.dart';

class ScanSessionScreen extends StatefulWidget {
  const ScanSessionScreen({super.key});

  @override
  State<ScanSessionScreen> createState() => _ScanSessionScreenState();
}

class _ScanSessionScreenState extends State<ScanSessionScreen> {
  MobileScannerController? _controller;
  String? _cooldownMessage;
  Timer? _cooldownTimer;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _startScanner();
  }

  void _startScanner() {
    _controller = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: true,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<AppState>(
          builder: (context, appState, child) {
            if (appState.currentRaceId != null) {
              final race = appState.races.firstWhere(
                (r) => r.id == appState.currentRaceId,
                orElse: () => appState.races.first,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Scan Runner'),
                  Text(
                    race.name,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                  ),
                ],
              );
            }
            return const Text('Scan Runner');
          },
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          Consumer<AppState>(
            builder: (context, appState, child) {
              if (appState.isConnectedToServer) {
                return IconButton(
                  icon: const Icon(Icons.leaderboard),
                  onPressed: () => _openStandings(context),
                  tooltip: 'View Standings',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (!appState.isSessionActive) {
            return const Center(
              child: Text('No active session. Please start a session first.'),
            );
          }

          return Stack(
            children: [
              MobileScanner(
                controller: _controller,
                onDetect: (capture) {
                  if (_isProcessing) return;
                  
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      _handleScan(barcode.rawValue!, appState);
                      break;
                    }
                  }
                },
                errorBuilder: (context, error, child) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.camera_alt,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Camera error',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            _controller?.dispose();
                            _startScanner();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (_cooldownMessage != null)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.timer_off,
                              size: 48,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _cooldownMessage!,
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.flash_on),
                  color: Colors.white,
                  onPressed: () => _controller?.toggleTorch(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleScan(String qrData, AppState appState) async {
    setState(() => _isProcessing = true);

    try {
      final runner = appState.parseRunnerQRCode(qrData);
      final existingRunner = appState.getRunner(runner.id);

      // Check cooldown
      if (!appState.canScanRunner(runner.id)) {
        final cooldownSeconds = appState.getCooldownSeconds(runner.id);
        setState(() {
          _cooldownMessage =
              'Please wait $cooldownSeconds seconds before scanning this runner again.';
        });

        _cooldownTimer?.cancel();
        _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!appState.canScanRunner(runner.id)) {
            final remaining = appState.getCooldownSeconds(runner.id);
            setState(() {
              _cooldownMessage =
                  'Please wait $remaining seconds before scanning this runner again.';
            });
          } else {
            setState(() => _cooldownMessage = null);
            timer.cancel();
          }
        });

        setState(() => _isProcessing = false);
        return;
      }

      // Check for duplicate runner
      if (existingRunner != null &&
          (existingRunner.name != runner.name ||
              existingRunner.dateOfBirth != runner.dateOfBirth)) {
        if (!context.mounted) return;

        final shouldOverwrite = await showDialog<bool>(
          context: context,
          builder: (context) => DuplicateRunnerDialog(
            existingRunner: existingRunner,
            newRunner: runner,
          ),
        );

        if (shouldOverwrite != true) {
          setState(() => _isProcessing = false);
          return;
        }
      }

      // Save runner if new or updated
      await appState.saveRunner(runner);

      // Record the scan
      await appState.recordScan(runner);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${runner.name} scanned successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      setState(() {
        _cooldownMessage = null;
      });

      _cooldownTimer?.cancel();
      _cooldownTimer = Timer(const Duration(seconds: 10), () {
        setState(() => _cooldownMessage = null);
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _openStandings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RaceStandingsScreen(),
      ),
    );
  }
}
